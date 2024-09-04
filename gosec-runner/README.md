# Gosec Runner GitHub Action

This GitHub Action can be used to run gosec on a particular package.

To enable this Action, you can create a .yml file under your repo's .github/workflows directory.
Simple example:

```yaml
name: Gosec runner

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:

  build:
    name: Run gosec
    runs-on: ubuntu-latest
    steps:
      - name: Checkout the code
        uses: actions/checkout@v4
      - name: Run gosec to check for security vulnerabilities
        uses: dell/common-github-actions/gosec-runner@main
        with:
          directories: "./..."
          excludes: "G108,G402"
          exclude-dir: "csireverseproxy"
```

Arguments described below -- all are optional:

`directories` specifies what directory/directories gosec will run in -- the default `./...` specifies the current folder and all subfolders.

`excludes` is used to give a comma-delimited list of gosec excludes (using the `-excludes=` option in gosec). By default, there are no excludes.

`exclude-dir` specifies a directory to skip in the gosec check (using the `-exclude-dir=` option in gosec).
