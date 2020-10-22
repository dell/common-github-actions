FROM golang:latest

LABEL "com.github.actions.name"="code-sanitizer"
LABEL "com.github.actions.description"="Checks for forbidden words and text in the code"
LABEL "com.github.actions.icon"="eye"
LABEL "com.github.actions.color"="gray-dark"

LABEL version="1.0.0"

COPY "inclusive-words.forbidden-word-list" "/inclusive-words.forbidden-word-list"
COPY "entrypoint.sh" "/entrypoint.sh"
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
