#! /bin/bash

cleanup() {
  pyenv uninstall -f "${VENV_BUILD}"
  rm -rf "$tmppath"
  rm -rf "$origpath/$VERSION_TAG"
  cd "$origpath"
}

set -e

origpath="$(pwd)"
tmppath="$(mktemp -d)"
VERSION_TAG=${VERSION_TAG:-3.1.1}
# Python **MUST** be installed from the official package downloaded from:
# https://www.python.org/downloads/
# inside the /usr/local/bin directory.
# ref: https://cibuildwheel.readthedocs.io/en/stable/setup/#macos-windows-builds
PYTHON_VERSION=${PYTHON_VERSION:-3.10.8}
VENV_BUILD="tmp-psycopg-binary-build"
mkdir -p "$origpath/${VERSION_TAG}"
pyenv virtualenv -f ${PYTHON_VERSION} ${VENV_BUILD}
trap cleanup EXIT

cd "$tmppath"
echo "Running cibuildwheel in $tmppath ..."
git clone --branch=${VERSION_TAG} https://github.com/psycopg/psycopg .
pyenv local "${VENV_BUILD}"

python3 ./tools/build/copy_to_binary.py

pip install -U pip setuptools wheel
pip install cibuildwheel
# ref: https://cibuildwheel.readthedocs.io/en/stable/options/
# ref: https://github.com/psycopg/psycopg/blob/ecd7965/.github/workflows/packages.yml#L180
export CIBW_BUILD="cp310-macosx_arm64"
export CIBW_ARCHS_MACOS="arm64"
export CIBW_BEFORE_ALL_MACOS="./tools/build/wheel_macos_before_all.sh"
export CIBW_TEST_REQUIRES="./psycopg[test] ./psycopg_pool"
export CIBW_TEST_COMMAND="pytest {project}/tests -m 'not slow and not flakey' --color yes"
export CIBW_ENVIRONMENT=$'PSYCOPG_IMPL=binary\nPSYCOPG_TEST_DSN="dbname=postgres"\nPSYCOPG_TEST_WANT_LIBPQ_BUILD=">= 14"\nPSYCOPG_TEST_WANT_LIBPQ_IMPORT=">= 14"'
# During build, it will reinstall postgresql@14 in homebrew.
# If your homebrew has older major version of postgresql, it may fail to start the server
# as postgresql won't start with the database directory created with prior major versions.
# In this case you may need to manually clean up the data directory.
cibuildwheel --platform macos psycopg_binary

cp ./wheelhouse/*.whl "$origpath/"
cd "$origpath"
