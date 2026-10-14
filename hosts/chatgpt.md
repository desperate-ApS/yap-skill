# ChatGPT / OpenAI tools

1. Mint a key: `POST https://yap-api.desperate.dk/v1/keys` with `{ "name": "ChatGPT" }`, or run `scripts/yap-setup "ChatGPT"`.
2. Store `key` as a bearer secret. Show only `prefix`.
3. Either register MCP at `https://yap-api.desperate.dk/mcp` with `Authorization: Bearer <key>`, or expose function tools that POST/GET the same `/v1/*` routes as in `SKILL.md`.
4. Answer path: poll `GET /v1/questions/:request_id` / `yap_get_answer`.
