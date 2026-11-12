"""日本語の UI の文字列で，和文と英数字の間に空白を入れていないことを確かめる。

macOS は日本語を和欧文間の空白なしで書き，描画のときに見た目の間隔を足す。
Resources/ja.lproj の .strings と .xib，Swift のソースの文字列リテラルを調べる。
引数 --app でビルドしたアプリを渡すと，コンパイル済みの ja.lproj の nib と strings も調べる。
引数 --mutation で，空白を入れた文字列を足すと検出されることを確かめる。
"""
from pathlib import Path
import plistlib
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
CJK = '[　-〿぀-ヿ㐀-鿿！-｠]'
SPACED = re.compile(f'{CJK} [A-Za-z0-9]|[A-Za-z0-9] {CJK}')
LITERAL = re.compile(r'"((?:[^"\\\n]|\\.)*)"')
JAPANESE = re.compile(CJK)


def report(failures, where, text):
    for match in SPACED.finditer(text):
        failures.append(f'{where}: {text[max(0, match.start() - 12):match.end() + 12]!r}')


def main():
    arguments = sys.argv[1:]
    mutation = '--mutation' in arguments
    failures, checked = [], 0
    for path in sorted((ROOT / 'Resources/ja.lproj').iterdir()):
        if path.suffix not in ('.strings', '.xib'):
            continue
        text = path.read_text(encoding='utf-8')
        if mutation and path.name == 'MainMenu.xib':
            text = text.replace('TeX2imgを終了', 'TeX2img を終了')
        checked += 1
        report(failures, path.relative_to(ROOT), text)
    for path in sorted((ROOT / 'Sources').rglob('*.swift')):
        for number, line in enumerate(path.read_text(encoding='utf-8').splitlines(), 1):
            for literal in LITERAL.finditer(line):
                if JAPANESE.search(literal.group(1)):
                    report(failures, f'{path.relative_to(ROOT)}:{number}', literal.group(1))
    assert checked == 4, checked
    if '--app' in arguments:
        app = Path(arguments[arguments.index('--app') + 1])
        compiled = 0
        for path in sorted((app / 'Contents/Resources/ja.lproj').rglob('*')):
            if path.is_dir():
                continue
            data = path.read_bytes()
            if data.startswith(b'bplist'):
                value = plistlib.loads(data)
                texts = [o for o in value.get('$objects', []) if isinstance(o, str)] if isinstance(value, dict) and '$objects' in value \
                    else [v for v in (value.values() if isinstance(value, dict) else []) if isinstance(v, str)]
            else:
                texts = [data.decode('utf-8', 'ignore')]
            compiled += 1
            for text in texts:
                report(failures, path.relative_to(app), text)
        assert compiled >= 4, compiled
    if mutation:
        assert failures, 'a spaced title was not detected'
        print(f'DETECTED {failures[0]}')
        return
    assert not failures, '\n'.join(failures)
    print(f'PASS no space between Japanese and Latin text in {checked} interface files and the Swift string literals')


main()
