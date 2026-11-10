# installed by term-lm
# managed by term-lm; reinstalling or updating the integration overwrites this file.
# add custom hooks beside this file instead of editing it.
# TERMLM_INTEGRATION_ID=codex
# TERMLM_INTEGRATION_VERSION=10

param([string]$Action = "")

if ($Action -ne "session") { exit 0 }
if ($env:TERMLM_ENV -ne "1") { exit 0 }
if ([string]::IsNullOrWhiteSpace($env:TERMLM_PANE_ID)) { exit 0 }

# Read hook input as raw bytes so UTF-8 payloads decode correctly even when the
# console input code page is not UTF-8 (for example CP949 on Korean Windows).
$stdinReader = New-Object System.IO.StreamReader([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8)
$inputText = $stdinReader.ReadToEnd()
try {
    $payload = if ([string]::IsNullOrWhiteSpace($inputText)) { $null } else { $inputText | ConvertFrom-Json }
} catch {
    exit 0
}

if ($payload.hook_event_name -and $payload.hook_event_name -ne "SessionStart") { exit 0 }

$sessionId = $payload.session_id
if ([string]::IsNullOrWhiteSpace($sessionId)) { exit 0 }
if ([string]::IsNullOrWhiteSpace($payload.transcript_path)) { exit 0 }
if (-not [string]::IsNullOrWhiteSpace($env:CODEX_THREAD_ID) -and $env:CODEX_THREAD_ID -ne $sessionId) { exit 0 }

$seq = [DateTimeOffset]::UtcNow.Ticks
$term_lm = if ([string]::IsNullOrWhiteSpace($env:TERMLM_BIN_PATH)) { "term-lm" } else { $env:TERMLM_BIN_PATH }
try {
    $args = @(
        "pane",
        "report-agent-session",
        $env:TERMLM_PANE_ID,
        "--source",
        "term-lm:codex",
        "--agent",
        "codex",
        "--seq",
        "$seq",
        "--agent-session-id",
        "$sessionId"
    )
    if ($payload.hook_event_name -eq "SessionStart" -and $payload.source -is [string] -and -not [string]::IsNullOrWhiteSpace($payload.source)) {
        $args += @("--session-start-source", "$($payload.source)")
    }
    & $term_lm @args 2>$null | Out-Null
} catch {
}
