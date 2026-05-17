# AGENTS.md

## Cursor Cloud specific instructions

### Overview

This is a desktop TodoApp built with Elixir, Phoenix LiveView, and the `elixir-desktop` library. It renders UI via a native wxWidgets webview backed by a local Phoenix server on `127.0.0.1:30979`. Data is stored in SQLite under the app config directory (`~/.config/todo/database.sq3` on Unix-like systems; see `TodoApp.config_dir/0` in `lib/todo_app.ex`).

### Running the app

```bash
. "$HOME/.asdf/asdf.sh" && cd /workspace && DISPLAY=:1 iex -S mix
```

The web UI is accessible at http://127.0.0.1:30979/ in a browser (useful for testing without needing the native window).

### Key commands

| Task | Command |
|------|---------|
| Install deps | `mix deps.get` |
| Compile | `mix compile` |
| Lint | `mix lint` |
| Tests | `mix test` |
| Asset build | `MIX_ENV=prod mix assets.deploy` |
| Run app (dev) | Same as [Running the app](#running-the-app): load asdf, set `DISPLAY`, then `iex -S mix` |

`MIX_ENV=prod mix assets.deploy` minifies and digests static assets for production releases. In development, esbuild and dart_sass run as Mix watchers when you start the app with `iex -S mix` (see `mix.exs` `asset_apps/1`).

### Non-obvious notes

- **No external services required.** This is a fully self-contained desktop app — no Postgres, Redis, Docker containers, or external APIs.
- **DBus/EGL warnings are expected** in headless/cloud environments. The app logs errors about DBus (desktop notifications) and EGL (GPU acceleration) but these do not affect functionality.
- **wxWidgets is required** for the desktop window. In headless environments, ensure `DISPLAY=:1` is set and an X server (Xvfb) is running.
- **Version management uses asdf** with `.tool-versions` pinning Erlang 28.4.3, Elixir 1.19.5, and Node.js 22.19.0. GitHub Actions (for example `.github/workflows/ci.yml`) still pins older Elixir/OTP for the default CI job; treat that file as the source of truth for CI, not `.tool-versions`.
- **The `mix lint` alias** runs `compile --warnings-as-errors`, `format --check-formatted`, and `credo --ignore design`. Run it with the default Mix environment (`dev`); Credo is only a dev/test dependency, so `MIX_ENV=prod mix lint` will fail on the Credo step.
- **Git LFS:** `*.a` files under `rel/android/` are tracked with Git LFS. After cloning, if those libraries look like small text files instead of archives, run `git lfs pull` before Android-related builds.
- **No test files exist** in the project currently — `mix test` compiles in the test environment but reports "There are no tests to run".
- **Assets** are built via esbuild (JS) and dart_sass (SCSS), both downloaded automatically by Mix on first run. Run `npm install` in `assets/` before `mix assets.deploy` if you have not yet (see the root `README.md`).
- **Android sample** lives under `rel/android/` (separate Gradle project). It uses a pinned Erlang/Elixir pair for the embedded runtime that can differ from the desktop `.tool-versions`; read `rel/android/README.md` before building an APK.
