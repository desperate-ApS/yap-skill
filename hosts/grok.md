# Grok / xAI

1. Install this skill (`SKILL.md` + `scripts/`). Prefer a git clone so `scripts/yap-update` can pull updates.
2. Run `scripts/yap-setup "Grok"` once. That writes `YAP_API_KEY` to `${XDG_CONFIG_HOME:-$HOME/.config}/yap/env` (mode 600), outside the skill directory.
3. Also store the key in the host's persistent secret store for this skill (the Grok skill environment that survives a reset of the workspace). Do not keep it only in the skill folder, in `~/.yap/env`, or in `/tmp`.
4. Keep `YAP_API_URL=https://yap-api.desperate.dk` in that same env file.
5. Show only `prefix` in chat. Never commit the key.
6. Pair with the glass code via `yap-pair` / `yap_pair_device`.
7. If the key is gone after a reset, say so. Mint a new key, save it in the host secret and in `~/.config/yap/env`, and pair the glass again.
8. Answer path: poll with `yap-answer` / `yap_get_answer`.
