# Repository Guidelines

## Project Structure & Module Organization

OpenNSW tools are command-line tools that National Single Window deployments and their CI run. Libraries belong in `OpenNSW/core`, and application code stays in each deployment's repository.

- Each tool is its own Go module in its own directory: `<tool>/go.mod` declares `github.com/OpenNSW/tools/<tool>`.
- A tool's library code sits at the root of its directory, and each command in `<tool>/cmd/<command>/`.
- Each tool has a `README.md` describing its commands and configuration, and a row in the root `README.md`.
- A tool never imports another tool's module or a deployment's repository. It reuses core's modules (`database`, `configyaml`, ...) rather than copying them.

## Build, Test, and Development Commands

Use Go 1.26+, GNU make, gitleaks and golangci-lint v2.15.0.

- `make setup`: install golangci-lint and addlicense, and enable the git hooks in `.githooks`.
- `make check`: secret scan, license headers, lint, tidy check and build, in every tool module.
- `make test`: race-enabled tests in every tool module; `make test/<tool>` for one. Every target takes `/<tool>`.
- `make fmt` and `make license`: apply formatting and SPDX headers.

Keep each Makefile recipe line a single command that runs in both sh and Windows `cmd.exe`; CI runs the Makefile on Windows.

## Compatibility

Deployments in production pin these tools by version. Within a major version, keep working what deployments rely on: configuration fields and their defaults, commands and flags, output that scripts parse, and data a tool writes. A change that breaks any of these is marked `!` and released as a new major version.

## Coding Style & Naming Conventions

Follow `.editorconfig`: tabs for Go and Makefiles, two spaces for YAML and JSON. Format with gofmt and goimports through golangci-lint, and pass `.golangci.yml`. Every `.go` file starts with the two SPDX lines in `.github/license-header.tmpl`; add no other license headers.

Write comments about the code as it is now, not about how it got there. Don't mention earlier behaviour, where code used to live, or the issues and PRs that changed it, and don't use words like "now", "no longer" or "used to". That history belongs in the commit message and the PR. A reference to an open issue for planned work belongs in a `TODO(#NNN)` comment.

## Testing Guidelines

Place tests beside the code as `*_test.go`, using the standard `testing` package; they run with the race detector. Every change that adds or changes behaviour comes with tests in the same PR, covering its main path, its error paths and its edge cases. A change that can't be tested this way says why in the PR's Testing section.

## Commit & Pull Request Guidelines

Name branches `<type>/<issue>-<short-slug>`, using the issue the work closes; create the issue first if there is none. Use Conventional Commits with the tool as the scope, e.g. `fix(migrator): report the failing statement`; mark breaking changes with `!`. PR titles follow the same format: PRs are squash-merged, and the title becomes the commit title on `main`. Complete `.github/pull_request_template.md`.

## Releases

Each tool is released on its own: tag its commit on `main` `<tool>/vX.Y.Z` and publish a GitHub release with notes for the people who run the tool. Never tag a commit that is not on `main`. There is no CHANGELOG file; the release notes are the record.
