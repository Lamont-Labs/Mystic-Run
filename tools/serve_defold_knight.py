#!/usr/bin/env python3
"""Serve ONLY the built experiment, never the repository or signing directories."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

PUBLIC = Path(__file__).resolve().parents[1] / "generated-artifacts/defold-knight/web"


class Handler(SimpleHTTPRequestHandler):
    extensions_map = {**SimpleHTTPRequestHandler.extensions_map, ".wasm": "application/wasm"}

    def end_headers(self):
        self.send_header("Cache-Control", "no-cache")
        self.send_header("X-Content-Type-Options", "nosniff")
        super().end_headers()

    def list_directory(self, path):
        self.send_error(403, "Directory listing disabled")
        return None


if __name__ == "__main__":
    if not (PUBLIC / "game/index.html").is_file():
        raise SystemExit("No compiled Defold web bundle. Build/download the verified experiment first.")
    server = ThreadingHTTPServer(("0.0.0.0", 5000), partial(Handler, directory=str(PUBLIC)))
    print("Serving compiled Defold Knight experiment on port 5000", flush=True)
    server.serve_forever()
