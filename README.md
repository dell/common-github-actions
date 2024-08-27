<!--
Copyright (c) 2020 Dell Inc., or its subsidiaries. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0
-->

# Dell GitHub Actions

[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v2.0%20adopted-ff69b4.svg)](./docs/CODE_OF_CONDUCT.md)
[![License](https://img.shields.io/github/license/dell/common-github-actions)](LICENSE)
[![Latest Release](https://img.shields.io/github/v/release/dell/common-github-actions?label=latest&style=flat-square)](https://github.com/dell/common-github-actions/releases)

This repository contains a set of reusable actions and workflows, designed to be run with GitHub Actions.

## Table of Contents

- [Code of Conduct](./docs/CODE_OF_CONDUCT.md)
- Guides
  - [Committer Guide](./docs/COMMITTER_GUIDE.md)
  - [Contributing Guide](./docs/CONTRIBUTING.md)
  - [Maintainer Guide](./docs/MAINTAINER_GUIDE.md)
- [Maintainers](./docs/MAINTAINERS.md)
- [Support](#support)
- [Security](./docs/SECURITY.md)
- [About](#About)

## Implemented Actions

### code-sanitizer

[GitHub Action to scan the source for non-inclusive words and language.](https://github.com/dell/common-github-actions/blob/main/code-sanitizer/README.md)

### go-code-formatter-linter-vetter

[GitHub Action to run go formatter, linter, and vetter scans against the GO source files](https://github.com/dell/common-github-actions/blob/main/go-code-formatter-linter-vetter/README.md)

### go-code-tester

[GitHub Action to run code coverage against GO source](https://github.com/dell/common-github-actions/blob/main/go-code-tester/README.md)

### malware-scanner

[GitHub Action to run ClamScan AntiVirus Scan against source](https://github.com/dell/common-github-actions/blob/main/malware-scanner/README.md)

## Implemented Workflows

In addition to the actions mentioned above, the repository contains workflows that are used by various projects.

### go-static-analysis

This workflow runs static analysis checks against repositories that utilize Golang as the primary development language. The jobs that are run include:
* golanci-lint with gofumpt (stricter version of gofmt), gosec, govet, and revive (replacement for golint). The configuration file for this job can be found at [.github/configs/golangci-lint/golangci.yaml](.github/configs/golangci-lint/golangci.yaml)
* malware_security_scan, which is the malware-scanner mentioned above
* yaml_lint_scan which validates yaml files. The yamllint config file for this job is at [.github/configs/yamllint/yamllint.yaml](.github/configs/yamllint/yamllint.yaml)

The workflow does not accept any parameters and can be used from any repo by creating a workflow that resembles the following

```
name: Workflow
on:
  push:
    branches: [main]
  pull_request:
    branches: ["**"]

jobs:

  # golang static analysis checks
  go-static-analysis:
    uses: dell/common-github-actions/.github/workflows/go-static-analysis.yaml@main
    name: Golang Validation
```

## Support

Don’t hesitate to ask! Contact the team and community on [our support](./docs/SUPPORT.md).
Open an issue if you found a bug on [Github Issues](https://github.com/dell/common-github-actions/issues).

## Versioning

This project is adhering to [Semantic Versioning](https://semver.org/).

## About

The GitHub Actions implemented in this repo are 100% open source and community-driven.
All components are available
under [Apache 2 License](https://www.apache.org/licenses/LICENSE-2.0.html) on GitHub.
