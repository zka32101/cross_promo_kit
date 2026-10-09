#!/usr/bin/env python3
"""掲載リスト（Remote Config `cross_promo_apps`）の検証と、投入用データの生成。

使い方:
  python3 tools/cross_promo_list.py validate [FILE] [--check-urls]
  python3 tools/cross_promo_list.py snippet  [FILE]

FILE の既定値は docs/cross_promo_apps.json。
validate はエラーがあれば終了コード 1。--check-urls は storeUrl / iconUrl が
HTTP 200 を返すか実際にアクセスして確認する（ネットワークが必要）。
snippet は Remote Config に貼る値（1行の JSON 文字列）と、テンプレート用の
パラメータ断片を出力する。本番設定の更新なので、投入は内容を確認してから手で行うこと。
"""
import argparse
import json
import sys
import urllib.error
import urllib.request
from pathlib import Path

DEFAULT_FILE = Path(__file__).resolve().parent.parent / "docs" / "cross_promo_apps.json"
KEY = "cross_promo_apps"
REQUIRED = ["id", "name", "tagline", "iconUrl", "storeUrl", "category"]
# docs/ROLLOUT.md の方針で決めたカテゴリ。増やすときはここと ROLLOUT.md を合わせて更新する。
KNOWN_CATEGORIES = {"小学コレ", "うかラボ", "パズル・ゲーム"}
PLAY_PREFIX = "https://play.google.com/store/apps/details?id="


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def validate(apps, check_urls=False):
    errors, warnings = [], []
    if not isinstance(apps, list):
        return ["トップレベルは配列である必要があります"], warnings
    seen = set()
    for i, app in enumerate(apps):
        where = f"[{i}]"
        if not isinstance(app, dict):
            errors.append(f"{where} オブジェクトではありません")
            continue
        for key in REQUIRED:
            value = app.get(key)
            if not isinstance(value, str) or not value.strip():
                errors.append(f"{where} {key} が未設定または空です")
        app_id = app.get("id")
        where = f"[{i}] {app_id}" if isinstance(app_id, str) and app_id else where
        if isinstance(app_id, str) and app_id:
            if app_id in seen:
                errors.append(f"{where} id が重複しています")
            seen.add(app_id)
            if app_id.endswith((".debug", ".dev")):
                errors.append(f"{where} id にデバッグサフィックスが付いています")
        store = app.get("storeUrl")
        if isinstance(store, str) and store:
            if not store.startswith("https://"):
                errors.append(f"{where} storeUrl は https:// で始めてください")
            elif store.startswith(PLAY_PREFIX) and isinstance(app_id, str):
                if store[len(PLAY_PREFIX):].split("&")[0] != app_id:
                    errors.append(f"{where} storeUrl の id が applicationId と一致しません")
        category = app.get("category")
        if isinstance(category, str) and category and category not in KNOWN_CATEGORIES:
            warnings.append(f"{where} 未知のカテゴリ: {category}（綴りを確認。新設なら ROLLOUT.md と KNOWN_CATEGORIES を更新）")
        if check_urls:
            for key in ("storeUrl", "iconUrl"):
                url = app.get(key)
                if isinstance(url, str) and url.startswith("https://"):
                    status = http_status(url)
                    if status != 200:
                        errors.append(f"{where} {key} が HTTP {status} を返しました: {url}")
    return errors, warnings


def http_status(url):
    req = urllib.request.Request(url, headers={"User-Agent": "cross-promo-list-check"})
    try:
        with urllib.request.urlopen(req, timeout=15) as res:
            return res.status
    except urllib.error.HTTPError as e:
        return e.code
    except Exception as e:  # noqa: BLE001
        return f"接続失敗({type(e).__name__})"


def cmd_validate(args):
    apps = load(args.file)
    errors, warnings = validate(apps, args.check_urls)
    for w in warnings:
        print(f"警告: {w}")
    for e in errors:
        print(f"エラー: {e}")
    print(f"{len(apps) if isinstance(apps, list) else 0} 件を検証: エラー {len(errors)} / 警告 {len(warnings)}")
    return 1 if errors else 0


def cmd_snippet(args):
    apps = load(args.file)
    errors, _ = validate(apps)
    if errors:
        print("検証エラーがあるため出力しません。先に validate を通してください。", file=sys.stderr)
        return 1
    value = json.dumps(apps, ensure_ascii=False, separators=(",", ":"))
    print("# Remote Config に設定する値（コンソールの「値」にそのまま貼る）")
    print(value)
    print()
    print("# firebase remoteconfig:get で取得したテンプレートの parameters に足す断片")
    print(json.dumps(
        {KEY: {"defaultValue": {"value": value}, "valueType": "JSON"}},
        ensure_ascii=False, indent=2,
    ))
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    v = sub.add_parser("validate", help="掲載リストを検証する")
    v.add_argument("file", nargs="?", type=Path, default=DEFAULT_FILE)
    v.add_argument("--check-urls", action="store_true", help="storeUrl / iconUrl が 200 を返すか確認する")
    v.set_defaults(func=cmd_validate)
    s = sub.add_parser("snippet", help="Remote Config 投入用の値を出力する")
    s.add_argument("file", nargs="?", type=Path, default=DEFAULT_FILE)
    s.set_defaults(func=cmd_snippet)
    args = parser.parse_args()
    sys.exit(args.func(args))


if __name__ == "__main__":
    main()
