# Code GO-Security GitHub Action
This GitHub Action can be used to check sources files for go security issues.
It requires [gosec installed](https://github.com/securego/gosec) in CI.

To enable this Action, you can create a .yml file under your repo's .github/workflows directory. 
Simple example:

```
name: Security Check

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:

  code-check:
    name: Go security
    runs-on: ubuntu-latest
    steps:
      - name: Checkout the code
        uses: actions/checkout@v2
      - name: Go Security
        uses: dell/common-github-actions/go-security@main
        with:
          directories: ./...
```

The `directories` for the Action is a path in which to check for these issues. You can use `./...` (default if no `directories` are provided) to check from the root of the repo.
