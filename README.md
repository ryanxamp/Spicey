# Spicey

A dead-simple, native Apple Silicon app for opening Proxmox VE's `.vv`
(virt-viewer) console files over SPICE. No settings to fight with, no
broken decade-old client — just double-click the file Proxmox gives you
and the console opens.

Built because [the official spice-space macOS client](https://www.spice-space.org/osx-client.html)
has been broken for years.

## Install

```bash
brew tap ryanxamp/spicey
brew install --cask spicey
```

Or grab `Spicey.dmg` from [Releases](https://github.com/ryanxamp/Spicey/releases).

> The app is ad-hoc signed, not notarized. On first launch, right-click
> the app in Applications and choose **Open** (or approve it in
> System Settings → Privacy & Security) to get past Gatekeeper.

## Use

1. In the Proxmox web UI, open a VM/CT console and download the `.vv` file.
2. Double-click it. Spicey opens the SPICE session.

Settings (⌘,) has exactly two toggles: open in fullscreen, and scale
the display to the window.

## How it works

Proxmox's `.vv` files aren't plain SPICE — they route the connection
through Proxmox's own HTTP proxy with a synthetic hostname and a
pinned TLS certificate, and the ticket embedded in the file is
single-use. Spicey parses that and hands the real protocol work to
[spice-gtk](https://www.spice-space.org/), the same maintained engine
behind tools like UTM.

- `Sources/Spicey/` — the SwiftUI shell: file association, settings,
  drag-and-drop, native error alerts.
- `helper/spicey-display.c` — a small C helper linking against
  spice-gtk that does the actual proxy tunnel, TLS pinning, and
  renders the VM display.

## Build from source

Requires [Homebrew](https://brew.sh) and Xcode Command Line Tools.

```bash
brew install spice-gtk pkg-config
./scripts/build-app.sh   # -> Spicey.app
./scripts/build-dmg.sh   # -> Spicey.dmg
```
