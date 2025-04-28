FROM golang:1.24

LABEL "com.github.actions.name"="license-checker"
LABEL "com.github.actions.description"="Checks for license header"
LABEL "com.github.actions.icon"="eye"
LABEL "com.github.actions.color"="gray-dark"

LABEL version="1.0.0"
RUN ls -al
COPY . ./
RUN go mod tidy
RUN go build .
ENTRYPOINT ["./license-checker"]
