# machin-web-demo-ssr — isomorphic **server-side rendering** in machin

A counter page rendered **server-side by a single native machin binary** — no
Node, no bundler, no JavaScript required to use it. The catch that makes it
interesting: the view logic lives in **`view.src`**, and *that same file* is
compiled into both halves of the app:

- the **native SSR server** (`server.src` + machweb) → fully-formed HTML per request;
- the **wasm client** (`client.src`, machin v0.50.0 `--target wasm`) → an in-browser SPA.

**One component model, two runtimes.** The server's HTML and the client's
re-render are byte-for-byte identical, because they call the same `view()`.

And it's **one binary**: the same native server **serves its own `app.wasm`**
(machin v0.51.0's binary HTTP bodies), so the page **hydrates** into an instant
SPA with no separate static host — first paint from the server, interactivity
from the wasm, all shipped by one executable.

![screenshot](screenshot.png)

## The shared component

`view.src` — compiled into the server *and* the wasm client, unchanged:

```go
func fib(n) (r) {
    if n < 2 { r = n } else { r = fib(n - 1) + fib(n - 2) }
}

func view(n) (s) {                                  // int in, HTML fragment out
    s = "<h1>machin · isomorphic counter</h1>"
    s = s + "<div class=big>" + str(n) + "</div>"
    s = s + "<p>n squared = <b>" + str(n * n) + "</b></p>"
    s = s + "<p>fib(n) = <b>" + str(fib(n)) + "</b></p>"
}
```

**Server** (`server.src`, composed with the vendored `machweb.src`): a machweb
handler reads `?n=` and returns `ok_html(page(n))`, where `page()` wraps the
shared `view()` in a document whose +/− controls are plain `<a href="/?n=…">`
links — navigation is a server round-trip, so it works with JavaScript off.

**Client** (`client.src`): `export func render(n) { set_html(view(n)) }` — the
same `view()`, exported from wasm, so a click re-renders in the browser with no
round-trip and produces the exact markup the server sent.

## Why this matters

- **SSR is native-fast and dependency-free.** Rendering a page is just calling a
  pure MFL function to build a string; the server is one static binary. No
  hydration runtime is needed at all for content pages.
- **The same code does SSR and SPA.** Write a component once in MFL; run it on the
  server for first paint and in wasm for interactivity. That's the full-stack
  payoff — one language, one component, both ends of the wire.
- **Machine-first.** The whole thing is canonical MFL an agent can author from
  `machin guide`; the build is `machin encode` + `machin build` — no `npm`, no
  Vite, no `node_modules`.

## Build & run

Needs `machin` (**v0.51.0+** — the server serves binary via `read_file_bytes` +
`ok_wasm`) and [`zig`](https://ziglang.org) (the C→wasm compiler).

```sh
./build.sh                       # builds app.wasm AND ./machin-web-demo-ssr
./machin-web-demo-ssr            # serves http://localhost:48090/  (HTML + its own /app.wasm)
# open http://localhost:48090/  ·  works with JS off (links navigate server-side),
#                                   and hydrates to an instant SPA when JS is on
```

Confirm both halves — the server and the wasm client emit the same HTML, and the
binary serves its own wasm:

```sh
curl -s 'http://localhost:48090/?n=7'              # ...<div class=big>7</div>...fib(n) = <b>13</b>...
curl -sI 'http://localhost:48090/app.wasm'         # Content-Type: application/wasm
# the served bytes are byte-identical to ./app.wasm, and client render(7) gives the same fragment
```

## How the single binary serves its wasm

machin v0.51.0 added **binary HTTP bodies** so a string body's NUL bytes can't
truncate a `.wasm`: `read_file_bytes(path) -> bytes` (NUL-safe read) and
`write_bytes(fd, bytes)` (exact write), with machweb builders `ok_bytes(ctype, b)`
/ `ok_wasm(b)`. The server's handler is just:

```go
if req.path == "/app.wasm" {
    return ok_wasm(read_file_bytes("app.wasm"))
}
return ok_html(page(qn(req.path)))
```

## What's next

The component still keeps no state of its own (the count lives in the URL / the
JS host). The next steps toward a real **reactive framework in MFL**: package-level
state so a component owns its state in machin, then signals + a patch-list runtime.
See the [web north star](https://github.com/javimosch/machin/blob/main/docs/NORTH-STAR-WEB.md).

## License

MIT
