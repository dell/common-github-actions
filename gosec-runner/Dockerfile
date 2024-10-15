FROM golang:1.23.2

LABEL "com.github.actions.name"="gosec-runner"
LABEL "com.github.actions.description"="Runs gosec"
LABEL "com.github.actions.icon"="eye"
LABEL "com.github.actions.color"="gray-dark"

LABEL version="1.0.0"

ENV GOFLAGS="-buildvcs=false"
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
