# Go Code Tester GitHub Action

This GitHub Action can be used to run Go unit tests and check that code coverage per package meets a threshold.

To enable this Action, you can create a .yml file under your repo's .github/workflows directory.
Simple example:

```yaml
name: Code Test

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:

  build:
    name: Run Go unit tests and check package coverage
    runs-on: ubuntu-latest
    steps:
      - name: Checkout the code
        uses: actions/checkout@v4
      - name: Run unit tests and check package coverage
        uses: dell/common-github-actions/go-code-tester@main
        with:
          threshold: 90
          test-folder: "."
          # Optional parameter to skip certain packages
          skip-list: "this/pkg1,this/pkg2"
          # Optional paramter to enable the race detector
          race-detector: "true"
          # Optional parameter to skip tests
          skip-test: "TestToSkip"
          # Optional parameter to specify regex for tests to run
          run-test: "TestToRun"
          # Optional paramter to exlude certain directories from go test. Ex. intregration test folders.
          exclude-directory: "DirectoryToExclude|DirectoryToExclude2"
```

The `threshold` for the Action is a coverage percentage threshold that every package must meet. The default `threshold` is 90.

The `test-folder` is for specifying what folder to run the test command in. The default value is the current folder, `"."`

The `skip-list` is an optional parameter. It should be a comma delimited string of package names to skip for the testing coverage criteria.

The `race-detector` is an optional boolean parameter to enable or disable the race detector.

The `skip-test` is a regex and passed directly as the -skip option to the `go test` command.

The `run-test` is a regex and passed directly as the -run option to the `go test` command.

The `exclude-directory` is an optional parameter to filter out directories you want to exclude from the `go test` command.
