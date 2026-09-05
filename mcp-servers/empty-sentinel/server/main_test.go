package main

import (
	"context"
	"testing"

	"github.com/modelcontextprotocol/go-sdk/mcp"
)

func TestServerExposesOnlyTheInertSentinelTool(t *testing.T) {
	ctx := context.Background()
	serverTransport, clientTransport := mcp.NewInMemoryTransports()

	serverSession, err := newEmptyServer().Connect(ctx, serverTransport, nil)
	if err != nil {
		t.Fatalf("connect server: %v", err)
	}
	defer serverSession.Close()

	client := mcp.NewClient(&mcp.Implementation{Name: "sentinel-test", Version: "0.1.0"}, nil)
	clientSession, err := client.Connect(ctx, clientTransport, nil)
	if err != nil {
		t.Fatalf("connect client: %v", err)
	}
	defer clientSession.Close()

	initialize := clientSession.InitializeResult()
	if initialize == nil {
		t.Fatal("initialize result is nil")
	}
	if got := initialize.Capabilities; got.Tools == nil || got.Prompts != nil || got.Resources != nil {
		t.Fatalf("expected only the tools capability, got %#v", got)
	}

	tools, err := clientSession.ListTools(ctx, nil)
	if err != nil {
		t.Fatalf("list tools: %v", err)
	}
	if len(tools.Tools) != 1 || tools.Tools[0].Name != "jam_empty_mcp_selection" {
		t.Fatalf("expected only the inert sentinel tool, got %#v", tools.Tools)
	}
}
