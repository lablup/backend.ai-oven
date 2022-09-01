#!/bin/sh

cleanup() {
  pyenv uninstall -f "${VENV_BUILD}"
  rm -rf "$tmppath"
  rm -rf "$origpath/$VERSION"
  cd "$origpath"
}

set -e

origpath="$(pwd)"
tmppath="$(mktemp -d)"
VERSION=${VERSION:-3.1.0}
VERSION_TAG=${VERSION_TAG:-3.1}
PYTHON_VERSION=${PYTHON_VERSION:3.10.5}
VENV_BUILD="tmp-psycopg-binary-build"

mkdir -p "$origpath/${VERSION}"
pyenv virtualenv -f ${PYTHON_VERSION} ${VENV_BUILD}
trap cleanup EXIT

cd "$tmppath"
pyenv local "${VENV_BUILD}"
pip install -U pip setuptools wheel
pip wheel -w ./wheelhouse "psycopg[c]==${VERSION}"
cp ./wheelhouse/psycopg*.whl "$origpath/$VERSION"
mv "$origpath/$VERSION/psycopg_c-${VERSION_TAG}-cp310-cp310-macosx_12_0_arm64.whl" \
   "$origpath/psycopg_binary-${VERSION_TAG}-cp310-cp310-macosx_12_0_arm64.whl"
cd "$origpath"
