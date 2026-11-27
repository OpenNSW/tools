# Contributing

Contributions are welcome. This guide covers how the repository is laid out, how to add a tool, how to build and check your changes, and how they are reviewed and released.

## Layout

Each tool lives in its own directory and is its own Go module:

```text
<tool>/
├── go.mod            module github.com/OpenNSW/tools/<tool>
├── README.md         what the tool does, its commands and its configuration
├── *.go              the tool's library code
└── cmd/<command>/    each command the tool provides
```

Modules don't nest: each tool has one `go.mod`, and every `.go` file is in a tool module. Each module has its own dependencies and its own releases. A tool never imports another tool's module or a deployment's repository. Library code that several tools or applications need belongs in [OpenNSW/core](https://github.com/OpenNSW/core).

## Adding a tool

1. Open an issue that describes the tool and the deployments that need it.
2. Create `<tool>/` with its `go.mod` (module `github.com/OpenNSW/tools/<tool>`), its commands under `cmd/<command>`, tests and a README.
3. Add a row to the tools table in the [README](README.md).
4. If the tool needs code owners besides the repository's, add a `/<tool>/` line to [.github/CODEOWNERS](.github/CODEOWNERS) that lists them all.
5. Add `/<tool>` to the `gomod` directories in [.github/dependabot.yml](.github/dependabot.yml).

CI finds the new module by its `go.mod`, so the workflows need no change.

## Development

### Prerequisites

