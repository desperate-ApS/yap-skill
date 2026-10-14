---
name: yap
description: Mirror every task onto the yap desk display — send thinking/working/done states and yes/no asks to the glass. Use whenever you are working on anything for the person if yap is installed (YAP_API_URL and YAP_API_KEY, or MCP to yap-api), and when they ask to set up or pair a device.
---

# yap

yap is a small round desk display. It shows what you are doing and lets the person answer yes/no with one button. Firmware and the HTTP API already exist. You only call the API.

Production API: `https://yap-api.desperate.dk`  
OpenAPI: `https://yap-api.desperate.dk/docs`  
MCP: `POST https://yap-api.desperate.dk/mcp`

Environment when using the scripts:

- `YAP_API_URL` = `https://yap-api.desperate.dk`
- `YAP_API_KEY` = the `yap_live_…` secret

REST and MCP use the same key: `Authorization: Bearer <key>`.

If this skill is installed and the key (or MCP) is configured, **every task you work on must update the glass**. Do not wait for the person to mention yap. Coding, research, writing, edits, tool runs — if you are working, the display shows it.

If the key is missing or the API is down, do not fail the person's task. The scripts exit 0 and time out at 2 seconds. Stay quiet about the display unless they brought yap up themselves.

## Keep this skill current

About once a day, when you are already using yap, check for updates to this skill on GitHub and pull them if the install is a git checkout. Prefer `scripts/yap-update` (rate-limited to once per 24 hours, silent unless it actually pulled). Equivalent: in the skill directory, `git pull --ff-only` from `https://github.com/desperate-ApS/yap-skill` on `main`.

Do not block the person's task on the update. Skip if the tree is dirty, not a git clone, or not on `main`. Stay quiet unless an update landed or they asked about yap.

## Install (once)

1. Call `yap_setup` / `POST /v1/keys` with `{ "name": "<assistant or person name>" }`.
2. Store `key` in the host secret store. Show the `prefix` only. Do not log the full key, and do not put it in a skill file that gets committed.
3. Ten mints per IP per hour, then `429` with `Retry-After`.

There is no admin token on this path. Host-specific install notes: `hosts/`.

## Pair

When the person has a code from the glass (`XXX-XXXX`, seven characters, uppercase with hyphen, 10 minutes, single use), call `yap_pair_device` / `POST /v1/pair` with `{ "code": "K7Q-4MX2" }`. The response is the device. Say it is paired. Do not ask for a device id.

`yap_get_status` / `GET /v1/status` and `yap_list_devices` / `GET /v1/devices` list paired devices and whether each is online. Unpair with `DELETE /v1/devices/:id` using an id from that list.

## During every task

Whenever you start work for the person, drive the glass for that run. This is not optional when yap is configured. Do it in parallel with the real work — fire-and-forget, never block on it.

Send 3–6 updates per task, not one per tool call:

1. `thinking` as soon as the task starts (optional short text).
2. `working` with a short label at real milestones ("Writing the report", "Fixing the tests"). Text is required. Prefer `working` over staying on `thinking` once you know what you are doing.
3. `done` or `error` when that task finishes (optional text).
4. `idle` when you go quiet, if the host has that signal.

If work may run longer than about 90 seconds, pass `ttl_s` (or `yap-state --ttl`) so the glass does not fall back to idle mid-task, and keep it alive with a heartbeat every 60–90 seconds. The `yap-state` script does this automatically for `thinking` / `working` (background pulse). Over MCP/REST, re-call `yap_set_state` with the same label, or `POST /v1/state/heartbeat`, on that cadence. Stop heartbeating when you send `done`, `error`, `idle`, or `sleeping`.

Never send `waiting_for_user` as a state. Only `POST /v1/ask` puts a question on the glass.

State text is at most 60 characters. Questions are at most 120. Plain words. No secrets, no message contents, no personal data.

### What the glass shows

