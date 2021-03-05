# Go Code Tester GitHub Action
This GitHub Action can be used to run Go unit tests and check that code coverage per package meets a threshold.

To enable this Action, you can create a .yml file under your repo's .github/workflows directory. 
Simple example:

```
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
        uses: actions/checkout@v2
      - name: Run unit tests and check package coverage
        uses: dell/common-github-actions/go-code-tester@main
        with:
          threshold: 90
          # Optional parameter to skip certain packages
          skip-list: "this/pkg1,this/pkg2"
```

The `threshold` for the Action is a coverage percentage threshold that every package must meet. The default `threshold` is 90.

The `skip-list` is an optional parameter. It should be a comma delimited string of package names to skip for the testing coverage criteria.
