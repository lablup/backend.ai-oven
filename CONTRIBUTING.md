# Uploading baked artifacts to Oven

## Common Prerequisites

- Check if `.gitattributes` match your artifacts. If not, Git LFS will ignore your file.

## PyPI

1. Create a folder under `pypi`, with name representating matching PyPI project.
2. Move wheels to newly created folder and `git add` moved files.
3. Create PR and merge branch.
4. Thats it! `generate_index` action will create PyPI index automatically so that PIP can access to uploaded wheels. Check `gh-pages` branch if you want to see the output of generated indexes.
