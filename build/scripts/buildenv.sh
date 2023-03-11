#!/bin/bash

set -eu

source ./build/scripts/buildspecs.in

echo "${BOLD}Building ${PACKAGE} build environment ...${NC}"

if [ "$PLATFORM" == "TERMUX" ] || [ $(id -u) -eq 0 ]; then
	SUDO=""
else
	SUDO="sudo"
fi

if [ "$PLATFORM" == "TERMUX" ]; then
	PACKAGES+="ctags cscope global"
else
	PACKAGES+="cscope universal-ctags global"
fi

$SUDO apt update && \
$SUDO apt install --no-install-recommends $PACKAGES

exit $?

#EOF
