FROM golang:latest

LABEL "com.github.actions.name"="go-security"
LABEL "com.github.actions.description"="Checks for Go security issues in the code"
LABEL "com.github.actions.icon"="eye"
LABEL "com.github.actions.color"="gray-dark"

LABEL version="1.0.0"

# Install gosec
RUN apt-get update
RUN apt-get -y install curl
RUN curl -sfL https://raw.githubusercontent.com/securego/gosec/master/install.sh | sh -s -- -b $(go env GOPATH)/bin latest
RUN gosec --help

COPY "entrypoint.sh" "/entrypoint.sh"
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
