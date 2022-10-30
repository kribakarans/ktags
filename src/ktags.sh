#!/bin/bash

PKGNAME=Ktags
PKGVERSION=1.0

OBJDIR=obj
DISTDIR=dist
BUILDDIR=build
CODEREVIEW=codereview

KTAGSDIR=__ktags
CTAGS_DB=$KTAGSDIR/tags
CSCOPE_DB=$KTAGSDIR/cscope.out
CSCOPE_FILES=$KTAGSDIR/cscope.files

VERBOSE=0
CTAGSGENERATED=0
HTTPBROWSER=firefox

#------------------------------------------
# Ktags utility functions
#------------------------------------------

print_usage() {
	cat <<-USAGE
	Usage: ktags [options]...
	Ktags makes it easy to use traditional source code tagging systems
	 such as Cscope, Ctags, GNU Global's Gtags, Gscope and Htags.

	Options:
	    -a  --all      -- Generate Ctags and Gtags
	    -b  --browse   -- Start webserver and open browser to explore source code
	    -c  --ctags    -- Generate only the Ctags
	    -g  --gtags    -- Generate only the Gtags
	    -D  --deploy   -- Deploy Ktags files into local webserver
	    -d  --delete   -- Delete Ktags database files
	    -V  --verbose  -- Enable verbose mode
	    -v  --version  -- Print Ktags version
	    -h  --help     -- Show this help menu
	                   -- Running Ktags without arguments will generate
	                      Ctags and Cscope databases
	USAGE

	exit 0
}

print_version() {
	echo "$PKGNAME: Version $PKGVERSION - Source code tagging and navigation tool"
	exit 0
}

print_debug() {
	if [ $VERBOSE -eq 1 ]; then
		echo -e "$@"
	fi
}

#---------------------------------------------------------------
# Lookup @BASENAME of an given file in the given @PATTERN
# Return TRUE if @BASENAME matched with the $PATTERN
#
# Args: $1  -- Basename
#       $2  -- Array of patterns to find
#
# Return 1 -- Pattern matched
#        0 -- Pattern not matched
#---------------------------------------------------------------

lookup_basename_pattern() {
	BASENAME=$(basename $1)
	shift
	PATTERNS=( "$@" )

	for PATTERN in "${PATTERNS[@]}"
	do
		if [[ $BASENAME == $PATTERN ]]; then
			return 1
		else
			continue
		fi
	done

	return 0
}

# Recursively travel a directory
ktags_scan_directory() {
	for ENTRY in $(ls -a "$1")
	do
		FILE=$1/$ENTRY
		if [ -d $FILE ]; then
			lookup_basename_pattern "$FILE" "${DIR_IGNORE_LIST[@]}"
			if [ $? -eq 0 ]; then
				ktags_scan_directory $FILE
			fi
		else
			lookup_basename_pattern "$FILE" "${FILE_IGNORE_LIST[@]}"
			if [ $? -eq 0 ]; then
				echo "$FILE"
			fi
		fi
	done
}

#------------------------------------------
# Ktags core functions
#------------------------------------------

ktags_delete_database() {
	if [ $VERBOSE -eq 1 ]; then
		DEBUGRM="-v"
	fi

	echo "$PKGNAME: removing tags ..."
	rm -rf $KTAGSDIR $DEBUGRM
	exit 0
}

ktags_generate_ctags() {
	if [ $VERBOSE -eq 1 ]; then
		CSCOPEDEBUG="-v"
		CTAGSDEBUG="--verbose"
	fi

	# Initialize ignore list
	FILE_IGNORE_LIST=( '*.a' '*.d' '*.o' '*.out' '*.so' '*.so.*' '*.swo' '*.swp' )
	DIR_IGNORE_LIST=( '.' '..' '.git' $OBJDIR $BUILDDIR $CODEREVIEW $DISTDIR $KTAGSDIR )

	# Check Ctags already generated
	if [ $CTAGSGENERATED -eq 1 ]; then
		return 0
	fi

	echo "$PKGNAME: generating Ctags ..."

	# Create source list
	print_debug "Scanning files ..."
	ktags_scan_directory $PWD > $CSCOPE_FILES
	if [ ! -f $CSCOPE_FILES ]; then
		echo "$PKGNAME: failed to generate source list !!!"
		exit 1
	fi

	# Validate source list
	NFILES=$(wc -l $CSCOPE_FILES | awk '{ print $1 }')
	if [ $NFILES -eq 0 ]; then
		echo "$PKGNAME: No source files scanned !!!"
		rmdir $KTAGSDIR
		exit 1
	fi

	# Generate Ctags and Cscope databases
	eval /usr/bin/cscope -b -i $CSCOPE_FILES -f $CSCOPE_DB $CSCOPEDEBUG
	eval /usr/bin/ctags -f $CTAGS_DB -w -L $CSCOPE_FILES $CTAGSDEBUG

	CTAGSGENERATED=1

	return $?
}

