#!/usr/bin/env bash

set -ex

BRANCH=$(git rev-parse --abbrev-ref HEAD)
DIST_VERSION=$(git describe --abbrev=0 --tags || echo "v0.0.0")  # Установить версию по умолчанию, если нет тегов

DIR=$(dirname "$0")

# Если ветка не HEAD и не является тегом, получить версию через скрипт
if [[ $BRANCH != HEAD && ! $BRANCH =~ heads/v.+ ]]
then
    DIST_VERSION=$("$DIR"/get-version-from-git.sh)
fi

DIST_VERSION=$("$DIR"/normalize-version.sh "$DIST_VERSION")
VERSION=$DIST_VERSION yarn build
echo "$DIST_VERSION" > /src/webapp/version
