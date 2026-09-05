# SeaApp CLI

Create visual workflows, digital characters, and custom AI websites from your terminal or coding agent. Cloud execution, identity, wallet and publishing remain on SeaApp.

The `seaapp` executable is compiled with Bun and includes its runtime, browser SDK and skill. End users do not need Bun or Node.js for built-in commands. A custom project's own build command may require its chosen toolchain.

## Install

Install or upgrade on macOS/Linux:

```sh
curl -fsSL https://raw.githubusercontent.com/SeaAPPAI/seaapp-cli/main/install.sh -o /tmp/seaapp-install.sh
sh /tmp/seaapp-install.sh
```

The installer checks SHA-256 and writes to `~/.local/bin`. Set `SEAAPP_INSTALL_DIR` or `SEAAPP_VERSION=v0.1.0` to override the destination or pin a release. On Windows, download `install.ps1` from the distribution repository and run it in PowerShell; it installs to `%LOCALAPPDATA%\SeaApp\bin`. Add the install directory to PATH. Rerun the installer to upgrade, then rerun `seaapp skills install --target codex` to update the managed skill.

Alternatively, download the archive for your operating system from [SeaApp CLI releases](https://github.com/SeaAPPAI/seaapp-cli/releases), verify it against `SHA256SUMS`, extract it and place `seaapp` (`seaapp.exe` on Windows) in your PATH.

```sh
seaapp --version
seaapp skills install --target codex
seaapp auth login
# Open the returned SeaApp authorization URL, then:
seaapp auth login --complete
seaapp doctor --json
```

In Codex, invoke `$seaapp` or ask it to create an app on SeaApp. The installed skill routes to visual, character, website and publishing guidance.

## Create

```sh
seaapp init my-visual-app --template flow/image
cd my-visual-app
seaapp catalog nodes --json
seaapp catalog models --capability image --json
# Edit flow/workflow.json and flow/face.json.
seaapp validate --json
seaapp push --json
seaapp flow run --json
seaapp flow wait --timeout 60 --json
seaapp flow outputs --download ./outputs --json
seaapp preview --json
seaapp publish --dry-run --json
seaapp publish --json
```

Other templates: `flow/video`, `flow/audio`, `flow/text`, `character`, `web`. Character cards are CCv3 JSON. Custom website files live in `web/`; a framework project can set `web.build` to an argv array and `web.dir` to its static output directory. The browser runtime is packaged from the canonical SeaApp SDK.

`seaapp pull <project-id> --kind flow --dir <empty-directory>` checks out an existing cloud project. `diff`, `push`, and `pull` preserve local edits and detect conflicting cloud changes. `.seaapp/` stores synchronization baselines and resumable operation IDs, and is ignored by Git.

## Automation contract

- `--json` emits one JSON result on stdout. Build logs/progress use stderr.
- Success: `{ "ok": true, "data": ... }`. Errors: `{ "ok": false, "error": { "code", "message", "details", "retryable" } }`.
- Exit codes: `0` success, `1` failure, `2` usage, `3` authentication, `4` conflict, `5` terminal failed/aborted Run.
- A timed-out wait leaves the cloud Run active. Use its ID to continue waiting.
- Repeating the same Flow revision and input reuses its saved operation. Use `--new` only for an intentional new generation.
- Publishing saves the intent before submission. Retry with unchanged contents to recover a lost response without creating a duplicate App/release.
- Credentials are stored outside projects in the user configuration directory with restrictive file permissions. `SEAAPP_CONFIG_DIR` overrides that directory; `SEAAPP_TOKEN` supports externally managed credentials. Never include credentials in project files or bundles.
- `--origin` / `SEAAPP_ORIGIN` selects an explicit gateway; HTTPS is required except loopback test servers. Project bindings prevent accidentally sending a project to another gateway.

Flow publishing creates a public listed AI APP. Character and website `listing.listed` controls store listing; their preview links are unlisted, not private. App delivery and store listing are reported separately. Use real cover images and complete listing metadata before listing.

## Development

Source lives in the private SeaApp SDK workspace at `cli/`. SDK imports refer to that workspace's single source tree. Binary builds embed the needed runtime; no separate SDK npm publication is required.

```sh
cd cli
bun install --frozen-lockfile
bun run check
bun run build
bun scripts/smoke.ts
```

`.github/workflows/cli.yml` builds and runs the binary on macOS arm64/x64, Linux arm64/x64 and Windows x64. Tests include operation recovery, synchronization conflicts, deterministic archive extraction and embedded-skill installation. Real provider calls and browser checks are tracked separately from automated tests.

### Custom Flow websites

After synchronizing a Flow project, use `seaapp site pull` to download its template to `site/`. Edit its HTML, CSS, JS and assets locally, then `seaapp site push`, `seaapp preview`, and `seaapp publish`. The site uses the Flow host bridge for cloud generation; it never receives a long-lived credential. Site writes check the cloud generation, and published revisions freeze every file. Run `seaapp site diff --json` before merging concurrent edits.
