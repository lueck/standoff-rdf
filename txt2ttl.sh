#!/bin/bash

outfile=/dev/stdout
language=${LANG:0:2}

usage () {
    echo "$1"
    cat <<EOF
USAGE: $0 [ -o OUTFILE ] [ -l LANGUAGE ] TXT-FILE
  -o   send RDF/turtle output to OUTFILE; defaults to $outfile
  -l   language of the text literal; defaults to $language

This makes a single RDF triple from the contents of a plaintext file.

EOF
    exit $2
}

while (($# > 1)); do
    case $1 in
	-o)
	    outfile=$2
	    shift
	    shift
	    ;;
	-l)
	    language=$2
	    shift
	    shift
	    ;;
	-h)
	    shift
	    usage "" 1
	    ;;
	-*)
	    usage "" 2
	    ;;
    esac
done

if [ $# -lt 1 ]; then usage "" 1; fi
[ -f $1 ] || usage "ERROR: '$1' no such file" 1

infile=$1

rangeId=$(basename -s .txt $infile)

subject="<http://github.com/lueck/standoff-mode/annotation/"$rangeId">"
predicate="<http://github.com/lueck/standoff-mode/owl#text>"

cat > $outfile <<EOF
$subject $predicate "$(sed "s/\\\"/\\\\\"/g"  $infile)"@$language .
EOF
