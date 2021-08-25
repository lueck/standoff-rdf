# `standoff-rdf`: Make RDF-triples from standoff annotations #

RDF's SPARQL is a nice query language for exploring external
markup. `standoff-rdf` gives you some tools for generating RDF triples
from standoff annotations (external markup) und putting them into a
Fuseki endpoint.

`standoff-rdf` works with the following formats of external markup:
- annotations produced by
  [`standoff-mode`](https://github.com/lueck/standoff-mode) and stored
  as JSON

It can easily be adapted to other annotation formats using RML, if the
referencing mechanism to the source document is based on character
offsets.


## Features ##

- make an RDF graph from annotation data
- extract metadata triples from TEI source document and add them to the
  graph
- extract annotated text fragments from the source files (text
  ranges), make RDF triples from them and add them to the
  graph.
- apply some NLP (via WebLicht) on the text fragments, generate RDF
  triples from the result and add them to the graph (optional)
- handle different versions of a source document by using the MD5
  checksum as filename and in IRIs
- make a TDB2 dataset for use with Fuseki endpoint
- configuration files for Fuseki with optional Lucene index and OWL
  reasoner and both
- scripts for the transformations to RDF can be used as standalone
  scripts
- GNU make is used to tie the scripts together, which makes everything
  reproducible

These features enable you to run SPARQL queries on a) the markup
structure and on b) the annotated content. If you have an annotation
scheme written in RDFS/OWL, you are enabled to run queries and let the
endpoint do inference jobs.

The results of SPARQL queries can easily be used to make reproducible
reports e.g. with R. See [samples](samples) folder.


# Requirements #

- GNU make: `apt get intall make`
- GNU sed: `apt get install sed`
- awk: `apt get install mawk`
- [rml-mapper](https://github.com/RMLio/rmlmapper-java)
- [Apache Jena](https://jena.apache.org/), `JENA_HOME` must be
  exported as an environment variable and `$JENA_HOME/bin` must be on
  `PATH`
- [Apache Jena Fuseki](https://jena.apache.org/), `FUSEKI_HOME` must
  be exported as an environment variable, optional
- JRE


`standoff-rdf` was developed and tested on Debian GNU / Linux. It was
observed, that the path to `sed` is different in other distros which
might result in errors.


# Usage #

## 1. Organize your files ##

Place your source documents (i.e. the annotated documents) and your
annotations (aka external markup aka standoff markup) in a separate
folders, were no other source documents and annotations can be found
in the subtree. Your files may be organized in subfolders.

`standoff-rdf` per default assumes source documents and annotations in
the `src` folder in the repos base directory. You can change the base
directory and you can also choose separate trees for source documents
and annotations.

You can also choose directories for generated files. Here is the
default setup:

```{shell}
export BASE_DIR=.
export SOURCE_DIR=$(BASE_DIR)/src    ## folder with source documents
export MARKUP_DIR=$(SOURCE_DIR)      ## folder with annotations
export MD5_DIR=$(SOURCE_DIR)         ## folder to copy source documents to
export RANGES_DIR=$(BASE_DIR)/ranges ## folder for extracted markup ranges
export DATABASE_DIR=$(BASE_DIR)/data ## folder for resulting RDF graph
```

See this [example setup](samples/env_praktikum) for some annotations
produced by students during laboratory sessions.

It is also important to setup file suffices, so that `make` can find
your files:

```{shell}
export SOURCE_SUFFIX=TEI-P5.xml
export MARKUP_SUFFIX=json
```

## 2. Generate RDF triples ##

First you need to point to your installation of RML mapper.

```{shell}
export RMLMAPPER_JAR=<PATH_TO_rmlmapper-VERSION-all.jar>
```

Now run

```{shell}
make all
```

This will
- copy your source documents to files named by MD5 checksums
- generate `*.meta.ttl` files from them
- concatenate all meta data in the database folder in `meta.ttl`
- generate `*.json.ttl` on your json-annotations
- concatenate everything in the database folder in `annotations.ttl`
- extract the annotated text ranges from the source documents and put
  them in a folder for these ranges
- make plain text from these extracted ranges, i.e. delete XML tags
  and resolve XML character references and do some additional
  processing defined in `LOCAL2PLAIN`
- make an RDF triple from every plain text file
- concatenate these triples into `ranges.ttl` in the database folder

## NLP (optional) ##

If you are not fine with Fuseki's Lucene index you can do additional
NLP by running

```{shell}
make nlp
```

This will send the extracted plain text ranges to WebLicht and make
RDF triples from the received TCF files. You can choose a
`WEBLICHT_CHAIN` und must provide a `WEBLICHTKEY`.


## 3. Run Fuseki ##

```{shell}
make tbd2
make index
make run
```

This will start the Fuseki endpoint as a standalone server locally on
[localhost:3030/standoff](http://localhost:3030/standoff).

The default config is a TDB2 dataset with the MicroOWL reasoner and a
Lucene index on the extracted markup ranges and meta data. You can set
the config by setting `FUSEKI_CONF`. See [`fuseki`](fuseki) for
different assembler files.

## 4. Run preparing queries ##

If you are using a tagger like `standoff-mode` with a RDFS/OWL
annotation scheme, you might want to run the following query in otder
to add your relations as SPO-triples to the graph:

```{sparql}
PREFIX som: <http://github.com/lueck/standoff-mode/owl#>

INSERT
    { ?subject ?predicate ?object }
WHERE {
    ?rel a som:relation .
    ?rel som:predicate ?predicate .
    ?rel som:subject ?subject .
    ?rel som:object ?object .
}
```


# Structure of generated RDF #

TODO

# Samples #

Here's a [report](samples/praktikum-arb.Rmd) on the annotations
created by students during a laboratory session using
[standoff-mode](https://github.com/lueck/standoff-mode).

# License #

GPL v3
