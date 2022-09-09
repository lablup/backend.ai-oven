#!/bin/sh
set -e
export CIBW_BUILD_FRONTEND=pip
export CIBW_ENVIRONMENT_MACOS="GRPC_PYTHON_BUILD_WITH_CYTHON=1"
export CIBW_BEFORE_BUILD="pip install -r requirements.txt"

origpath=$(pwd)
VERSION=${VERSION:-1.48.1}
PYTHON_VERSION=${PYTHON_VERSION:-3.10.5}
pyenv virtualenv $PYTHON_VERSION tmp-grpcio-build
cd $(mktemp -d)
pyenv local tmp-grpcio-build
pip install -U pip setuptools wheel cibuildwheel
set +e
pip download --no-binary grpcio grpcio
tar xf *.tar.gz
cd grpcio-*/

for pyver in "cp38" "cp39" "cp310"; do
    for arch in "arm64" "x86_64"; do
        CIBW_ARCHS_MACOS="${arch}" \
        CIBW_TEST_SKIP="*_${arch}" \
        CIBW_BUILD="${pyver}-macosx_${arch}" \
            cibuildwheel --output-dir ../wheelhouse
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
    done
done
set -e
cp ./wheelhouse/grpcio*.whl $origpath
pyenv uninstall -f tmp-grpcio-build
