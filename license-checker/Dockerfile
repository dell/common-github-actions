FROM golang:1.24

LABEL "com.github.actions.name"="license-checker"
LABEL "com.github.actions.description"="Checks for license header"
LABEL "com.github.actions.icon"="eye"
LABEL "com.github.actions.color"="gray-dark"

LABEL version="1.0.0"

COPY go.mod go.sum main.go LICENSE-HEADER.txt ./
RUN go build .
ENTRYPOINT ["./license-checker"]
