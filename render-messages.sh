#!/usr/bin/env bash

set -eu

BASE="$(dirname "$0")"
cd "$BASE"

STORE="$1"
tail -n20 "$STORE"/messages.json | jq -s 'reverse | {messages: .}' | tera -t ./html/messages.html --stdin
