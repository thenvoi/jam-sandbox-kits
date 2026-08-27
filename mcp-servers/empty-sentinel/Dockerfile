FROM golang:1.25.0-alpine3.22@sha256:f18a072054848d87a8077455f0ac8a25886f2397f88bfdd222d6fafbb5bba440 AS build

WORKDIR /src
COPY server/go.mod server/go.sum ./
RUN go mod download
COPY server/main.go ./
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /out/jam-empty-mcp-sentinel .

FROM scratch
COPY --from=build /out/jam-empty-mcp-sentinel /jam-empty-mcp-sentinel
USER 65532:65532
ENTRYPOINT ["/jam-empty-mcp-sentinel"]
