#!/bin/sh
set -e
origpath=$(pwd)
VERSION=${VERSION:-1.48.0}
pyenv virtualenv 3.10.5 tmp-grpcio-build
cd $(mktemp -d)
pyenv local tmp-grpcio-build
pip install -U pip setuptools wheel
set +e
pip wheel -w ./wheelhouse grpcio==$VERSION grpcio-tools==$VERSION
if [ $? -ne 0 ]; then
    pyenv uninstall -f tmp-grpcio-build
    echo "Meh, looks like the build has failed. Sadly, nobody has yet figured out why this fails. But here are some workarounds:"
    echo "    1) unset LDFLAGS CFLAGS CPPFLAGS PKG_CONFIG_PATH"
    echo "    2) export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=true GRPC_PYTHON_BUILD_SYSTEM_ZLIB=true"
    echo "    3) export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=false GRPC_PYTHON_BUILD_SYSTEM_ZLIB=false"
    echo "Try building again with one of the options above applied."
    echo "If it still fails, then try combining the options (1-2, 2-3, 1-3, 1-2-3, ...)."
    echo "If none of these works, then sorry. You're out of luck. :("
    exit $?
fi
set -e
cp ./wheelhouse/grpcio*.whl $origpath
pyenv uninstall -f tmp-grpcio-build
