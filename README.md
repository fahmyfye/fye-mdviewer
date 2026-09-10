# fye-mdviewer

A local Markdown **viewer + editor** for macOS. Double-click a `.md` file and it
opens in your browser, rendered with GitHub styling. Flip the **Edit** toggle for
a split editor with live preview, and save straight back to the file.

- Rendered view by default — clean, centered, GitHub CSS
- **Table-of-contents sidebar** in view mode (h1–h3), scroll-synced; **Contents** button hides it
- **View / Edit** toggle; Edit is source-left / preview-right with live update
- In-place **Save** (button or `⌘S`), atomic write back to the original file
- **Print / PDF** via the browser print dialog
- **DOCX export** via pandoc (optional — button is a no-op with a hint if pandoc isn't installed)
- Syntax highlighting (highlight.js), **Mermaid** diagrams, **KaTeX** math
- Font switcher (System / Georgia / Charter / Helvetica / Mono)
- 100% offline — every library is vendored locally, no network calls at runtime
- The local server detaches on launch and shuts itself down ~12s after you close the tab

## How it works

`mdview <file.md>` starts a tiny Python (stdlib-only) HTTP server bound to
`127.0.0.1` on a random port, opens a browser tab, and serves:

| route            | purpose                                  |
|------------------|------------------------------------------|
| `GET /`          | the viewer/editor page (`app.html`)      |
| `GET /raw`         | current file contents                    |
| `PUT /raw`         | save new contents (atomic `os.replace`)  |
| `POST /export.docx`| render editor contents to `.docx` (pandoc) |
| `GET /assets/…`    | vendored JS/CSS/fonts                     |
| `GET /ping`        | keepalive from the tab                   |

A browser can't write to disk from a `file://` page, which is why this uses a
localhost server instead of a static HTML file.

## Requirements

- macOS
- `python3` — the system one at `/usr/bin/python3` works (stdlib only), or
  Homebrew's `python3`
- `curl` (for `install.sh` only)
- `pandoc` — **optional**, only for DOCX export: `brew install pandoc`

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

## Open `.md` files on double-click (Automator app)

macOS won't let you set a shell script as a file handler, so `mdview` is wrapped
in a tiny app that Finder can associate with `.md` files.

`install.sh` builds this for you at **`~/Applications/MarkdownViewer.app`** — an
AppleScript "droplet" that runs `mdview` on whatever files you open with it.

Then, in Finder:

1. right-click any `.md` file → **Get Info**
2. under **Open with**, choose **MarkdownViewer.app**
3. click **Change All…** and confirm

Double-clicking a `.md` now opens it in the viewer.

### Build the app by hand instead

If you'd rather not run `install.sh`, create it with Automator:

1. **Automator** → **New Document** → **Application**
2. add the **Run Shell Script** action
3. set **Pass input:** to **as arguments**
4. replace the body with:
   ```bash
   for f in "$@"; do
     "$HOME/bin/mdview" "$f"
   done
   ```
5. **File → Save…** → name it `MarkdownViewer`, save to `~/Applications`

Or from the command line (what `install.sh` runs):

```bash
osacompile -o ~/Applications/MarkdownViewer.app -e '
on open theFiles
  repeat with f in theFiles
    do shell script "$HOME/bin/mdview " & quoted form of (POSIX path of f)
  end repeat
end open'
```

### If double-click stops working after an update

macOS caches app registrations. Re-register the app:

```bash
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f ~/Applications/MarkdownViewer.app
```

## Use from the terminal

```bash
mdview README.md
```

By default `mdview` detaches and returns to the prompt immediately; the server
stops ~12s after you close the browser tab. To force it: `pkill -f 'mdview'`.

Pass `--foreground` (`-f`) to keep it in the foreground and stop it with
`Ctrl+C`:

```bash
mdview -f README.md
```

## Export to PDF / DOCX

- **PDF** — the **Print / PDF** button opens the browser print dialog; choose
  "Save as PDF". Print CSS strips the toolbar.
- **DOCX** — the **DOCX** button converts the current editor contents with
  `pandoc` (`-f gfm+tex_math_dollars -t docx`), so GitHub tables, task lists,
  and `$…$` math all carry over (math becomes native Word equations). Headings
  and code use Word's built-in styles, so the result is editable, not a screenshot.
  Requires `brew install pandoc`; without it the button shows a hint and does nothing.

## Updating the libraries

Re-run `./install.sh`. Version pins live at the top of that script.

## Layout

```
mdview        the launcher / local server (Python)
app.html      the viewer/editor UI (HTML + vanilla JS)
install.sh    installer + updater
```

The vendored libraries are **not** committed — `install.sh` fetches them.
