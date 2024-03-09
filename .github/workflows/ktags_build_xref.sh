#!/bin/bash

set -u

ktags_update_html() {
	local FILE=$1

	if [ ! -f "$FILE" ]; then
		echo "Oops! file '$FILE' is not exist."
		exit 1
	fi

	echo "Updating $FILE ..."

	sed -i '
		# Remove content between "<div class='poweredby'>" and "<hr />"
		/<div class='"'poweredby'"'>/,/<hr \/>/d;

		# Change "cols='200" to "cols='300"
		s/cols='"'200/cols='"'300/;

		# Change "rows='50%" to "rows='100%"
		s/rows='"'50%/rows='"'100%/;

		# Remove "<frame name='defines' id='defines' src='defines.html' />"
		/<frame name='"'defines'"' id='"'defines'"' src='"'defines.html'"' \/>/d;

		# Remove content between "<h2 class='header'><a href='defines.html'>DEFINITIONS</a></h2>" and "<hr />"
		/<h2 class='"'"'header'"'"'><a href='"'"'defines.html'"'"'>DEFINITIONS<\/a><\/h2>/,/<hr \/>/d;

		# Remove content between "<h2 class='header'><a href='files.html'>FILES</a></h2>" and "<hr />"
		/<h2 class='"'"'header'"'"'><a href='"'"'files.html'"'"'>FILES<\/a><\/h2>/,/<hr \/>/d
	' "$FILE"

	return $?
}

ktags_update_style() {
	local FILE=$1

	if [ ! -f "$FILE" ]; then
		echo "Oops! file '$FILE' is not exist."
		exit 1
	fi

	echo "Updating $FILE ..."

	sed -i 's/#f5f5dc/#e0eaee/g' $FILE

	return $?
}

ktags_update_mode() {
	local FILE=$1

	if [ ! -f "$FILE" ]; then
		echo "Oops! file '$FILE' is not exist."
		exit 1
	fi

	echo "Updating $FILE ..."

	chmod +r $FILE # Fixing file permissions to upload artifacts

	return $?
}

ktags_insert_url() {
	local REPOURL="$1"

	if [ -z "$REPOURL" ]; then
		echo "Oops! invalid repository url"
		exit 1
	fi

	sed -i "/<h1 class='title'>/a <a href=\"$REPOURL\" target=\"_blank\">$REPOURL</a>" HTML/index.html
	sed -i "/<h1 class='title'>/a <a href=\"$REPOURL\" target=\"_blank\">$REPOURL</a>" HTML/mains.html
}

ktags_build() {
	local REPONAME="$1"

	if [ -z "$REPONAME" ]; then
		echo "Oops! invalid repository name"
		exit 1
	fi

	htags -g --auto-completion --colorize-warned-line --frame \
	      --icon --line-number --other --symbol --table-list --fixed-guide \
	      --verbose --warning --tree-view=filetree --title "$REPONAME"
}

# Main
ktags_build        "$1"
ktags_insert_url   "$2"

ktags_update_mode  'HTML/rebuild.sh'
ktags_update_html  'HTML/index.html'
ktags_update_html  'HTML/mains.html'
ktags_update_style 'HTML/style.css'
ktags_update_style 'HTML/js/jquery.treeview.css'

exit $?

# EOF
