# License header checker GitHub Action

This GitHub Action can be used to check the license header for the source codes (.go files only).

To enable this Action, you can create a .yml file under your repo's .github/workflows directory.
Simple example:

```yaml
name: License Header Checker

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:

  check-license-header:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Check license headers
        uses: dell/common-github-actions/license-checker@main
        with:
          autofix: false
```

Arguments described below -- all are optional:

`autofix` specifies whether to enable auto-fix the missing headers in the source code or not. This is optional. The default value will be `False` if nothing is supplied
