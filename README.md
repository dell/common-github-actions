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
- [About](#about)

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

- golanci-lint with gofumpt (stricter version of gofmt), gosec, govet, and revive (replacement for golint). The configuration file for this job can be found at [.github/configs/golangci-lint/golangci.yaml](.github/configs/golangci-lint/golangci.yaml)
- yaml_lint_scan which validates yaml files. The yamllint config file for this job is at [.github/configs/yamllint/yamllint.yaml](.github/configs/yamllint/yamllint.yaml)

The workflow does not accept any parameters and can be used from any repo by creating a workflow that resembles the following

```yaml
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

### csm-release-libs

This workflow automates the release process for all the Go Client Libraries:

The workflow accepts version as an input and releases that particular version. Below is the example usage in gobrick repository. If no version is specified then it will automatically bump up the major version.

```yaml
name: Release Gobrick
# Invocable as a reusable workflow
# Can be manually triggered
on:
  workflow_call:
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to release (major, minor, patch)'
        required: true
        default: 'none'
jobs:
  csm-release:
    uses: dell/common-github-actions/.github/workflows/csm-release-libs.yaml@main
    name: Release Go Client Libraries
```

### go-version-workflow

This workflow updates to the latest go version in repositories that utilize Golang as the primary development language. The workflow is triggered by https://github.com/dell/common-github-actions/actions/workflows/trigger-go-workflow.yaml or can be triggered manually.

The workflow does not accept any parameters and can be used from any repository by creating a workflow that resembles the following
Note: Workflows that call reusable workflows in the same organization or enterprise can use the inherit keyword to implicitly pass the secrets. See: https://docs.github.com/en/actions/sharing-automations/reusing-workflows#passing-inputs-and-secrets-to-a-reusable-workflow.

```yaml
name: Go Version Update

on:
  workflow_dispatch:
  repository_dispatch:
    types: [go-update-workflow]

jobs:
  go-version-update:
    uses: dell/common-github-actions/.github/workflows/go-version-workflow.yaml@main
    name: Go Version Update
    secrets: inherit
```

### go-common

This workflow runs multiple checks against repositories that utilize Golang as the primary development language. Currently, this workflow will run unit tests, check package coverage, gosec, go formatter and vetter, malware scan, and auto-merge Dependabot PRs only.

```
name: Common Workflows
on:  # yamllint disable-line rule:truthy
  push:
    branches: [main]
  pull_request:
    branches: ["**"]

jobs:

  common:
    name: Quality Checks
    uses: dell/common-github-actions/.github/workflows/go-common.yml@main
```

### csm-release-driver-module

This workflow automates the release of CSM drivers and modules repositories. The workflow accepts two parameters as version and image, and can be used from any repo by creating a workflow that resembles the following.
The manual workflow is recommended to be used for out of band releases such as patch releases or when the increment is a major version change.

For manual trigger from driver and module repositories, here is the example for the csi-powerscale repo:

```yaml
name: Release CSIPowerScale
on:
  workflow_call:
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to release (major, minor, patch) Ex: 1.0.0'
        required: true
      image:
        description: 'Image name to release Ex: csi-isilon'
        required: true

jobs:
  release:
    uses: dell/common-github-actions/.github/workflows/csm-release-driver-module.yaml@main
    name: Release CSM Drivers and Modules
    with:
      version: ${{ github.event.inputs.version }}
      image: ${{ github.event.inputs.image }}
    secrets: inherit
```

For Auto release of the driver and module repositories, here is the example for the csi-powerscale repo:

```yaml
name: Auto Release CSIPowerScale
on:
  workflow_dispatch:
  repository_dispatch:
    types: [auto-release-workflow]

jobs:
  calculate-version:
    runs-on: ubuntu-latest
    outputs:
      new-version: ${{ steps.set-version.outputs.version }}
    steps:
      - name: Check out repository
        uses: actions/checkout@v3
        with:
          fetch-depth: 0 # Fetch the full history including tags

      - name: Get latest release version
        id: get-latest-version
        run: |
          latest_version=$(git describe --tags $(git rev-list --tags --max-count=1))
          echo "latest_version=${latest_version}" >> $GITHUB_ENV

      - name: Increment minor version and remove 'v' prefix
        id: set-version
        run: |
          version=${{ env.latest_version }}
          clean_version=${version#v}

          # Parse version parts
          major=$(echo $clean_version | cut -d'.' -f1)
          minor=$(echo $clean_version | cut -d'.' -f2)
          patch=$(echo $clean_version | cut -d'.' -f3)
          new_minor=$((minor + 1))
          new_version="${major}.${new_minor}.0"

          echo "New version: $new_version"
          echo "::set-output name=version::$new_version"

  csm-release:
    needs: calculate-version
    uses: dell/common-github-actions/.github/workflows/csm-release-driver-module.yaml@main
    with:
      version: ${{ inputs.version || needs.calculate-version.outputs.new-version }}
      image: "csi-isilon"  # Please provide the appropriate image name
    secrets: inherit
```

## update-libraries-to-commits
This workflow updates Dell libraries to their **latest commits** in repositories that utilize Golang as the primary development language. The workflow is triggered automatically, but can be triggered manually as well.
The workflow does not accept any parameters and can be used from any repository by creating a workflow that resembles the following:
```
name: Dell Libraries Commit Update
on:  # yamllint disable-line rule:truthy
  workflow_dispatch:

jobs:
  library-update:
    uses: dell/common-github-actions/.github/workflows/update-libraries-to-commits.yml@main
    name: Dell Libraries Update
```

## csm-operator version update to latest
This workflow updates csm-operator repository with latest version of the operator for the given release. 
It also updates the CSM program version wherever it is used in csm-operator repository.

This workflow accepts total three parameters as input to the workflow (csm version, latest operator version, existing operator version).

It expects a script to be present in the csm-operator repository ".github/scripts/operator-version-update.sh".

Workflow needs to be triggered manually from csm-operator repository. Below is the example usage in csm-operator repository.
```
name: Update CSM Operator version
# reusable workflow
on:  # yamllint disable-line rule:truthy
  workflow_call:
  workflow_dispatch:
    inputs:
      csm-version:
        description: 'CSM program version, ex: v1.12.0, v1.13.0, ...'
        required: true
      latest-version:
        description: 'Latest operator version, ex: v1.7.0, v1.8.0, ...'
        required: true
      existing-version:
        description: 'Existing operator version, ex: v1.6.0, 1.7.0, ...'
        required: true
jobs:
  version-update:
    uses: dell/common-github-actions/.github/workflows/operator-version-update.yaml@main
    name: Operator version update
    with:
      latest-version: ${{ inputs.latest-version }}
      existing-version: ${{ inputs.existing-version }}
      csm-version: ${{ inputs.csm-version }}
    secrets: inherit
```

## Update all sidecar versions to latest available, in csm-operator
This workflow updates csm-operator repository with latest versions of the sidecars.

This workflow accepts total eight parameters as input to the workflow -
(attacher,provisioner,snapshotter,resizer,registrar,external_heath_monitor,metadata_retriever,sdcmonitor). 
Below is the example usage in csm-operator repository.

It expects a script to be present in the csm-operator repository ".github/scripts/sidecar-version-update.sh".

Workflow needs to be triggered manually from csm-operator repository. Below is the example usage in csm-operator repository.
```
name: Update sidecar version
# reusable workflow
on:  # yamllint disable-line rule:truthy
  workflow_call:
  workflow_dispatch:
    inputs:
      attacher:
        description: 'csi-attacher version, ex: v4.8.0'
        required: true
      provisioner:
        description: 'csi-provisioner version, ex: v5.1.0'
        required: true
      snapshotter:
        description: 'csi-snapshotter version, ex: v8.2.0'
        required: true
      resizer:
        description: 'csi-resizer version, ex: v1.13.1'
        required: true
      registrar:
        description: 'csi-node-driver-registrar version, ex: v2.13.0'
        required: true
      health-monitor:
        description: 'csi-external-health-monitor-controller version, ex: v0.14.0'
        required: true
      metadata-retriever:
        description: 'csi-metadata-retriever version, ex: v1.8.0'
        required: true
      sdcmonitor:
        description: 'sdc version, ex: 4.5.1'
        required: true
jobs:
  version-update:
    uses: dell/common-github-actions/.github/workflows/sidecar-version-update.yaml@main
    name: Sidecar version update
    with:
      attacher: ${{ inputs.attacher }}
      snapshotter: ${{ inputs.snapshotter }}
      provisioner: ${{ inputs.provisioner }}
      registrar: ${{ inputs.registrar }}
      health-monitor: ${{ inputs.health-monitor }}
      metadata-retriever: ${{ inputs.metadata-retriever }}
      resizer: ${{ inputs.resizer }}
      sdcmonitor: ${{ inputs.sdcmonitor }}
    secrets: inherit

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
