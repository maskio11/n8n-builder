#!/bin/bash
# Helper per chiamare n8n-mcp con le variabili d'ambiente dal .mcp.json
export MCP_MODE=stdio
export LOG_LEVEL=error
export DISABLE_CONSOLE_OUTPUT=true
export N8N_API_URL="https://n8n.srv1159731.hstgr.cloud"
export N8N_API_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIwMmE2MzY1Yi00OTExLTQ0ZTMtOGNmYy0yNmYzZmM1MjM3MDAiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzcyMTExNzczfQ.W2EJnE-OfGOk4TA_pupXPKDN2LRVh5qHePVImnauBDQ"

echo "$1" | npx n8n-mcp 2>/dev/null
