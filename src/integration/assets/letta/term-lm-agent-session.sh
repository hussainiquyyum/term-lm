#!/bin/sh
# managed by term-lm; reinstalling the integration replaces this file.
# TERMLM_INTEGRATION_ID=letta
# TERMLM_INTEGRATION_VERSION=2

[ "${1:-}" = "session" ] || exit 0
[ "${TERMLM_ENV:-}" = "1" ] || exit 0
[ -n "${TERMLM_PANE_ID:-}" ] || exit 0
[ -n "${TERMLM_SOCKET_PATH:-}" ] || exit 0
if [ -n "${TERMLM_BIN_PATH:-}" ]; then
    [ -x "$TERMLM_BIN_PATH" ] || exit 0
else
    command -v term-lm >/dev/null 2>&1 || exit 0
fi
command -v python3 >/dev/null 2>&1 || exit 0

# SessionStart stdout is injected into Letta's next user message. Keep every
# path silent, including successful reports and malformed hook input.
python3 -c '
import json
import os
import subprocess
import sys
import time

try:
    payload = json.load(sys.stdin)
    conversation_id = payload.get("conversation_id")
    agent_id = payload.get("agent_id")
    if not isinstance(conversation_id, str) or not conversation_id:
        raise ValueError
    if conversation_id == "default":
        if not isinstance(agent_id, str) or not agent_id:
            raise ValueError
        session_id = "default:" + agent_id
    else:
        session_id = conversation_id

    command = os.environ.get("TERMLM_BIN_PATH") or "term-lm"
    args = [
        command, "pane", "report-agent-session", os.environ["TERMLM_PANE_ID"],
        "--source", "term-lm:letta", "--agent", "letta",
        "--agent-session-id", session_id, "--seq", str(time.time_ns()),
        "--session-start-source", "new" if payload.get("is_new_session") else "resume",
    ]
    subprocess.run(
        args,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        timeout=1,
        check=False,
    )
except Exception:
    pass
' 2>/dev/null || true
