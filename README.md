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

## Run preparing queries (optional) ##

If you are using a tagger like `standoff-mode` with a RDFS/OWL
annotation scheme, you might want to run the following query in order
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

Let's explain the structure of the generated RDF graph by example!

Here's an example from the generated `annotations.ttl`:

```{ttl}
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix som: <http://github.com/lueck/standoff-mode/owl#> .

<file://../src/6ef9537e9e5e70edbd3936f89a33a992>
        rdf:type    som:sourceDocument ;
        som:md5sum  "6ef9537e9e5e70edbd3936f89a33a992" .

<http://github.com/lueck/standoff-mode/annotation/0063875a-b5d3-4878-8e2f-5508e2baa7ef>
        rdf:type             som:markupRange ;
        som:annotator        "RBach" ;
        som:markupElementId  <http://github.com/lueck/standoff-mode/annotation/49a97f61-b8d8-4f27-b978-7c18caf16688> ;
        som:sourceDocument   <file://../src/6ef9537e9e5e70edbd3936f89a33a992> ;
        som:sourceEnd        557928 ;
        som:sourceStart      557743 ;
        som:tag              <http://arb.fernuni-hagen.de/owl/beispiel#Konzept> ;
        som:uuid             "0063875a-b5d3-4878-8e2f-5508e2baa7ef" .

<http://github.com/lueck/standoff-mode/annotation/000ca09c-c48a-4b51-b1e6-c29eddaf80cd>
        rdf:type       som:relation ;
        som:annotator  "RBach" ;
        som:object     <http://github.com/lueck/standoff-mode/annotation/49a97f61-b8d8-4f27-b978-7c18caf16688> ;
        som:predicate  <http://arb.fernuni-hagen.de/owl/beispiel#beispielFuer> ;
        som:subject    <http://github.com/lueck/standoff-mode/annotation/5a683485-1c49-48fa-ae64-fff080df207c> ;
        som:uuid       "000ca09c-c48a-4b51-b1e6-c29eddaf80cd" .
```

Note, that multiple `markupRange`s can share a common
`som:markupElementId` property!  If they do, they belong to the same
annotated entity and are parts of **discontinuous markup**.  Relations
do not reference `markupRange`s, but **elements**!

Here is an example how TEI header data are transformed to `meta.ttl`:

```{ttl}
@prefix dc: <http://purl.org/dc/elements/1.1/> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix som: <http://github.com/lueck/standoff-mode/owl#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

<file://../src/6ef9537e9e5e70edbd3936f89a33a992>
        rdf:type       som:teiDocument ;
        som:md5sum     "6ef9537e9e5e70edbd3936f89a33a992" ;
        dc:creator     "\n\nVischer\nFriedrich Theodor von\n\n" ;
        dc:creator     "http://d-nb.info/gnd/11862721X" ;
        dc:date        1846 ;
        dc:identifier  "urn:nbn:de:kobv:b4-200905196548" ;
        dc:source      "Vischer, Friedrich Theodor von: Ästhetik oder Wissenschaft des Schönen. Bd. 1. Reutlingen u. a., 1846." ;
        dc:title       "Erster Theil: Die Metaphysik des Schönen" ;
        dc:title       "Zum Gebrauche für Vorlesungen" ;
        dc:title       "Ästhetik oder Wissenschaft des Schönen" .
```

Note, that the MD5 sum of the file is central to joining annotation
data and meta data, since it goes into the
`<file://../src/6ef9537e9e5e70edbd3936f89a33a992>` IRI.

Here is an example Range from `ranges.ttl`:

```{ttl}
@prefix som: <http://github.com/lueck/standoff-mode/owl#> .

<http://github.com/lueck/standoff-mode/annotation/0063875a-b5d3-4878-8e2f-5508e2baa7ef>
        som:text  "der\nKünstler findet diesen so weit schon geformten Stoff in der Erfahrung\nvor und wählt ihn zur Umbildung in die reine Form"@de .
```

So, the annotation's UUIDs and the IRIs made from it are central to
joining annotation data and the content of the source document.


# Samples #

Here's a [report](samples/praktikum-arb.Rmd) on the annotations
created by students during a laboratory session using
[standoff-mode](https://github.com/lueck/standoff-mode).

# License #

GPL v3
