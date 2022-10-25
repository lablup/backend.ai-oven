#!/bin/bash
cleanup() {
    rm -rf "$tmppath"
}

VERSION=${VERSION:-1.49.1}  # target grpcio version
TARGET_PYVER=${TARGET_PYVER:-3.9 3.10 3.11}  # target python version
TARGET_ARCH=${TARGET_ARCH:-arm64 x86_64}  # target architecture

tmppath="$(mktemp -d)"

# System-wide installtion of python is required for every minor release (3.8, 3.9, 3.10, 3.11, ...).
for pyver in $TARGET_PYVER; do
    pkgutil --pkgs | grep "PythonFramework-${pyver}" > /dev/null
    if [ $? -ne 0 ]; then
        echo "System-wide installation of Python ${pyver} not found."
        echo "Please download and install one from https://www.python.org/downloads/macos/"
        exit 1
    fi
done

read -ra version_arr <<<"$TARGET_PYVER"
venv_python_version=${version_arr[0]}
venv_python="python${venv_python_version}"
echo "using ${venv_python} as cibuildwheel python"

realpath_script="import os,sys;print(os.path.realpath('$0/../../../..'))"
root_dir="$(${venv_python} -c "${realpath_script}")"

set -e

trap cleanup EXIT
cd "${tmppath}"
$venv_python -m venv "venv-build"
source "venv-build/bin/activate"

pip install -U pip setuptools wheel cibuildwheel
set +e
pip download --no-binary grpcio --no-binary grpcio-tools  "grpcio==${VERSION}" "grpcio-tools==${VERSION}"
ls -al
tar xf "grpcio-${VERSION}.tar.gz"
tar xf "grpcio-tools-${VERSION}.tar.gz"

for pyver in $TARGET_PYVER; do
    for arch in $TARGET_ARCH; do
        build_target="cp$(echo $pyver | sed 's/\.//')-macosx_${arch}"
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
cp wheelhouse/grpcio-*.whl "${root_dir}/pypi/projects/grpcio"
cp wheelhouse/grpcio_tools-*.whl "${root_dir}/pypi/projects/grpcio-tools"

cleanup
