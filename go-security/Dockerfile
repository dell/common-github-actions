FROM golang:latest

LABEL "com.github.actions.name"="go-security"
LABEL "com.github.actions.description"="Checks for Go security issues in the code"
LABEL "com.github.actions.icon"="eye"
LABEL "com.github.actions.color"="gray-dark"

LABEL version="1.0.0"

COPY "entrypoint.sh" "/entrypoint.sh"
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]