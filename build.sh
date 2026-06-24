#!/usr/bin/env bash
# Build machin-web-demo-ssr: a single native binary that serves both its SSR HTML
# and its own wasm SPA bundle, all from one shared view.src.
#
#   ./build.sh           # builds app.wasm (the client) AND machin-web-demo-ssr (the server)
#   ./build.sh server    # server only (skip the wasm client)
#
# Both halves are composed from the SAME view.src — one component model, two
# runtimes. No Node, no bundler. Needs machin v0.51.0+ (the server uses
# read_file_bytes + ok_wasm to serve binary) and zig (the C->wasm compiler).
set -euo pipefail
cd "$(dirname "$0")"
MACHIN="${MACHIN:-machin}"

if [ "${1:-}" != "server" ]; then
    # wasm client: shared view + client export -> app.wasm (the SPA half)
    "$MACHIN" encode view.src client.src > client.mfl
    "$MACHIN" build client.mfl --target wasm -o app.wasm
    echo "built ./app.wasm                (the SPA half, from view.src)"
fi

# native SSR server: machweb + shared view + server app -> one binary that also
# serves ./app.wasm (so the page hydrates from the same binary).
"$MACHIN" encode machweb.src view.src server.src > server.mfl
"$MACHIN" build server.mfl -o machin-web-demo-ssr
echo "built ./machin-web-demo-ssr     (run it, then open http://localhost:48090/)"