ktags_generate_gtags() {
	if [ $VERBOSE -eq 1 ]; then
		DEBUGRSYNC="-v"
		DEBUGHTAGS="--statistics"
		DEBUGGTAGS="--explain --statistics --warning"
	fi

	echo -e "$PKGNAME: generating Gtags ..."
	# Copy source repo to $KTAGSDIR
	print_debug "Copying source ..."
	rsync -ar --exclude "*~" \
	          --exclude "*.a" \
	          --exclude "*.d" \
	          --exclude "*.o" \
	          --exclude "*.so*" \
	          --exclude "*.out" \
	          --exclude "*.swo" \
	          --exclude "*.swp" \
	          --exclude ".git*" \
	          --exclude "$OBJDIR" \
	          --exclude "$DISTDIR" \
	          --exclude "$BUILDDIR" \
	          --exclude "$KTAGSDIR" \
	          --exclude "$CODEREVIEW" $PWD $KTAGSDIR $DEBUGRSYNC

	if [ $? -ne 0 ]; then
		echo "$PKGNAME: Rsync failed !!!"
		exit 1
	fi

	# Step into KTAGSDIR
	cd $KTAGSDIR

	# Generate Gtags database
	echo "    Generating Gtags ..."
	gtags --incremental --skip-symlink --incremental $DEBUGGTAGS
	if [ $? -ne 0 ]; then
		echo "$PKGNAME: Gtags failed !!!"
		exit 1
	fi

	# Generate Htags database
	echo "    Generating Htags ..."
	htags --alphabet \
	      --auto-completion \
	      --colorize-warned-line \
	      --dynamic \
	      --frame \
	      --form \
	      --fixed-guide \
	      --icon \
	      --line-number \
	      --map-file \
	      --other \
	      --symbol \
	      --show-position \
	      --table-list \
	      --warning \
	      --func-header=right \
	      --tree-view=filetree \
	      --title "$PKGNAME: Source code navigator" $DEBUGHTAGS

	if [ $? -ne 0 ]; then
		echo "$PKGNAME: Htags failed !!!"
		exit 1
	fi

	cd - > /dev/null 2>&1 #Step out from KTAGSDIR

	return $?
}

ktags_browse_sourcecode() {
	if [ ! -d "$KTAGSDIR/HTML" ]; then
		ktags_generate_gtags
	fi

	if [ $VERBOSE -eq 1 ]; then
		DEBUGSERVER=""
	else
		DEBUGSERVER="> /tmp/ktags.log 2>&1"
	fi

	# Step into $KTAGSDIR and start web-server
	cd $KTAGSDIR

	echo "Opening Ktags HTML navigator ..."
	eval $HTTPBROWSER http://127.0.0.1:8000 $DEBUGSERVER &
	eval htags-server $DEBUGSERVER

	return $?
}

ktags_worker() {
	case "$KTAGSOPTS" in
		all)
			ktags_generate_ctags
			ktags_generate_gtags
			;;
		browse)
			ktags_browse_sourcecode
			;;
		ctags)
			ktags_generate_ctags
			;;
		gtags)
			ktags_generate_gtags
			;;
		deploy)
			echo "Need to implement !!!"
			#ktags_deploy_tags $DEPLOYPATH
			;;
		delete)
			ktags_delete_database
			;;
		*)
			ktags_generate_ctags
			;;
	esac

	# Remove empty ktag directory

	return $?
}

parse_cmdline_options() {
	GETOPTS=$(getopt -o abcdDghvV --long all,browse,ctags,delete,deploy,gtags,help,verbose,version -- "$@")
	if [ "$?" != "0" ]; then
		echo "Try 'ktags --help' for more information."
		exit 1
	fi

	eval set -- "$GETOPTS"
	while :
	do
		case "$1" in
			-a | --all)
				KTAGSOPTS=all
				shift
				;;
			-b | --browse)
				KTAGSOPTS=browse
				shift
				;;
			-c | --ctags)
				KTAGSOPTS=ctags
				shift
				;;
			-g | --gtags)
				KTAGSOPTS=gtags
				shift
				;;
			-d | --delete)
				KTAGSOPTS=delete
				shift
				;;
			-D | --deploy)
				KTAGSOPTS=deploy
				DEPLOYPATH=$2
				shift
				;;
			-V | --verbose)
				VERBOSE=1
				shift
				;;
			-v | --version)
				print_version
				shift
				;;
			-h | --help)
				print_usage
				shift
				;;
			--) shift; break ;; # -- means the End of the arguments
			*) echo "Unexpected option: $1" # will not hit here
		esac
	done

	#echo "Remaining arguments: $@"

	return $?
}

ktags_sanity_test()
{
	# Validate required tools are installed
	PKGS=( ctags cscope cflow global )
	for PKG in "${PKGS[@]}"
	do
		type $PKG > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "$PKGNAME: $PKG is not installed !!!"
			exit 1
		fi
	done

	mkdir -p $KTAGSDIR
}

ktags_main() {
	ktags_sanity_test

	parse_cmdline_options $@

	ktags_worker

	return $?
}

#------------------------------------------
# Main procedure
#------------------------------------------

ktags_main $@

#EOF
