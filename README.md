# yap skill

Installable assistant skill for [yap](https://yap.desperate.dk) — a desk display that shows task progress and yes/no questions.

The API and MCP server are already hosted. This repo is only the skill text, shell helpers, and per-host install notes.

- API: https://yap-api.desperate.dk  
- OpenAPI: https://yap-api.desperate.dk/docs  
- MCP: `POST https://yap-api.desperate.dk/mcp`

Behavior for the model lives in [`SKILL.md`](SKILL.md). Host wrappers: [`hosts/`](hosts/).

## Quick start

```bash
git clone https://github.com/desperate-ApS/yap-skill.git
cd yap-skill

# Mint a key once (prints plaintext once — store it as a secret)
./scripts/yap-setup "Desk"
export YAP_API_URL=https://yap-api.desperate.dk
export YAP_API_KEY=yap_live_…   # from the setup response; show only the prefix in chat

# Pair with the code on the glass (XXX-XXXX)
./scripts/yap-pair K7Q-4MX2

./scripts/yap-task "Writing the report" -- make test   # thinking, then done or error
./scripts/yap-state thinking
./scripts/yap-state --ttl 300 working "Writing the report"   # long task; auto-pulse keeps the glass awake
./scripts/yap-ask "Send the weekly report?" '{"action":"send_report"}'
./scripts/yap-answer <request_id>
./scripts/yap-state done
```

On every task the glass gets a start (`thinking`), milestones (`working` with a short label), and a finish (`done` or `error`). `yap-task` does that around one command and does not wait on the API.

Never commit `YAP_API_KEY`. Missing env is silent success for the state/ask/pair/answer scripts. A timeout, network error, or 5xx is retried in the background so a down API does not block the task or leave the glass on a stale state. 4xx is not retried.

For long tasks, pass `--ttl` (seconds, max 86400; default when omitted is the API’s 120s). While the state is `thinking` or `working`, `yap-state` heartbeats in the background about every 75 seconds so the display does not fall back to idle. `done` / `error` / `idle` / `sleeping` stop the pulse.

## Install by host

### Cursor (skill + MCP)

Copy or symlink this repo into your skills dir:

```bash
mkdir -p ~/.cursor/skills
ln -s "$(pwd)" ~/.cursor/skills/yap
```

Or project-local: `.cursor/skills/yap/`.

Add MCP (replace the key with your secret):

```json
{
  "mcpServers": {
    "yap": {
      "url": "https://yap-api.desperate.dk/mcp",
      "headers": {
        "Authorization": "Bearer yap_live_…"
      }
    }
  }
}
```

Details: [`hosts/cursor.md`](hosts/cursor.md).

### Claude / Claude Code

```bash
mkdir -p ~/.claude/skills
ln -s "$(pwd)" ~/.claude/skills/yap
```

Set `YAP_API_URL` and `YAP_API_KEY`, or configure MCP the same way as Cursor. Details: [`hosts/claude.md`](hosts/claude.md).

### Grok / xAI

Install `SKILL.md` (+ `scripts/` if the host can run them). Put `YAP_API_URL` and `YAP_API_KEY` in the skill environment. Poll for answers. Details: [`hosts/grok.md`](hosts/grok.md).

### ChatGPT

Point MCP at `https://yap-api.desperate.dk/mcp` with a bearer key, or register function tools for the `/v1/*` routes in `SKILL.md`. Details: [`hosts/chatgpt.md`](hosts/chatgpt.md).

### Gemini

Same REST bodies as function declarations; bearer key; poll `GET /v1/questions/:id`. Details: [`hosts/gemini.md`](hosts/gemini.md).

## Scripts

| Script | Purpose |
| --- | --- |
| `scripts/yap-setup [name]` | `POST /v1/keys` — print key once |
| `scripts/yap-pair <code>` | `POST /v1/pair` |
| `scripts/yap-task "label" -- command` | `thinking`, then `done` or `error` from the command's exit code |
| `scripts/yap-state [--ttl N] <state> [text]` | `POST /v1/state` (optional `ttl_s`; pulses during thinking/working) |
| `scripts/yap-ask "question" ['{…}']` | `POST /v1/ask` |
| `scripts/yap-answer <request_id>` | `GET /v1/questions/:id` |
| `scripts/yap-update` | Once per day, `git pull --ff-only` this skill from GitHub (silent if nothing to do) |

Requires `curl` and `node` for JSON bodies. `yap-update` also needs `git` and a clean clone on `main`.

Agents following [`SKILL.md`](SKILL.md) should run `yap-update` about once a day when using yap so skill/script changes land without a manual reinstall.
