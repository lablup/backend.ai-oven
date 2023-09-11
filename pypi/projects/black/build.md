# Building mypyc-compiled Black binary wheels

This boosts the performance of the Black formatter, though having the binary wheels are optional.

```console
$ git clone https://github.com/psf/black
$ git checkout ${RELEASE_TAG}
```

Then install some build prerequisites in a venv:

```console
$ pip install hatch hatch-vcs hatch-fancy-pypi-readme hatch-mypyc
```

Check if the version is cleanly recognized:

```console
$ hatch version
```

Run the mypyc build.  
This step takes about *2-3 minutes* at an aarch64 Linux VM running on an Apple Silicon (M1, arm64) machine.

```console
$ HATCH_BUILD_HOOKS_ENABLE=1 hatch build -t wheel
```

Rename the wheel file to be a "vanilla" linux wheel so that `auditwheel` can correct the platofrm tag.  
(Apply your `RELEASE_TAG` version in the filenames instead of `23.7.0`.)

```console
$ mv dist/black-23.7.0-cp311-cp311-manylinux_2_35_aarch64.whl dist/black-23.7.0-cp311-cp311-linux_aarch64.whl
```

Repair the wheel to conform with the manylinux2014 platform.

```console
$ docker run -u "$(id -u):$(id -g)" -i -t -v `pwd`:/io quay.io/pypa/manylinux2014_aarch64 auditwheel repair -w /io/dist /io/dist/black-23.7.0-cp311-cp311-linux_aarch64.whl
```

Copy the repaired wheel files inside the `dist` directory here once done.
