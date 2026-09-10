# fye-mdviewer

A local Markdown **viewer + editor** for macOS. Double-click a `.md` file and it
opens in your browser, rendered with GitHub styling. Flip the **Edit** toggle for
a split editor with live preview, and save straight back to the file.

- Rendered view by default — clean, centered, GitHub CSS
- **View / Edit** toggle; Edit is source-left / preview-right with live update
- In-place **Save** (button or `⌘S`), atomic write back to the original file
- **Print / PDF** via the browser print dialog
- Syntax highlighting (highlight.js), **Mermaid** diagrams, **KaTeX** math
- Font switcher (System / Georgia / Charter / Helvetica / Mono)
- 100% offline — every library is vendored locally, no network calls at runtime
- The local server shuts itself down ~12s after you close the tab

## How it works

`mdview <file.md>` starts a tiny Python (stdlib-only) HTTP server bound to
`127.0.0.1` on a random port, opens a browser tab, and serves:

| route            | purpose                                  |
|------------------|------------------------------------------|
| `GET /`          | the viewer/editor page (`app.html`)      |
| `GET /raw`       | current file contents                    |
| `PUT /raw`       | save new contents (atomic `os.replace`)  |
| `GET /assets/…`  | vendored JS/CSS/fonts                     |
| `GET /ping`      | keepalive from the tab                    |

A browser can't write to disk from a `file://` page, which is why this uses a
localhost server instead of a static HTML file.

## Requirements

- macOS
- `python3` — the system one at `/usr/bin/python3` works (stdlib only), or
  Homebrew's `python3`
- `curl` (for `install.sh` only)

## Install

```bash
git clone git@github.com:fahmyfye/fye-mdviewer.git
cd fye-mdviewer
./install.sh
```

`install.sh` will:

1. copy `mdview` to `~/bin/mdview` and `app.html` to `~/.local/share/mdview/`
2. download the vendored libraries (marked, highlight.js, Mermaid, KaTeX + fonts,
   GitHub Markdown CSS) into `~/.local/share/mdview/`
3. build `~/Applications/MarkdownViewer.app` — an AppleScript app that runs
   `mdview` on the files you open with it

If `~/bin` isn't on your `PATH`, add it:

```bash
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
```

## Set `.md` files to open with it

Finder → right-click any `.md` → **Get Info** → **Open with** →
**MarkdownViewer.app** → **Change All…**

Now double-clicking a `.md` opens the viewer.

## Use from the terminal

```bash
mdview README.md
```

Press `Ctrl+C` in that terminal to stop the server immediately (otherwise it
exits on its own shortly after the tab closes).

## Updating the libraries

Re-run `./install.sh`. Version pins live at the top of that script.

## Layout

```
mdview        the launcher / local server (Python)
app.html      the viewer/editor UI (HTML + vanilla JS)
install.sh    installer + updater
```

The vendored libraries are **not** committed — `install.sh` fetches them.
