# OpenNSW Tools

Command-line tools that National Single Window deployments and their CI run. They are built on the libraries in [OpenNSW/core](https://github.com/OpenNSW/core).

## Tools

| Tool | Command | What it does |
|------|---------|--------------|

## What belongs here

- Standalone commands that any OpenNSW deployment can use.
- No code that is specific to one deployment: a tool takes everything about a deployment from its configuration.
- Libraries belong in [OpenNSW/core](https://github.com/OpenNSW/core), and application code stays in the application.

## Installing a tool

Each tool is its own Go module, `github.com/OpenNSW/tools/<tool>`, released with its own tags, `<tool>/vX.Y.Z`. Install a command with `go install`, giving the version without the tool prefix:

```sh
go install github.com/OpenNSW/tools/<tool>/cmd/<command>@vX.Y.Z
```

Pin a version in builds and container images, so every environment runs the same tool. Each tool's README describes its commands and configuration.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Report security problems privately, as [SECURITY.md](SECURITY.md) describes, not in public issues.

## License

Apache License 2.0. See [LICENSE](LICENSE).