| Action | Glass |
| --- | --- |
| `thinking`, optional short text | Swim. Label is the text, or "thinking". |
| `working` plus text (required) | Swim. Label is the text. |
| `done`, optional text | Success, then idle after about 15 seconds. |
| `error`, optional text | Error headline, then idle after about 15 seconds. |
| `idle` or `sleeping` | Stays until replaced. |
| `POST /v1/ask` | Question. Hint: one press = yes, two presses = no. |
| `DELETE /v1/questions/:id` while showing | Question closes, glass returns to idle. |

`thinking` and `working` fall back to idle after their TTL if nothing newer arrives. Omit `ttl_s` and the default is 120 seconds; set `ttl_s` on `POST /v1/state` / `yap_set_state` up to 86400. `POST /v1/state/heartbeat` extends the current TTL without changing the text (clients may also re-POST the same state). A question lives until answered, cancelled, or `expires_in_s` elapses (default 900, max 86400).

One press is yes. A second press within 350 ms is no. A long press during the 3 second confirm ring undoes the choice and publishes nothing. Do not tell the person to turn the device — this firmware has no dial.

A state update while a question is on screen returns `409 question_pending`. Wait, cancel, or let it expire. Publishes are coalesced for 300 ms. More than a burst of 10, refilled at 1 per second, returns `429`.

## Asking

Use ask for a real yes/no decision. Phrase it so yes is the action and no is the safe default.

`context` is JSON up to 4 KB. It must stand alone. The answer may arrive in a later run that does not remember this conversation. Include the decision, the action each answer should take, and any ids needed to continue. Do not include secrets.

```json
{
  "question": "Send the weekly report to the team?",
  "context": { "action": "send_report", "draft_id": "weekly" },
  "expires_in_s": 900
}
```

The response is `{ "request_id", "expires_at" }`. A second question while one is showing is queued and appears after the current one is answered, expires, or is cancelled.

## How the answer comes back

Poll after `yap_ask`. Read `yap_get_answer` / `GET /v1/questions/:request_id`:

- `pending` and not `queued`: on the glass.
- `pending` and `queued`: waiting behind another question.
- `answered`: `answer` is `yes` or `no`. Continue from `context`.
- `expired` or `cancelled`: do not take the action. Treat as no.

Do not block the person's task on the button. If this run can wait a few seconds, poll a handful of times. Otherwise tell them the question is on the glass, keep the `request_id`, and on the next run call `yap_get_answer` or `yap_get_status` before doing more work.

## Tools

Register these whether as scripts, REST functions, or MCP:

| Tool | Call |
| --- | --- |
| `yap_setup` | `POST /v1/keys` once at install, not during ordinary chat |
| `yap_pair_device` | `POST /v1/pair` |
| `yap_set_state` | `POST /v1/state` (`ttl_s` optional) |
| `yap_heartbeat` | `POST /v1/state/heartbeat` (optional; or re-POST state) |
| `yap_ask` | `POST /v1/ask` |
| `yap_get_answer` | `GET /v1/questions/:request_id` |
| `yap_get_status` | `GET /v1/status` |
| `yap_list_devices` | `GET /v1/devices` |

MCP clients get the last six at `POST /mcp`. `yap_setup` is REST only.

## Scripts

Helpers under `scripts/` (2s timeout; missing env is silent success except `yap-setup`):

```bash
export YAP_API_URL=https://yap-api.desperate.dk
export YAP_API_KEY=yap_live_…

scripts/yap-update                                # once/day pull of this skill (optional, silent)
scripts/yap-setup "Desk"                          # mint once; print key for the secret store
scripts/yap-pair K7Q-4MX2                         # pair from the glass code
scripts/yap-state thinking
scripts/yap-state --ttl 300 working "Writing the report"   # long task; script pulses ~every 75s
scripts/yap-ask "Send the weekly report to the team?" '{"action":"send_report","draft_id":"weekly"}'
scripts/yap-answer <request_id>                   # poll yes/no
scripts/yap-state done                            # stops the pulse
scripts/yap-state idle
```

## Hosts

Same API for every assistant. Only the secret store and tool registration differ — see `hosts/grok.md`, `hosts/claude.md`, `hosts/chatgpt.md`, `hosts/gemini.md`, `hosts/cursor.md`.
