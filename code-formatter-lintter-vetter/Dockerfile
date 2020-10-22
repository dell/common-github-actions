FROM golang:1.14

LABEL "com.github.actions.name"="code-formatter-lintter-vetter"
LABEL "com.github.actions.description"="Checks for formatting, linting, and vetting issues"
LABEL "com.github.actions.icon"="eye"
LABEL "com.github.actions.color"="gray-dark"

LABEL version="1.0.0"

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
