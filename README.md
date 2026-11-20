# Whip Guy

A grumpy stick cowboy lives on top of your screen and cracks a whip at whatever you're working on. Mostly at Claude.

He sits in a transparent, always-on-top window, so clicks go straight through to the apps underneath. The only thing you can click is him.

## Run it

macOS only. You need Apple's command line tools (`xcode-select --install`).

```bash
sh build.sh
open WhipGuy.app
```

A 🤠 shows up in the menu bar. Quit from there.

## What he does

He walks around, stops, cracks the whip, and yells things like "Compile faster!" and "I've seen faster dial-up!". Every minute or so something random happens.

- **Drag** him anywhere.
- **Click** him to poke him.
- **Right-click** him (or click 🤠 in the menu bar) for the menu:
  - **MEGA ULTRA GIGA WHIP CRACK**: your screen shatters like glass.
  - **Call reinforcements**: five more whip guys show up for about 30 seconds.
  - **Request air strike**: bombers fly over and blow up your desktop.
  - **Duel against Claude**: high noon, 3-2-1, draw.
  - Toggles for random events, speech bubbles and sound, plus faster, slower, hide and quit.

## How it works

- `main.swift`: a borderless, click-through `NSPanel` covering the screen, with a transparent `WKWebView` inside. Every 25ms it checks whether the mouse is over the whip guy, and only then lets clicks land on the overlay. The right-click menu is a native `NSMenu`.
- `web/index.html`: the whole show, drawn on one canvas: walking, whipping, speech bubbles, glass cracks, planes, bombs, explosions and the duel.
- `web/img/`: three AI-generated frames (resting, winding up, cracking).
- `web/sfx/`: the sounds, made with a few lines of numpy. No recordings.

You can also open `web/index.html` in a browser to preview it. Keys 1–4 trigger the four actions.
