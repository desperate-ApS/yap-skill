# Grok / xAI

1. Install this skill (`SKILL.md` + `scripts/`).
2. Run `scripts/yap-setup "Grok"` once. Store `key` as `YAP_API_KEY` in the skill environment. Keep `YAP_API_URL=https://yap-api.desperate.dk`.
3. Show only `prefix` in chat. Never commit the key.
4. Pair with the glass code via `yap-pair` / `yap_pair_device`.
5. Answer path: poll with `yap-answer` / `yap_get_answer`. A wake webhook is optional later, not required to ship.
