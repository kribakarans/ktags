#!/bin/bash

PKGNAME=Ktags
PKGVERSION=1.0-e

OBJDIR=obj
DISTDIR=dist
BUILDDIR=build
CODEREVIEW=codereview

KTAGSDIR=__ktags
CTAGS_DB=$KTAGSDIR/tags
CSCOPE_DB=$KTAGSDIR/cscope.out
CSCOPE_FILES=$KTAGSDIR/cscope.files

PORT=8888
HOST=localhost
HTTPBROWSER=firefox
URL=http://$HOST:$PORT

VERBOSE=0
CTAGSGENERATED=0

#------------------------------------------
# Ktags utility functions
#------------------------------------------

print_usage() {
	cat <<-USAGE
	Usage: ktags [options]...
	Ktags makes it easy to use traditional source code tagging systems
	 such as Cscope, Ctags, GNU Global's Gscope, Gtags, and Htags.

	Options:
	    -a  --all      -- Generate both Ctags and Gtags symbols
	    -b  --browse   -- Instantly explore the source code in web-browser at $LOCALHOST
	    -c  --ctags    -- Generate tags with Ctags tool
	    -g  --gtags    -- Generate tags eith Gtags tool
	    -d  --delete   -- Delete tags database files in current path
	    -V  --verbose  -- Enable debug mode
	    -v  --version  -- Print package version
	    -h  --help     -- Show this help menu
	                   -- Running application without arguments will generate
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

ktags_scan_files() {
	FILE=$1

	find -L $PWD -name '*.c'    \
	          -o -name '*.h'    \
	          -o -name '*.go'   \
	          -o -name '*.js'   \
	          -o -name '*.mk'   \
	          -o -name '*.pl'   \
	          -o -name '*.pm'   \
	          -o -name '*.py'   \
	          -o -name '*.sh'   \
	          -o -name '*.asm'  \
	          -o -name '*.asp'  \
	          -o -name '*.awk'  \
	          -o -name '*.cpp'  \
	          -o -name '*.php'  \
	          -o -name '*.xml'  \
	          -o -name '*.yml'  \
	          -o -name '*.html' \
	          -o -name '*.java' \
	          -o -name '*.yaml' | sort > $CSCOPE_FILES

	# Validate source list
	NFILES=$(wc -l $FILE | awk '{ print $1 }')
	if [ $NFILES -eq 0 ]; then
		echo "$PKGNAME: No source files scanned !!!"
		rmdir $KTAGSDIR
		return 1
	fi

	return 0
}

ktags_generate_ctags() {
	if [ $VERBOSE -eq 1 ]; then
		CSCOPEDEBUG="-v"
		CTAGSDEBUG="--verbose"
	fi

	# Check Ctags already generated
	if [ $CTAGSGENERATED -eq 1 ]; then
		return 0
	fi

	# Create source list
	echo "$PKGNAME: generating Ctags ..."
	echo "    Enumerating files ..."
	ktags_scan_files $CSCOPE_FILES
	if [ $? -ne 0 ]; then
		echo "$PKGNAME: failed to generate source list !!!"
		exit 1
	fi

	# Generate Ctags and Cscope databases
	echo "    Generating Cscope ..."
	eval /usr/bin/cscope -b -i $CSCOPE_FILES -f $CSCOPE_DB $CSCOPEDEBUG

	echo "    Generating Ctags ..."
	eval /usr/bin/ctags -f $CTAGS_DB -w -L $CSCOPE_FILES $CTAGSDEBUG

	CTAGSGENERATED=1

	return $?
}

ktags_generate_gtags() {
	KTAGS_PKGSRC=$(basename $PWD)

	if [ $VERBOSE -eq 1 ]; then
		DEBUGRSYNC="-v"
		DEBUGHTAGS="--statistics"
		DEBUGGTAGS="--explain --statistics --warning"
	fi

	echo -e "$PKGNAME: generating Gtags ..."
	# Copy source repo to $KTAGSDIR to build tags
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
	htags --auto-completion \
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

	rm -rf $KTAGS_PKGSRC
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
	echo "If not work, vist $URL and explore."
	eval $HTTPBROWSER $URL $DEBUGSERVER &
	eval htags-server --retry 3 -b $HOST $PORT $DEBUGSERVER

	return $?
}

ktags_worker() {
	mkdir -p $KTAGSDIR

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
	PKGS=( ctags cscope global )
	for PKG in "${PKGS[@]}"
	do
		type $PKG > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "$PKGNAME: $PKG is not installed !!!"
			exit 1
		fi
	done
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
