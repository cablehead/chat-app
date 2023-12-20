#!/usr/bin/env bash

set -eu

meta_out() {
    jo "$@" >&4
    exec 4>&-
}

META="$(cat <&3)"
P="$(jq -r .path <<< "$META")"
METHOD="$(jq -r .method <<< "$META")"

if [[ "$P" == "/" && "$METHOD" == "GET" ]]; then
    meta_out headers="$(jo "content-type"="text/html")"
    cat chat.html
    exit
fi

meta_out status=404 headers="$(jo "content-type"="text/html")"
echo "404 Not Found"
