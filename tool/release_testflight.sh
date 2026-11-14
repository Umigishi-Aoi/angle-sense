#!/bin/bash
# TestFlight へ上げる（ビルド番号を 1 上げる → 署名つき ipa を作る → App Store Connect へアップロード）。
#
# 使い方: bash tool/release_testflight.sh
#
# 前提:
#   - API キー ~/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8 が置いてある（権限 600）
#   - TestFlight の内部テストグループで「自動配布」がオン（上げたビルドが自動で届く）
# キーID・Issuer ID は tool/asc.env に置く（秘密は .p8 の中身だけ）。
set -euo pipefail

cd "$(dirname "$0")/.."

# キー ID と Issuer ID は tool/asc.env（Git 管理外）か環境変数で渡す。
if [[ -f tool/asc.env ]]; then
  # shellcheck source=/dev/null
  source tool/asc.env
fi
: "${ASC_KEY_ID:?ASC_KEY_ID を tool/asc.env か環境変数で設定する}"
: "${ASC_ISSUER_ID:?ASC_ISSUER_ID を tool/asc.env か環境変数で設定する}"

key="$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8"
if [[ ! -f "$key" ]]; then
  echo "エラー: API キーが見つからない: $key" >&2
  exit 1
fi

# pubspec の version: X.Y.Z+N の N を 1 上げる（同じビルド番号は App Store Connect に弾かれる）。
line=$(grep -E '^version: ' pubspec.yaml)
name=${line#version: }
name=${name%%+*}
build=${line##*+}
next=$((build + 1))
sed -i '' -E "s/^version: .*/version: ${name}+${next}/" pubspec.yaml
echo "バージョン: ${name} (${build} → ${next})"

rm -rf build/ios/ipa
if ! fvm flutter build ipa --release; then
  # 失敗したらビルド番号を戻す（次回また同じ番号から試せるように）。
  sed -i '' -E "s/^version: .*/version: ${name}+${build}/" pubspec.yaml
  echo "エラー: ビルド失敗。ビルド番号を ${build} に戻した" >&2
  exit 1
fi

ipa=$(ls build/ios/ipa/*.ipa)
xcrun altool --upload-package "$ipa" --api-key "$ASC_KEY_ID" --api-issuer "$ASC_ISSUER_ID"
echo "完了: ${name} (${next}) をアップロードした。TestFlight に出るまで 10〜30 分。"
