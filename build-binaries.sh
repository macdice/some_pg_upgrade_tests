#!/bin/sh

set -e

TARGET_BRANCH=collation-versioning

if [ ! -e postgres ] ; then
  git clone https://github.com/postgres/postgres.git
  # ... also probably need to add check out the patched branch...
fi
mkdir -p install
mkdir -p install-icu

base_path=`pwd`

# the branches I'm interested in today...
for branch in $TARGET_BRANCH REL_13_STABLE REL9_6_STABLE
do
  # build non-ICU variant
  (
    cd postgres
    git checkout $branch
    rm -f src/include/dynloader.h
    ./configure --prefix=$base_path/install/$branch --enable-cassert --enable-debug
    make -s clean
    make -s -j16
    make -s install
    make -s check
  )
  # if new enough then build ICU variant too
  if echo "$branch" | grep -v -E 'REL[6789]' > /dev/null ; then
    (
      cd postgres
      git checkout $branch
      rm -f src/include/dynloader.h
      ./configure --prefix=$base_path/install-icu/$branch --enable-cassert --enable-debug --with-icu
      make -s clean
      make -s -j16
      make -s install
      make -s check
    )
  fi
done
