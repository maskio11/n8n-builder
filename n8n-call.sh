#!/bin/bash
# Wrapper per chiamare n8n-mcp con env vars corrette

MCP_MODE=stdio \
LOG_LEVEL=error \
DISABLE_CONSOLE_OUTPUT=true \
N8N_API_URL="https://n8n.srv1159731.hstgr.cloud" \
N8N_API_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIwMmE2MzY1Yi00OTExLTQ0ZTMtOGNmYy0yNmYzZmM1MjM3MDAiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzcyMTExNzczfQ.W2EJnE-OfGOk4TA_pupXPKDN2LRVh5qHePVImnauBDQ" \
npx n8n-mcp
