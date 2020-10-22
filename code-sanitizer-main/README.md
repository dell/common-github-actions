# Code Sanitizer GitHub Action
This GitHub Action can be used to check sources files for forbidden words and text. Forbidden words include 
such things as non-inclusive language, non-private IP addresses. 

To enable this Action, you can create a .yml file under your repo's .github/workflows directory. 
Simple example:

```
name: Sanitize source

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:

  build:
    name: Check for forbidden words
    runs-on: ubuntu-latest
    steps:
      - name: Checkout the code
        uses: actions/checkout@v2
      - name: Run the forbidden words scan
        uses: dell/common-github-actions/code-sanitizer@main
        with:
          args: .
```

The `args` for the Action is a path in which to search for forbidden words. You can use '.' to search from the root of the repo.
