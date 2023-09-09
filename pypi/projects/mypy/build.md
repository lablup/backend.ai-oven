# Building mypyc-compiled Mypy binary wheels

This boosts the performance of the Mypy typechecker, though having the binary wheels are optional.

```
$ git clone https://github.com/mypyc/mypy_mypyc-wheels
$ cd mypy_mypyc-wheels
$ git checkout ${RELEASE_TAG}
$ git clone https://github.com/python/mypy --recurse-submodules
$ git -C mypy checkout $(cat mypy_commit)
$ pipx run cibuildwheel --config=cibuildwheel.toml --platform=linux --archs=aarch64 mypy
```

The build takes about *two hours* at an aarch64 Linux VM running on an Apple Silicon (M1, arm64) machine.
Copy the wheel files inside the wheelhouse directory here one done.
