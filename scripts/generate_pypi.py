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
OUTPUT_DIRECTORY = os.environ.get('OUTPUT_DIRECTORY')

BASE_HTML = textwrap.dedent('''
    <!DOCTYPE html>
    <html>
        <head>
            <title>Index of {name}</title>
        </head>
        <body>
            <h1>Index of {name}</h1>
        </body>
    </html>
''')


def generate_html(meta: Mapping[str, str], outpath: Path, name: str = 'package') -> None:
    soup = BSoup(BASE_HTML.format_map({'name': name}), 'html.parser')
    for wheel_name, url in meta.items():
        tag = soup.new_tag('a', href=url)
        tag.string = wheel_name
        soup.html.body.append(tag)
        soup.html.body.append(soup.new_tag('br'))
    with open(outpath, 'w') as fw:
        fw.write(soup.prettify())


def create_simple_repository(meta: Mapping[str, Mapping[str, str]], outdir: Path) -> None:
    generate_html({k: f'{k}/' for k in meta.keys()}, outdir / 'index.html', name='simple')
    for project, wheels in meta.items():
        (outdir / project).mkdir(parents=True, exist_ok=True)
        generate_html(wheels, outdir / project / 'index.html', name=project)


def main():

    entrypoint = Path('pypi')
    if OUTPUT_DIRECTORY is not None:
        output_directory = Path(OUTPUT_DIRECTORY)
    else:
        output_directory = entrypoint
    projects = list((entrypoint / 'projects').iterdir())
    package_output: MutableMapping[str, str] = {}
    simple_output: MutableMapping[str, MutableMapping[str, str]] = {}
    hash_cache: MutableMapping[str, str] = {}
    if (output_directory / 'hash-lock.json').exists():
        with open(entrypoint / 'hash-lock.json', 'r') as fr:
            hash_cache = json.loads(fr.read())

    if len(projects) == 0:
        print('no project to serve!')
        sys.exit(0)

    for project in projects:
        if not project.is_dir():
            continue
        simple_output[project.name] = {}
        for wheel in project.iterdir():
            if not wheel.is_file() or wheel.name.startswith('.') or not wheel.name.endswith('.whl'):
                continue
            if _hash := hash_cache.get(f'{project.name}:{wheel.name}'):
                hash = _hash
            else:
                with open(wheel, 'rb') as fr:
                    hash = hashlib.sha256(fr.read()).hexdigest()
                hash_cache[f'{project.name}:{wheel.name}'] = hash
            url = (
                f'https://media.githubusercontent.com/media/{REPOSITORY}/{BRANCH}'
                f'/pypi/projects/{project.name}/{wheel.name}#sha256={hash}'
            )
            package_output[wheel.name] = url
            simple_output[project.name][wheel.name] = url

    generate_html({'simple': 'simple/', 'package': 'package/'}, output_directory / 'index.html', name='pypi')
    (output_directory / 'package').mkdir(parents=True, exist_ok=True)
    (output_directory / 'simple').mkdir(parents=True, exist_ok=True)
    generate_html(package_output, output_directory / 'package' / 'index.html')
    create_simple_repository(simple_output, output_directory / 'simple')

    with open(output_directory / 'hash-lock.json', 'w') as fw:
        fw.write(json.dumps(hash_cache, ensure_ascii=False, indent=4))


if __name__ == '__main__':
    main()
