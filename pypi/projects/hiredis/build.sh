#!/bin/sh
set -e
export CFLAGS=-std=c99
origpath=$(pwd)
VERSION=${VERSION:-1.1.0}
mkdir $origpath/$VERSION
pyenv virtualenv 3.10.5 tmp-hiredis-build
cd $(mktemp -d)
pyenv local tmp-hiredis-build
pip install -U pip setuptools wheel
set +e
pip wheel -w ./wheelhouse hiredis==$VERSION
if [ $? -ne 0 ]; then
    pyenv uninstall -f tmp-hiredis-build
    echo "Meh, looks like the build has failed. Sadly, nobody has yet figured out why this fails. But here are some workarounds:"
    echo "    1) set CFLAGS=-std=c99"
    echo "Try building again with one of the options above applied."
    echo "If it still fails, then re-try it."
    echo "If none of these works, then sorry. You're out of luck. :("
    exit $?
fi
set -e
cp ./wheelhouse/hiredis*.whl $origpath/$VERSION
pyenv uninstall -f tmp-hiredis-build
