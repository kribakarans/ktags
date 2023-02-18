#!/bin/bash

PKGNAME=Ktags
PKGVERSION=1.1-c

OBJDIR=obj
DISTDIR=dist
BUILDDIR=build

KTAGSDIR=__ktags
VIMRC=$HOME/.vimrc
BASHRC=$HOME/.bashrc
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
	    -a  --all       -- Generate both Ctags and Gtags symbols
	    -b  --browse    -- Instantly explore the source code in web-browser at $URL
	    -c  --ctags     -- Generate tags with Ctags tool
	    -g  --gtags     -- Generate tags eith Gtags tool
	    -d  --delete    -- Delete tags database files in current path
	    -i  --install   -- First time initialisation to install bash and vim scripts to the local user
	    -u  --uninstall -- Uninstall the bash and vim scripts of the local user
	    -v  --version   -- Print package version
	    -V  --verbose   -- Enable debug mode
	    -h  --help      -- Show this help menu
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

	return $?
}

#------------------------------------------
# Ktags core functions
#------------------------------------------

ktags_delete_xref() {
	if [ $VERBOSE -eq 1 ]; then
		DEBUGRM="-v"
	fi

	echo "$PKGNAME: removing tags ..."
	rm -rf $KTAGSDIR $DEBUGRM

	exit 0
}

ktags_scan_files() {
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
	          -o -name '*.yaml' \
	          -o -name '*.aliases' | grep -vE "__|-build/" | sort > $CSCOPE_FILES

	# Validate source list
	if [[ $(wc -l $CSCOPE_FILES | awk '{ print $1 }') -eq 0 ]]; then
		echo "$PKGNAME: No source files scanned !!!"
		rm -rf $KTAGSDIR
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

	# Install aliases
	ktags_install_aliases

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
	          --exclude "__*" \
	          --exclude "*.so*" \
	          --exclude "*.out" \
	          --exclude "*.swo" \
	          --exclude "*.swp" \
	          --exclude ".git*" \
	          --exclude "$OBJDIR" \
	          --exclude "$DISTDIR" \
	          --exclude "$BUILDDIR" \
	          --exclude "$KTAGSDIR" $PWD $KTAGSDIR $DEBUGRSYNC

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

ktags_browse_xref() {
	if [ ! -d "$KTAGSDIR/HTML" ]; then
		echo "Ktags is not generated !!!"
		echo "Run 'ktags --gtags' and try again"
		return 1
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

ktags_uninstall_aliases() {
	if [[ $(grep "tags=$KTAGSDIR" $VIMRC) ]]; then
		echo "Removing vim aliases ..."
		sed -i "/$KTAGSDIR/d" $VIMRC
	fi

	if [[ $(grep "$KTAGSDIR/cscope" $BASHRC) ]]; then
		echo "Removing bash aliases ..."
		sed -i "/$KTAGSDIR/d" $BASHRC
	fi

	return $?
}

ktags_install_aliases() {
	if [[ ! $(grep "tags=$KTAGSDIR" $VIMRC) ]]; then
		echo "Installing vim aliases ..."
		echo "set tags=$KTAGSDIR/tags" >> $VIMRC
	fi

	if [[ ! $(grep "$KTAGSDIR/cscope" $BASHRC) ]]; then
		echo "Installing bash aliases ..."
		echo "alias cs='cscope -df $KTAGSDIR/cscope\$1.out'" >> $BASHRC
	fi

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
			ktags_browse_xref
			;;
		ctags)
			ktags_generate_ctags
			;;
		gtags)
			ktags_generate_gtags
			;;
		delete)
			ktags_delete_xref
			;;
		install)
			ktags_install_aliases
			;;
		uninstall)
			ktags_uninstall_aliases
			;;
		*)
			ktags_generate_ctags
			;;
	esac

	# Remove empty ktag directory

	return $?
}

parse_cmdline() {
	SHORT_OPTS='abcdDghiuvV'
	LONG_OPTS='all,browse,ctags,delete,deploy,gtags,help,install,uninstall,verbose,version'

	GETOPTS=$(getopt -o $SHORT_OPTS --long $LONG_OPTS -- "$@")
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
			-i | --install)
				KTAGSOPTS=install
				shift
				;;
			-u | --uninstall)
				KTAGSOPTS=uninstall
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
			--) shift; break ;; # -- means the end of the arguments
			*) echo "Unexpected option: $1" # will not hit here
		esac
	done

	#echo "Remaining arguments: $@"

	return $?
}

validate_packages()
{
	# Validate required tools are installed
	PKGS=( ctags cscope global )
	for PKG in "${PKGS[@]}"
	do
		if [[ ! $(which $PKG 2>/dev/null) ]]; then
			echo "$PKGNAME: $PKG is not installed !!!"
			exit 1
		fi
	done

	return $?
}

ktags_init() {
	validate_packages
	return $?
}

ktags_main() {
	ktags_init       # Initialize package
	parse_cmdline $@ # Parse cmdline options
	ktags_worker     # Ktags symbol generator
	return $?
}

#------------------------------------------
# Ktags main procedure
#------------------------------------------

ktags_main $@

#EOF
