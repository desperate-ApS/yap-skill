# Claude / Claude Code

1. Install this skill (`SKILL.md` + `scripts/`).
2. Run `scripts/yap-setup "Claude"` once. Store `key` as `YAP_API_KEY` in the environment. Set `YAP_API_URL=https://yap-api.desperate.dk`.
3. Show only `prefix` in chat. Never commit the key.
4. Use the scripts during chat, or point MCP at `https://yap-api.desperate.dk/mcp` with `Authorization: Bearer <key>`.
5. Answer path: poll with `yap-answer` / `yap_get_answer`.
