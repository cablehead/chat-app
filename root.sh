#!/usr/bin/env bash

set -eu

BASE="$(dirname "$0")"
cd "$BASE"

meta_out() {
    jo "$@" >&4
    exec 4>&-
}

META="$(cat <&3)"
P="$(jq -r .path <<<"$META")"
METHOD="$(jq -r .method <<<"$META")"

if [[ "$METHOD" == "GET" && "$P" == "/" ]]; then
    meta_out headers="$(jo "content-type"="text/html")"
    jo request="$META" | tera --include-path ./scratch -i --template html/index.html --stdin
    exit
fi

if [[ "$METHOD" == "GET" && "$P" == "/messages" ]]; then
    meta_out headers="$(jo "content-type"="text/event-stream")"
    exec watchexec --postpone -w ./scratch/messages.html -- "cat scratch/messages.html | sed 's/^/data: /g'; echo"
fi

if [[ "$METHOD" == "POST" && "$P" == "/message" ]]; then
    meta_out headers="$(jo "content-type"="text/html")"
    jq -c --argjson meta "$META" '{
        stamp: $meta.stamp,
        ip: $meta.remote_ip,
        port: $meta.remote_port,
        message,
    }' >>"$STORE"/messages.json
    echo OK
    exit
fi

meta_out status=404 headers="$(jo "content-type"="text/html")"
echo "Not Found:" $METHOD $P
