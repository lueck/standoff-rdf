SHELL := /bin/bash

BASE_DIR ?= .
SOURCE_DIR ?= $(BASE_DIR)/src
MARKUP_DIR ?= $(SOURCE_DIR)
MD5_DIR ?= $(SOURCE_DIR)
RANGES_DIR ?= $(BASE_DIR)/ranges # should contain nothing but ranges and derivates, see clean* rule!
DATABASE_DIR ?= $(BASE_DIR)/data
DATABASE_TDB2 ?= tdb2


TEXT_LANGUAGE ?= $(shell ${LANG:0:2})

LOCAL2PLAIN ?= cat

SOURCE_SUFFIX ?= TEI-P5.xml
SOURCE_DOCS ?= $(shell find $(SOURCE_DIR) -regextype sed -regex ".*\.$(SOURCE_SUFFIX)$$" -type f)

RMLMAPPER_JAR ?= ~/src/rmlmapper-java/target/rmlmapper-*-all.jar

MARKUP_SUFFIX ?= json
MARKUP := $(shell find $(MARKUP_DIR) -name "*.$(MARKUP_SUFFIX)" -type f)
MARKUP_RDF := $(patsubst %,%.ttl,$(MARKUP))
MARKUP_RANGES_SH := $(patsubst %.json.ttl,%.ranges.sh,$(MARKUP_RDF))

MD5_DOCS := $(shell find $(MD5_DIR) -regextype sed -regex ".*/[a-fA-F0-9]\{32\}" -type f)
MD5_META := $(patsubst %,%.meta.ttl,$(MD5_DOCS))

RANGES := $(shell find $(RANGES_DIR) -regextype sed -regex ".*/[a-fA-F0-9-]\{36\}" -type f)
RANGES_TXT := $(patsubst %,%.txt,$(RANGES))
RANGES_TTL := $(patsubst %,%.txt.ttl,$(RANGES))


## Assembler file (configuration) for Apache Jena Fuseki server
FUSEKI_CONF ?= resources/fuseki/fuseki-inf-text.ttl


# using WebLicht for NLP is optional
WEBLICHT_URL ?= https://weblicht.sfs.uni-tuebingen.de/WaaS/api/1.0/chain/process
WEBLICHT_CHAIN ?= weblicht/de/chain42891928686544276.xml

RANGES_TCF := $(patsubst %,%.tcf,$(RANGES))
RANGES_TCF_TTL := $(patsubst %,%.tcf.ttl,$(RANGES))


.PHONY: all
all: 	$(DATABASE_DIR)/meta.ttl $(DATABASE_DIR)/annotations.ttl $(DATABASE_DIR)/ranges.ttl



.PHONY: md5src
md5src:
	$(foreach s,$(SOURCE_DOCS),./cp-sources.sh $(MD5_DIR) $(s);)


%.meta.ttl: %
	./tei2rdf.sh $< > $@

.PHONY: meta
meta: $(MD5_META)


%.json.ttl: %.json
	./som2rdf.sh -o $@ $<

.PHONY: markup_rdf
markup_rdf: $(MARKUP_RDF)


%.ranges.sh: %.json.ttl
	./extract-ranges.sh $(MD5_DIR)/ $(RANGES_DIR)/ $< 2> $@

.PHONY: markup_ranges_sh
markup_ranges_sh: $(MARKUP_RANGES_SH)


%.txt: %
	./plain.sh $< | $(LOCAL2PLAIN) > $@

.PHONY: txt
txt: $(RANGES_TXT)


%.txt.ttl: %.txt
	./txt2ttl.sh -l $(TEXT_LANGUAGE) -o $@ $<

.PHONY: txt_ttl
txtttl: $(RANGES_TTL)


%.tcf:	%.txt
	weblicht/waas.sh -c $(WEBLICHT_CHAIN) $< > $@ 2> >(tee -a $@.log >&2)

.PHONY: ranges_tcf
tcf: $(RANGES_TCF)


%.tcf.ttl: %.tcf
	./tcf2rdf.sh $< > $@

.PHONY: ranges_tcf_ttl
tcfttl: $(RANGES_TCF_TTL)


## rules for concatenating RDF files

$(DATABASE_DIR)/meta.ttl: $(MD5_META)
	riot --output=turtle $^ > $@

$(DATABASE_DIR)/annotations.ttl: $(MARKUP_RDF)
	riot --output=turtle $^ > $@

$(DATABASE_DIR)/ranges.ttl: $(RANGES_TTL)
	riot --output=turtle $^ > $@


$(DATABASE_DIR)/nlp.ttl: $(RANGES_TCF_TTL)
	riot --output=turtle $^ > $@

.PHONY: nlp
nlp:	$(DATABASE_DIR)/nlp.ttl


## rules for setting up und running Fuseki server

tdb2:	all
	tdb2.tdbloader --tdb $(FUSEKI_CONF) $(DATABASE_DIR)/*

index:
	java -cp $(FUSEKI_HOME)/fuseki-server.jar jena.textindexer --desc=$(FUSEKI_CONF)

run:
	$(FUSEKI_HOME)/fuseki-server --config=$(FUSEKI_CONF)

.PHONY: tdb2 index run


.PHONY: clean
clean:
	rm -Rf $(DATABASE_DIR)/meta.ttl
	rm -Rf $(DATABASE_DIR)/annotations.ttl
	rm -Rf $(DATABASE_DIR)/ranges.ttl
	rm -Rf $(DATABASE_DIR)/nlp.ttl
	rm -RF $(RANGES_TTL)


.PHONY: cleanall
cleanall:
	rm -Rf $(MD5_META)
	rm -Rf $(MD5_DOCS)
	rm -Rf $(MARKUP_RDF)
	rm -Rf $(MARKUP_RANGES_SH) $(RANGES_DIR)/*
