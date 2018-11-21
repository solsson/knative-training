FROM golang:1.11.2-alpine

COPY . /go/src/knative-training.local/frontend

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
  go install -ldflags '-w -extldflags "-static"' \
  /go/src/knative-training.local/frontend

FROM scratch

COPY --from=0 /go/bin/frontend /frontend

ENV PORT 8080
EXPOSE $PORT

CMD ["/frontend"]
