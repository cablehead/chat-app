#!/usr/bin/env bash

set -eu

BASE="$(dirname "$0")"
cd "$BASE"

STORE="$1"
cat "$STORE"/messages.json | jq -s '{messages: .}' | tera -t ./html/messages.html --stdin
