# Gemini

1. Mint a key: `POST https://yap-api.desperate.dk/v1/keys` with `{ "name": "Gemini" }`, or run `scripts/yap-setup "Gemini"`.
2. Store `key` as a bearer secret. Show only `prefix`.
3. Register function declarations with the same REST bodies as in `SKILL.md` (`/v1/keys`, `/v1/pair`, `/v1/state`, `/v1/ask`, `/v1/questions/:id`, `/v1/status`, `/v1/devices`).
4. Answer path: poll `GET /v1/questions/:request_id`.
