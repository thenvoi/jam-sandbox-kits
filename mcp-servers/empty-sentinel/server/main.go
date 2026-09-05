package main

import (
	"context"
	"log"

	"github.com/modelcontextprotocol/go-sdk/mcp"
)

func newEmptyServer() *mcp.Server {
	server := mcp.NewServer(&mcp.Implementation{
		Name:    "jam-empty-sentinel",
		Version: "0.1.0",
	}, nil)
	type emptySelectionInput struct{}
	mcp.AddTool(server, &mcp.Tool{
		Name:        "jam_empty_mcp_selection",
		Description: "Reports that this sandbox has no user-selected MCP services.",
	}, func(context.Context, *mcp.CallToolRequest, emptySelectionInput) (*mcp.CallToolResult, any, error) {
		return &mcp.CallToolResult{Content: []mcp.Content{
			&mcp.TextContent{Text: "No user-selected MCP services are enabled for this sandbox."},
		}}, nil, nil
	})
	return server
}

func main() {
	if err := newEmptyServer().Run(context.Background(), &mcp.StdioTransport{}); err != nil {
		log.Fatalf("jam-empty-mcp-sentinel: transport failed: %v", err)
	}
}
