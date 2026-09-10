#!/bin/bash
# install.sh — set up mdview on this machine.
#
#   ./install.sh
#
# Installs:
#   ~/bin/mdview                     the launcher (a small local web server)
#   ~/.local/share/mdview/app.html   the viewer/editor UI
#   ~/.local/share/mdview/...        vendored JS/CSS/fonts (downloaded here)
#
# Also builds ~/Applications/MarkdownViewer.app so you can set .md files to
# "Open with" it in Finder. Re-run any time to update the vendored libraries.

set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/bin"
SHARE_DIR="$HOME/.local/share/mdview"
APP_DIR="$HOME/Applications/MarkdownViewer.app"

# Pinned versions
MARKED=12.0.2
GHMD_CSS=5.5.1
HLJS=11.9.0
MERMAID=10.9.3
KATEX=0.16.11

CDN=https://cdn.jsdelivr.net

say() { printf '  %s\n' "$*"; }

command -v python3 >/dev/null || { echo "python3 is required (brew install python)"; exit 1; }
command -v curl    >/dev/null || { echo "curl is required"; exit 1; }

echo "Installing mdview…"
mkdir -p "$BIN_DIR" "$SHARE_DIR/katex/fonts"

# --- scripts -----------------------------------------------------------------
install -m 0755 "$SRC_DIR/mdview" "$BIN_DIR/mdview"
install -m 0644 "$SRC_DIR/app.html" "$SHARE_DIR/app.html"
say "launcher  -> $BIN_DIR/mdview"
say "ui        -> $SHARE_DIR/app.html"

# --- vendored libraries ----------------------------------------------------
dl() { # dl <url> <dest>
  curl -fsSL -o "$2" "$1" || { echo "failed: $1"; exit 1; }
}

echo "Downloading libraries (offline assets)…"
dl "$CDN/npm/marked@$MARKED/marked.min.js"                         "$SHARE_DIR/marked.min.js"
dl "$CDN/npm/github-markdown-css@$GHMD_CSS/github-markdown.css"     "$SHARE_DIR/github-markdown.css"
dl "$CDN/gh/highlightjs/cdn-release@$HLJS/build/highlight.min.js"   "$SHARE_DIR/highlight.min.js"
dl "$CDN/gh/highlightjs/cdn-release@$HLJS/build/styles/github.min.css"      "$SHARE_DIR/hljs-github.css"
dl "$CDN/gh/highlightjs/cdn-release@$HLJS/build/styles/github-dark.min.css" "$SHARE_DIR/hljs-github-dark.css"
dl "$CDN/npm/mermaid@$MERMAID/dist/mermaid.min.js"                 "$SHARE_DIR/mermaid.min.js"
dl "$CDN/npm/katex@$KATEX/dist/katex.min.css"                      "$SHARE_DIR/katex/katex.min.css"
dl "$CDN/npm/katex@$KATEX/dist/katex.min.js"                       "$SHARE_DIR/katex/katex.min.js"
dl "$CDN/npm/katex@$KATEX/dist/contrib/auto-render.min.js"         "$SHARE_DIR/katex/auto-render.min.js"

say "fetching KaTeX fonts…"
for font in $(grep -oE 'KaTeX_[A-Za-z0-9-]+\.woff2' "$SHARE_DIR/katex/katex.min.css" | sort -u); do
  dl "$CDN/npm/katex@$KATEX/dist/fonts/$font" "$SHARE_DIR/katex/fonts/$font"
done

# --- Finder app ------------------------------------------------------------
echo "Building $APP_DIR…"
mkdir -p "$HOME/Applications"
rm -rf "$APP_DIR"
osacompile -o "$APP_DIR" -e '
on open theFiles
  repeat with f in theFiles
    do shell script "$HOME/bin/mdview " & quoted form of (POSIX path of f)
  end repeat
end open
on run
  display dialog "Open a .md file with this app from Finder." buttons {"OK"} default button 1
end run
' >/dev/null
say "app       -> $APP_DIR"

# --- optional: pandoc for DOCX export ------------------------------------
if ! command -v pandoc >/dev/null; then
  echo
  if [ -t 0 ] && command -v brew >/dev/null; then
    printf "DOCX export needs pandoc (~280 MB). Install it now? [y/N] "
    read -r reply
    case "$reply" in
      [yY]*) brew install pandoc ;;
      *) echo "Skipped. Run 'brew install pandoc' later to enable DOCX export." ;;
    esac
  else
    echo "Optional: DOCX export needs pandoc.  brew install pandoc"
  fi
fi

echo
echo "Done."
case ":$PATH:" in
  *":$BIN_DIR:"*) : ;;
  *) echo "Add ~/bin to your PATH:  echo 'export PATH=\"\$HOME/bin:\$PATH\"' >> ~/.zshrc" ;;
esac
echo "To open .md files on double-click: Finder > right-click a .md > Get Info >"
echo "Open with > MarkdownViewer.app > Change All."