| Tool | Version | Install |
|---|---|---|
| Go | ≥ 1.26 | [go.dev/dl](https://go.dev/dl/) |
| GNU make | ≥ 3.81 | macOS and Linux: preinstalled or the system package manager. Windows: `winget install ezwinports.make`, `choco install make` or `scoop install make` |
| git | ≥ 2.9 | System package manager. On Windows, [Git for Windows](https://gitforwindows.org/), whose bash runs the git hooks |
| golangci-lint | v2.15.0 | `make tools` |
| addlicense | latest | `make tools` |
| editorconfig-checker | v3.11.1 | `make tools` |
| gitleaks | latest | `brew install gitleaks`, `choco install gitleaks`, `scoop install gitleaks` or a [release binary](https://github.com/gitleaks/gitleaks/releases) |

Ensure `$(go env GOPATH)/bin` is on your `PATH`. `make test` uses the race detector, which needs cgo and a C compiler; on Windows, install a MinGW-w64 gcc.

### One-time setup

```sh
make setup
```

This installs golangci-lint, addlicense and editorconfig-checker, and runs `git config core.hooksPath .githooks` to enable the git hooks.

### Make targets

The Go targets run in every tool module, and `editorconfig` and `secrets` check the whole repository. Add `/<tool>` to `fmt`, `lint`, `license`, `license-check`, `tidy`, `build`, `test` or `vuln` to run it in one module, e.g. `make test/migrator`. Run `make` on its own to list the targets.

| Target | What it does |
|---|---|
| `make check` | `secrets`, `editorconfig`, `license-check`, `lint`, `tidy` and `build`, as the pre-commit hook checks them |
| `make test` | `go test -race ./...` |
| `make editorconfig` | Checks every file against `.editorconfig` |
| `make fmt` | Formats code (gofmt + goimports via golangci-lint) |
| `make lint` | Runs golangci-lint |
| `make license` | Adds missing SPDX headers |
| `make license-check` | Checks every `.go` file has its SPDX header, as CI does |
| `make tidy` | Checks that `go.mod` and `go.sum` are tidy (`go mod tidy -diff`) |
| `make build` | Builds every package |
| `make vuln` | Scans dependencies with govulncheck |
| `make secrets` | Scans the working tree with gitleaks |

The Makefile runs the same in sh and in Windows `cmd.exe`: each recipe line is one command, or `cd <dir> && <command>`, with no shell loops, `if`, pipes or Unix-only tools. Keep it that way; CI runs it on Windows.

### EditorConfig

[.editorconfig](.editorconfig) sets each file type's line endings, final newline, trailing whitespace and indent style, and editors that support EditorConfig apply it as you type. `make editorconfig`, the pre-commit hook and CI check every file against it with editorconfig-checker, with two settings in [.editorconfig-checker.json](.editorconfig-checker.json):

- `.go` files are left out. gofmt formats them, and golangci-lint checks that, while their raw strings can hold text indented with spaces, such as YAML test fixtures.
- Indent widths aren't checked, only tabs against spaces, so Markdown lists, shell continuation lines and the license text keep their alignment.

### Git hooks

The pre-commit hook runs against staged changes: the EditorConfig check on every staged file, and the Go checks in each tool module with staged `.go`, `go.mod` or `go.sum` files, deleted ones included. It refuses a `.go` file outside every tool module, and a nested `go.mod`:

| Step | Tool | Behaviour |
|---|---|---|
| Secret scan | `gitleaks` | Hard gate: runs first, before any auto-fix |
| EditorConfig | `editorconfig-checker` | Blocks on a missing final newline, CRLF line endings, trailing whitespace or the wrong indent style |
| License headers | `addlicense` | Adds missing SPDX headers, re-stages |
| Format | `golangci-lint fmt` | Formats the staged `.go` files, re-stages |
| Lint | `golangci-lint run` | Blocks on errors |
| go mod tidy | `go mod tidy -diff` | Blocks when `go.mod` or `go.sum` is not tidy |
| Build | `go build ./...` | Blocks on compile errors |

If you `git add -p` only some hunks of a `.go` file, the auto-fixers re-stage the whole file. Stage whole files, or run `make fmt` first.

The pre-push hook runs `go test -race ./...` in every tool module.

Bypass the hooks with `git commit --no-verify` or `git push --no-verify`, or skip single pre-commit checks with `SKIP`, e.g. `SKIP=secrets,lint git commit`. The `SKIP` tokens are `secrets`, `editorconfig`, `license`, `format`, `lint`, `mod` and `build`.

### CI

| Job | What it checks |
|---|---|
| Find modules | Lists the tool modules, every top-level directory with a `go.mod`. Fails if a `.go` file is outside them or a `go.mod` is nested |
| Module (`<tool>`) | `go.mod` tidy, golangci-lint, license headers, tests with `-race` and gosec (informational), with the Go version in `go.mod`; then govulncheck with the latest stable Go |
| Make on Windows | The Makefile under `cmd.exe`, with the latest stable Go: `editorconfig`, `license-check`, `lint`, `tidy`, `build` and `test` |
| EditorConfig | Every file against `.editorconfig` |
| Secret Scan | gitleaks |
| CI | Passes only when every job above passed. Branch protection requires it |
| Conventional Commit Title | The PR title follows Conventional Commits |

CI enforces every gate on its own: `--no-verify` skips the local hooks, not CI.

## Compatibility

Deployments pin a tool's version and run it in production, so a release must not break them. Within a major version, keep these working:

- configuration fields and their defaults
- commands and flags
- output that scripts parse
- data the tool writes, such as tables or files

A change that breaks any of these is a breaking change: mark it with `!` and release it as a new major version.

## Commits and pull requests

- Name branches `<type>/<issue>-<short-slug>`, e.g. `fix/12-status-order`, using the issue the work closes. Open the issue first if there is none.
- Follow [Conventional Commits](https://www.conventionalcommits.org/), with the tool as the scope: `feat(migrator): add a redo command`. Put `!` before the colon for a breaking change: `feat(migrator)!: rename the dir setting`.
- Fill in the [pull request template](.github/pull_request_template.md).
- Pull requests are squash-merged, so the PR title becomes the commit title on `main`. CI checks that the title follows Conventional Commits.

| Type | When to use |
|---|---|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code change that is not a feature or fix |
| `docs` | Documentation only |
| `build` | Build system or dependency changes |
| `ci` | CI changes |
| `chore` | Maintenance (tooling, config, etc.) |
| `test` | Test-only changes |

## License headers

Every `.go` file starts with these two lines:

```go
// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Lanka Software Foundation
```

The year is the year the file was created and is never updated; git history records later edits. The template is [.github/license-header.tmpl](.github/license-header.tmpl).

## Releases

Each tool is released on its own:

1. Merge the changes to `main`.
2. Tag the merge commit `<tool>/vX.Y.Z` and push the tag, e.g. `git tag migrator/v1.2.0 <commit>` then `git push origin migrator/v1.2.0`. Only maintainers can create tags.
3. Publish a GitHub release for the tag. Write its notes for the people who run the tool: what changed, and anything they must do when they upgrade.

Versions follow [Semantic Versioning](https://semver.org/). Before `v1.0.0`, a minor version may include breaking changes, and its release notes say so.

## Reporting issues

Search the [existing issues](https://github.com/OpenNSW/tools/issues?q=is%3Aissue) first, then open one with the matching template: bug, feature, improvement or documentation. Name the tool and its version.

Report security vulnerabilities privately, as [SECURITY.md](SECURITY.md) describes, never in a public issue.
