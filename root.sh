#!/usr/bin/env bash

set -eu

STORE="$1"

ROUTE_PATH=${2:-"/"}
# we export to make it available in the tera template
export ROUTE_PATH=${ROUTE_PATH%/}

BASE="$(dirname "$0")"
cd "$BASE"

mkdir -p "$STORE"

meta_out() {
    jo "$@" >&4
    exec 4>&-
}

META="$(cat <&3)"

METHOD="$(jq -r .method <<<"$META")"

P="$(jq -r .path <<<"$META")"
P=${P%/}

if [[ "$METHOD" == "GET" && "$P" == "${ROUTE_PATH}" ]]; then
    meta_out headers="$(jo "content-type"="text/html")"
    jo request="$META" | tera --env --env-key ENV -i --template html/index.html --stdin
    exit
fi

if [[ "$METHOD" == "GET" && "$P" == "${ROUTE_PATH}/messages" ]]; then
    meta_out headers="$(jo "content-type"="text/event-stream")"
    exec tail --sleep-interval 0.1 -F $STORE/messages.json |
        xcat -- bash -c "sed 's/^/data: /g'; echo"
fi

if [[ "$METHOD" == "GET" && "$P" == "${ROUTE_PATH}/screenshot.png" ]]; then
    meta_out headers="$(jo "content-type"="image/png")"
    exec cat docs/screenshot.png
fi

if [[ "$METHOD" == "POST" && "$P" == "${ROUTE_PATH}/message" ]]; then
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
