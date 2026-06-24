#!/usr/bin/env bash
# Build machin-demo-ssr.
#
#   ./build.sh           # the native SSR server  -> ./machin-demo-ssr
#   ./build.sh client    # also the wasm client   -> ./app.wasm  (needs zig)
#
# Both halves are composed from the SAME view.src — one component model, two
# runtimes. The server is a single static binary (machweb, vendored); no Node,
# no bundler. The wasm client uses machin v0.50.0+ `--target wasm`.
set -euo pipefail
cd "$(dirname "$0")"
MACHIN="${MACHIN:-machin}"

# native SSR server: machweb + shared view + server app -> one binary
"$MACHIN" encode machweb.src view.src server.src > server.mfl
"$MACHIN" build server.mfl -o machin-demo-ssr
echo "built ./machin-demo-ssr   (run it, then open http://localhost:48090/)"

if [ "${1:-}" = "client" ]; then
    # wasm client: shared view + client export -> app.wasm (same view() as above)
    "$MACHIN" encode view.src client.src > client.mfl
    "$MACHIN" build client.mfl --target wasm -o app.wasm
    echo "built ./app.wasm          (the SPA half, from the same view.src)"
fi
