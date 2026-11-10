# installed by term-lm
# managed by term-lm; reinstalling or updating the integration overwrites this file.
# add custom hooks beside this file instead of editing it.
# TERMLM_INTEGRATION_ID=mastracode
# TERMLM_INTEGRATION_VERSION=3

param([string]$Action = "")

if ($Action -notin @("session", "working", "idle", "blocked")) { exit 0 }
if ($env:TERMLM_ENV -ne "1") { exit 0 }
if ([string]::IsNullOrWhiteSpace($env:TERMLM_PANE_ID)) { exit 0 }

# Read hook input as raw bytes so UTF-8 payloads decode correctly even when the
# console input code page is not UTF-8 (for example CP949 on Korean Windows).
$stdinReader = New-Object System.IO.StreamReader([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8)
$inputText = $stdinReader.ReadToEnd()
try {
    $payload = if ([string]::IsNullOrWhiteSpace($inputText)) { $null } else { $inputText | ConvertFrom-Json }
} catch {
    $payload = $null
}

$sessionId = if ($null -ne $payload -and $payload.session_id -is [string]) { $payload.session_id } else { $null }
$seq = [DateTime]::UtcNow.Ticks
$term_lm = if ([string]::IsNullOrWhiteSpace($env:TERMLM_BIN_PATH)) { "term-lm" } else { $env:TERMLM_BIN_PATH }
try {
    if ($Action -eq "session") {
        if ([string]::IsNullOrWhiteSpace($sessionId)) { exit 0 }
        & $term_lm pane report-agent-session $env:TERMLM_PANE_ID --source term-lm:mastracode --agent mastracode --seq $seq --session-start-source startup --agent-session-id $sessionId 2>$null | Out-Null
    } else {
        $args = @("pane", "report-agent", $env:TERMLM_PANE_ID, "--source", "term-lm:mastracode", "--agent", "mastracode", "--state", $Action, "--seq", "$seq")
        if (-not [string]::IsNullOrWhiteSpace($sessionId)) {
            $args += @("--agent-session-id", $sessionId)
        }
        & $term_lm @args 2>$null | Out-Null
    }
} catch {
}
