#!/bin/bash

set -e

NAME=$(basename $0)
CTAG_DIR=.ktags
CTAGS_DB=$CTAG_DIR/tags
CSCOPE_DB=$CTAG_DIR/cscope.out
CSCOPE_FILES=$CTAG_DIR/cscope.files

echo "Cleaning Ktag symbols..."
eval rm -f $CSCOPE_FILES $CSCOPE_DB $CTAGS_DB

if [ ! -e $CTAG_DIR ]; then
	mkdir $CTAG_DIR
fi

echo "Builing Ktag symbols..."
find $PWD -name '*.c'    \
       -o -name '*.h'    \
       -o -name '*.sh'   \
       -o -name '*.pl'   \
       -o -name '*.pm'   \
       -o -name '*.py'   \
       -o -name '*.js'   \
       -o -name '*.mk'   \
       -o -name '*.asm'  \
       -o -name '*.awk'  \
       -o -name '*.asp'  \
       -o -name '*.cpp'  \
       -o -name '*.php'  \
       -o -name '*.html' \
       -o -name '*.java' \
       -o -name '*.xml'  | sort > $CSCOPE_FILES

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

