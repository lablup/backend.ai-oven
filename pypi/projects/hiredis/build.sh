#!/bin/sh
set -e
origpath=$(pwd)
VERSION=${VERSION:-2.0.0}
pyenv virtualenv 3.10.5 tmp-hiredis-build
cd $(mktemp -d)
pyenv local tmp-hiredis-build
pip install -U pip setuptools wheel
set +e
pip wheel -w ./wheelhouse hiredis==$VERSION
if [ $? -ne 0 ]; then
    pyenv uninstall -f tmp-hiredis-build
    echo "Meh, looks like the build has failed. Sadly, nobody has yet figured out why this fails. But here are some workarounds:"
    echo "    1) unset LDFLAGS CFLAGS CPPFLAGS PKG_CONFIG_PATH"
    echo "Try building again with one of the options above applied."
    echo "If it still fails, then try combining the options (1-2, 2-3, 1-3, 1-2-3, ...)."
    echo "If none of these works, then sorry. You're out of luck. :("
    exit $?
fi
set -e
cp ./wheelhouse/hiredis*.whl $origpath
pyenv uninstall -f tmp-hiredis-build