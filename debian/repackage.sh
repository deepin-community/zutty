#!/bin/bash

# Repackage zutty master branch and generate a version for it based on
# the git version and the date of the last commit.
# Needs git, tar and python3-dev (to run the waf)

UPSTREAM_GIT_URL=https://github.com/tomszilagyi/zutty.git
TARGET=zutty
DFSG=1

echo "Getting upstream..."
test -d ${TARGET} && ( cd ${TARGET} && git pull )
test ! -d ${TARGET} && git clone ${UPSTREAM_GIT_URL} ${TARGET}
cd ${TARGET}

echo "Removing WAF binary blob..."
# Based on https://wiki.debian.org/UnpackWaf
./waf --help &> /dev/null
mv .waf3-*/* .
sed -i '/^#==>$/,$d' waf
rmdir .waf3-*
find . -type d -name __pycache__ -exec rm -rf '{}' +

echo "Removing unnecessary files..."
rm doc/org.css

echo "Computing version..."
GIT_VERSION=$(git describe | sed 's,-,.,' | env G=$(date +%s) sed "s,-g.*,,")
# 0.9-2-g67b54f9 -> 0.9.2
while : ; do [[ ${GIT_VERSION} =~ ^[0-9]*\.[0-9]*\.[0-9]*$ ]] && break; GIT_VERSION+=".0"; done
# 0.10 -> 0.10.0
LAST_COMMIT_DATE_EMAIL="$(git show | grep ^Date | sed 's,^Date:\s*,,' | awk '{print $1", "$3" "$2" "$5" "$4" "$6}')"
LAST_COMMIT_DATE_TIME_STAMP=$(date +%Y%m%d -d "$LAST_COMMIT_DATE_EMAIL")
UPSTREAM_VERSION=${GIT_VERSION}.${LAST_COMMIT_DATE_TIME_STAMP}
DFSG_VERSION="${UPSTREAM_VERSION}+dfsg${DFSG}"
cd ..

echo "Compressing..."
ZUTTY="zutty-${DFSG_VERSION}"
test ! -d ${ZUTTY} && mv ${TARGET} ${ZUTTY}
test ! -e ./${ZUTTY}.tar.xz && tar --create --xz --file ./${ZUTTY}.tar.xz --exclude-vcs --totals ${ZUTTY}
rm -rf ${ZUTTY}

echo "Repackaged as ${ZUTTY}.tar.xz"
