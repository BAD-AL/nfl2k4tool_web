# Build and Run — NFL2K5Tool Web

## Development (hot reload)

```bash
webdev serve
```

Compiles Dart → JS incrementally, serves at `http://localhost:8080`, and hot-reloads on file save.

**Note:** `webdev serve` works best with Chrome. If it fails to launch a browser automatically, pass `--no-launch-in-chrome` and open the URL manually.

---

## Debugging in the browser

`webdev serve` emits source maps, so Chrome DevTools shows your original Dart source:

1. Open `http://localhost:8080` in Chrome
2. Open DevTools (`F12`) → **Sources** tab
3. Under `dart:///` or `packages/` you'll find your `.dart` files — set breakpoints directly there
4. `print()` output appears in the **Console** tab

For the best experience, install the **Dart Debug Extension** for Chrome — it enables proper variable inspection in Dart rather than the compiled JS.

---

## Unit tests (no browser needed)

```bash
dart test                               # run all tests
dart test test/text_parser_test.dart    # run one file
dart test --reporter expanded           # verbose output
dart test --watch                       # re-run on file save
```

Tests run on the Dart VM directly — fast, no browser required.

---

## Production build

```bash
webdev build
# Output goes to build/web/
```

Serve it locally to verify the production bundle:

```bash
cd build/web && python3 -m http.server 8080
# or: npx serve .
```

---

## Quick daily workflow

```bash
# Terminal 1 — dev server with hot reload
webdev serve

# Terminal 2 — unit tests on file save
dart test --watch
```

---

## Static analysis

```bash
dart analyze
```

Should exit with 0 errors. The one known `info` about `PlayerDataFile.dart` naming is from a generated file and can be ignored.

---

## Common issues

| Problem | Fix |
|---|---|
| `webdev: command not found` | `export PATH="$PATH":"$HOME/.pub-cache/bin"` |
| Blank page / JS error | Check browser console; check `webdev serve` terminal for compile errors |
| `dart pub get` fails on `nfl2k5tool_dart` | Needs internet to clone the git dependency |
| Hot reload didn't pick up a change | Hard refresh in browser (`Ctrl+Shift+R`); occasionally `webdev serve` needs a restart |
