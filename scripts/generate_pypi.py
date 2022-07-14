import hashlib
import json
import os
from pathlib import Path
import sys
import textwrap
from typing import Mapping, MutableMapping
from bs4 import BeautifulSoup as BSoup

REPOSITORY = os.environ['REPOSITORY']
BRANCH = os.environ.get('BRANCH', 'main')

BASE_HTML = textwrap.dedent('''
    <!DOCTYPE html>
    <html>
        <head>
            <title>Index of pypi</title>
        </head>
        <body>
            <h1>Index of pypi</h1>
        </body>
    </html>
''')


def generate_html(meta: Mapping[str, str]) -> str:
    soup = BSoup(BASE_HTML, 'html.parser')
    for wheel_name, url in meta.items():
        tag = soup.new_tag('a', href=url)
        tag.string = wheel_name
        soup.html.body.append(tag)
        soup.html.body.append(soup.new_tag('br'))
    return soup.prettify()


def main():

    entrypoint = Path('pypi')
    wheels = os.listdir(entrypoint)
    output: MutableMapping[str, str] = {}
    hash_cache: MutableMapping[str, str] = {}
    if (entrypoint / 'hash-lock.json').exists():
        with open(entrypoint / 'hash-lock.json', 'r') as fr:
            hash_cache = json.loads(fr.read())

    if len(wheels) == 0:
        print('no file to serve!')
        sys.exit(0)

    for wheel in wheels:
        if wheel.startswith('.') or not wheel.endswith('.whl'):
            continue
        if _hash := hash_cache.get(wheel):
            hash = _hash
        else:
            with open(entrypoint / wheel, 'rb') as fr:
                hash = hashlib.sha256(fr.read()).hexdigest()
            hash_cache[wheel] = hash
        output[wheel] = f'https://media.githubusercontent.com/media/{REPOSITORY}/{BRANCH}/pypi/{wheel}#sha256={hash}'

    with open(entrypoint / 'index.html', 'w') as fw:
        fw.write(generate_html(output))
    with open(entrypoint / 'hash-lock.json', 'w') as fw:
        fw.write(json.dumps(hash_cache, ensure_ascii=False, indent=4))


if __name__ == '__main__':
    main()
