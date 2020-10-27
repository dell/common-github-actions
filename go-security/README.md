# Code GO-Security GitHub Action
This GitHub Action can be used to check sources files for go security issues.

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

  go_security_scan:
    name: Go security
    runs-on: ubuntu-latest
    steps:
      - name: Checkout the code
        uses: actions/checkout@v2
      - name: Go Security
        uses: dell/common-github-actions/go-security@main
        with:
          args: -h
```

The `args` for the Action is argument for gosec.
You can use `-h` (default if no `args` are provided) to see gosec Usage/ Moreover, you can use `-quiet ./...` to check from the root of the repo and to show only output when error is found.
