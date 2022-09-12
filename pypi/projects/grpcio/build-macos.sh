#!/bin/sh
cleanup() {
    pyenv uninstall -f "${VENV_BUILD}"
    rm -rf "$tmppath"
}

VERSION=${VERSION:-1.48.1}  # target grpcio version
PYTHON_VERSION=${PYTHON_VERSION:-3.10.5}   # Python version to install and run cibuildwheel
VENV_BUILD=${VENV_BUILD:-tmp-grpcio-build} # PyEnv virtualenv name to install cibuildwheel

origpath="$(pwd)"
tmppath="$(mktemp -d)"
target_architectures="arm64 x86_64"
# System-wide installtion of python is required for every minor release (3.8, 3.9, 3.10, ...).
build_target_python_versions="3.9 3.10"

for pyver in $build_target_python_versions; do
    pkgutil --pkgs | grep "PythonFramework-${pyver}" > /dev/null
    if [ $? -ne 0 ]; then
        echo "System-wide installation of Python ${pyver} not found."
        echo "Please download and install one from https://www.python.org/downloads/macos/"
        exit 1
    fi
done

set -e

pyenv virtualenv "${PYTHON_VERSION}" "${VENV_BUILD}"
trap cleanup EXIT
cd "${tmppath}"
pyenv local "${VENV_BUILD}"
pip install -U pip setuptools wheel cibuildwheel
set +e
pip download --no-binary grpcio --no-binary grpcio-tools  "grpcio==${VERSION}" "grpcio-tools==${VERSION}"
ls -al
tar xf "grpcio-${VERSION}.tar.gz"
tar xf "grpcio-tools-${VERSION}.tar.gz"

for pyver in $build_target_python_versions; do
    for arch in $target_architectures; do
        build_target="cp${echo $pyver | sed 's/.//'}-macosx_${arch}"
        cd "grpcio-tools-${VERSION}"
        echo "building grpcio-tools wheel for ${build_target}"
        CIBW_BUILD_FRONTEND=pip \
        CIBW_ENVIRONMENT_MACOS="GRPC_PYTHON_BUILD_WITH_CYTHON=1" \
        CIBW_BEFORE_BUILD="pip install Cython" \
        CIBW_ARCHS_MACOS="${arch}" \
        CIBW_TEST_SKIP="*_${arch}" \
        CIBW_BUILD="${build_target}" \
            cibuildwheel --platform macos --output-dir ../wheelhouse .
        if [ $? -ne 0 ]; then
            exit $?
        fi
        cd "../grpcio-${VERSION}"
        echo "building grpcio wheel for ${build_target}"
        CIBW_BUILD_FRONTEND=pip \
        CIBW_ENVIRONMENT_MACOS="GRPC_PYTHON_BUILD_WITH_CYTHON=1" \
        CIBW_BEFORE_BUILD="pip install -r requirements.txt" \
        CIBW_ARCHS_MACOS="${arch}" \
        CIBW_TEST_SKIP="*_${arch}" \
        CIBW_BUILD="${build_target}" \
            cibuildwheel --platform macos --output-dir ../wheelhouse .
        if [ $? -ne 0 ]; then
            exit $?
        fi
        cd ..
    done
done

set -e
cp wheelhouse/grpcio*.whl "$origpath"
pyenv uninstall -f "${VENV_BUILD}"
cd "$origpath"
mv grpcio_tools* ../grpcio-tools