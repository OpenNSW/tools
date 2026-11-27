# Contributing

Contributions are welcome. This guide covers how the repository is laid out, how to add a tool, and how changes are reviewed and released.

## Layout

Each tool lives in its own directory and is its own Go module:

```text
<tool>/
├── go.mod            module github.com/OpenNSW/tools/<tool>
├── README.md         what the tool does, its commands and its configuration
├── *.go              the tool's library code
└── cmd/<command>/    each command the tool provides
```

Each module has its own dependencies and its own releases. A tool never imports another tool's module or a deployment's repository. Library code that several tools or applications need belongs in [OpenNSW/core](https://github.com/OpenNSW/core).

## Adding a tool

1. Open an issue that describes the tool and the deployments that need it.
2. Create `<tool>/` with its `go.mod` (module `github.com/OpenNSW/tools/<tool>`), its commands under `cmd/<command>`, tests and a README.
3. Add a row to the tools table in the [README](README.md).
4. Add a `/<tool>/` line to [.github/CODEOWNERS](.github/CODEOWNERS).

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
