#!/bin/bash

set -e

NAME=$(basename $0)
CTAG_DIR=tags
CTAGS_DB=$CTAG_DIR/tags
CSCOPE_DB=$CTAG_DIR/cscope.out
CSCOPE_FILES=$CTAG_DIR/cscope.files

#echo "Running cscope-ctags-builder..."
eval rm -f $CSCOPE_FILES $CSCOPE_DB $CTAGS_DB

if [ ! -e $CTAG_DIR ]; then
	mkdir $CTAG_DIR
fi

echo "Builing cscope & ctag symbols:"
find $PWD -name '*.c' -o -name '*.cpp' -o -name '*.h' | sort > $CSCOPE_FILES

# exit. if no source file entries exist.
NFILES=$(wc -l $CSCOPE_FILES | awk '{ print $1 }')
if [ $NFILES -eq 0 ]; then
	echo "$NAME: No source files available."
	rm -rf $CTAG_DIR
	exit 1
fi

eval /usr/bin/cscope -b -i $CSCOPE_FILES -f $CSCOPE_DB
eval /usr/bin/ctags -f $CTAGS_DB -w -L - < $CSCOPE_FILES

echo "Done."

exit 0

