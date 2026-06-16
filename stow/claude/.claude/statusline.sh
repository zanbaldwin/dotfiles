#!/usr/bin/env bash
# Claude Code statusline. Reads the session JSON on stdin and prints two lines.
# Designed to degrade gracefully: a missing field or tool must never abort the
# render, so we deliberately avoid `set -e`/pipefail here.

input=$(cat)

# jq is required for every field below. If it is unavailable, emit a minimal
# line rather than a screenful of broken output, and exit cleanly.
if ! command -v jq >/dev/null 2>&1; then
    printf 'claude\n'
    exit 0
fi

# Single source of truth for "now" so every relative-time calculation in this
# render is consistent (and we spawn `date` once instead of four times).
NOW=$(date +%s)

# --- Single-pass field extraction -------------------------------------------
# Pull every scalar field in ONE jq invocation as newline-delimited records in
# a fixed order. Always use `// ""` (never `// empty`) so empty fields keep
# their slot and the array indices below stay aligned.
mapfile -t F < <(
    jq -r '
        [
            (.session_id // "global"),
            (.workspace.current_dir // .cwd // ""),
            (.workspace.project_dir // ""),
            (.model.display_name // ""),
            (.session_name // ""),
            (.version // ""),
            (.output_style.name // ""),
            (.cost.total_cost_usd // ""),
            (.context_window.current_usage.cache_read_input_tokens // ""),
            (.context_window.current_usage.cache_creation_input_tokens // ""),
            (.context_window.used_percentage // ""),
            (.cost.total_duration_ms // ""),
            (.cost.total_lines_added // ""),
            (.cost.total_lines_removed // ""),
            (.rate_limits.five_hour.used_percentage // ""),
            (.rate_limits.five_hour.resets_at // ""),
            (.rate_limits.seven_day.used_percentage // ""),
            (.rate_limits.seven_day.resets_at // ""),
            (.context_window.total_input_tokens // ""),
            (.context_window.total_output_tokens // ""),
            (.worktree.name // "")
        ] | .[] | tostring
    ' <<<"$input"
)

SESSION_ID=${F[0]}
DIR=${F[1]}
PROJECT_DIR=${F[2]}
MODEL=${F[3]}
SESSION_NAME=${F[4]}
VERSION=${F[5]}
OUTPUT_STYLE=${F[6]}
COST_USD=${F[7]}
CACHE_READ=${F[8]}
CACHE_CREATE=${F[9]}
PCT=${F[10]}
DURATION_MS=${F[11]}
LINES_ADDED=${F[12]}
LINES_REMOVED=${F[13]}
FIVE_H_PCT=${F[14]}
FIVE_H_RESET=${F[15]}
SEVEN_D_PCT=${F[16]}
SEVEN_D_RESET=${F[17]}
TOTAL_INPUT=${F[18]}
TOTAL_OUTPUT=${F[19]}
WORKTREE_JSON=${F[20]}

# added_dirs is an array, so it gets its own (newline-per-entry) pass.
ADDED_DIRS=$(jq -r '.workspace.added_dirs // [] | .[]' <<<"$input" 2>/dev/null)

BOLD_GREEN='\033[1;32m'
CYAN='\033[36m'
BOLD_BLUE='\033[1;34m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
MAGENTA='\033[35m'
RESET='\033[0m'

HOME_DIR="$HOME"
DIR="${DIR/#$HOME_DIR/~}"
BASENAME=$(basename "$DIR")

# Robbyrussell-style prompt
PROMPT_PART="${BOLD_GREEN}➜${RESET} ${CYAN}${BASENAME}${RESET}"

# Git info with dirty indicator
REAL_DIR="${DIR/#\~/$HOME_DIR}"
if [[ -d "${REAL_DIR}/.git" ]] || git -C "$REAL_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    BRANCH=$(git -C "$REAL_DIR" symbolic-ref --short HEAD 2>/dev/null)
    if [[ -n "$BRANCH" ]]; then
        DIRTY=""
        if ! git -C "$REAL_DIR" diff --quiet 2>/dev/null || ! git -C "$REAL_DIR" diff --cached --quiet 2>/dev/null; then
            DIRTY=" ${YELLOW}✗${RESET}"
        fi
        PROMPT_PART="${PROMPT_PART} ${BOLD_BLUE}git:(${RED}${BRANCH}${BOLD_BLUE})${RESET}${DIRTY}"
    fi
fi

# Worktree indicator: detect via git (works for both --worktree sessions and
# regular git worktrees created via `make worktree-new BRANCH=<name>`).
# In a linked worktree, git-dir != git-common-dir.
GIT_DIR=$(git -C "$REAL_DIR" rev-parse --no-flags --git-dir 2>/dev/null)
GIT_COMMON=$(git -C "$REAL_DIR" rev-parse --no-flags --git-common-dir 2>/dev/null)
if [[ -n "$WORKTREE_JSON" ]]; then
    PROMPT_PART="${PROMPT_PART} ${YELLOW}🌿 ${WORKTREE_JSON}${RESET}"
elif [[ -n "$GIT_DIR" ]] && [[ -n "$GIT_COMMON" ]] && [[ "$GIT_DIR" != "$GIT_COMMON" ]]; then
    # Derive worktree name from the directory basename
    WT_NAME=$(basename "$REAL_DIR")
    PROMPT_PART="${PROMPT_PART} ${YELLOW}🌿 worktree:${WT_NAME}${RESET}"
fi

# Session name
if [[ -n "$SESSION_NAME" ]]; then
    PROMPT_PART="${PROMPT_PART} ${MAGENTA}[${SESSION_NAME}]${RESET}"
fi

# Session cost
COST_STR=""
if [[ -n "$COST_USD" ]]; then
    COST_STR=$(printf "${YELLOW}\$%.2f${RESET}" "$COST_USD")
fi

# Cache efficiency (percentage of reads vs total cache operations)
CACHE_STR=""
if [[ -n "$CACHE_READ" ]] && [[ -n "$CACHE_CREATE" ]]; then
    CACHE_TOTAL=$((CACHE_READ + CACHE_CREATE))
    if [[ "$CACHE_TOTAL" -gt 0 ]]; then
        CACHE_PCT=$((CACHE_READ * 100 / CACHE_TOTAL))
        if [[ "$CACHE_PCT" -ge 70 ]]; then
            CACHE_COLOR="$GREEN"
        elif [[ "$CACHE_PCT" -ge 40 ]]; then
            CACHE_COLOR="$YELLOW"
        else
            CACHE_COLOR="$RED"
        fi
        CACHE_STR="${CACHE_COLOR}cache ${CACHE_PCT}%${RESET}"
    fi
fi

# Session duration
DURATION_STR=""
if [[ -n "$DURATION_MS" ]]; then
    DURATION_SECS=$((DURATION_MS / 1000))
    DUR_HOURS=$((DURATION_SECS / 3600))
    DUR_MINS=$(( (DURATION_SECS % 3600) / 60 ))
    if [[ "$DUR_HOURS" -gt 0 ]]; then
        DURATION_STR="${DUR_HOURS}u${DUR_MINS}m"
    else
        DURATION_STR="${DUR_MINS}m"
    fi
fi

# Lines changed
LINES_STR=""
if [[ -n "$LINES_ADDED" ]] || [[ -n "$LINES_REMOVED" ]]; then
    ADDED="${LINES_ADDED:-0}"
    REMOVED="${LINES_REMOVED:-0}"
    if [[ "$ADDED" -gt 0 ]] || [[ "$REMOVED" -gt 0 ]]; then
        LINES_STR="${GREEN}+${ADDED}${RESET} ${RED}-${REMOVED}${RESET}"
    fi
fi

# Rate limit cache: persist last known values per account so new sessions
# (including worktrees) show the bars immediately, before the first API response.
RATE_CACHE_FILE="/tmp/claude-statusline-rate-cache.json"

if [[ -n "$FIVE_H_PCT" ]] || [[ -n "$SEVEN_D_PCT" ]]; then
    # Fresh data available: update the cache atomically (write to a temp file in
    # the same directory, then rename) so concurrent sessions never read a
    # half-written file.
    RATE_CACHE_TMP=$(mktemp "${RATE_CACHE_FILE}.XXXXXX" 2>/dev/null)
    if [[ -n "$RATE_CACHE_TMP" ]]; then
        if jq -n \
            --argjson five_pct "${FIVE_H_PCT:-null}" \
            --argjson five_reset "${FIVE_H_RESET:-null}" \
            --argjson seven_pct "${SEVEN_D_PCT:-null}" \
            --argjson seven_reset "${SEVEN_D_RESET:-null}" \
            --argjson saved_at "$NOW" \
            '{five_pct: $five_pct, five_reset: $five_reset, seven_pct: $seven_pct, seven_reset: $seven_reset, saved_at: $saved_at}' \
            > "$RATE_CACHE_TMP" 2>/dev/null; then
            mv -f "$RATE_CACHE_TMP" "$RATE_CACHE_FILE" 2>/dev/null
        else
            rm -f "$RATE_CACHE_TMP" 2>/dev/null
        fi
    fi
elif [[ -f "$RATE_CACHE_FILE" ]]; then
    # No live data yet: use cached values (only if cache is less than 8 hours old).
    # One jq pass reads every field instead of four.
    mapfile -t RC < <(
        jq -r '[.saved_at // 0, .five_pct // "", .five_reset // "", .seven_pct // "", .seven_reset // ""] | .[] | tostring' \
            "$RATE_CACHE_FILE" 2>/dev/null
    )
    CACHE_AGE=${RC[0]:-0}
    if [[ -n "$CACHE_AGE" ]] && [[ $(( NOW - CACHE_AGE )) -lt 28800 ]]; then
        FIVE_H_PCT=${RC[1]}
        FIVE_H_RESET=${RC[2]}
        SEVEN_D_PCT=${RC[3]}
        SEVEN_D_RESET=${RC[4]}
    fi
fi

# Build rate limit part with progress bar
build_rate_part() {
    local label=$1 pct=$2 reset_at=$3 now=$4
    local part=""
    if [[ -n "$pct" ]]; then
        local pct_int
        pct_int=$(printf "%.0f" "$pct")
        local color
        if [[ "$pct_int" -ge 90 ]]; then
            color="$RED"
        elif [[ "$pct_int" -ge 70 ]]; then
            color="$YELLOW"
        else
            color="$GREEN"
        fi

        # Progress bar (10 chars wide, dim empty blocks, rounded)
        local dim='\033[2m'
        local filled=$(( (pct_int * 10 + 50) / 100 ))
        local empty=$((10 - filled))
        local bar_fill bar_pad
        printf -v bar_fill "%${filled}s"
        printf -v bar_pad "%${empty}s"
        local bar="${color}${bar_fill// /█}${RESET}${dim}${bar_pad// /░}${RESET}"

        local reset_str=""
        if [[ -n "$reset_at" ]]; then
            local diff
            diff=$((reset_at - now))
            if [[ "$diff" -gt 0 ]]; then
                local days hours mins
                days=$((diff / 86400))
                hours=$(( (diff % 86400) / 3600 ))
                mins=$(( (diff % 3600) / 60 ))
                if [[ "$days" -gt 0 ]]; then
                    reset_str=" ${days}d${hours}u"
                elif [[ "$hours" -gt 0 ]]; then
                    reset_str=" ${hours}u${mins}m"
                else
                    reset_str=" ${mins}m"
                fi
            fi
        fi

        part="${label}${bar} ${color}${pct_int}%${reset_str}${RESET}"
    fi
    echo "$part"
}

FIVE_PART=$(build_rate_part "5u:" "$FIVE_H_PCT" "$FIVE_H_RESET" "$NOW")
SEVEN_PART=$(build_rate_part "7d:" "$SEVEN_D_PCT" "$SEVEN_D_RESET" "$NOW")

# Tokens per minute: 5-minute rolling average
TPM_STR=""
if [[ -n "$TOTAL_INPUT" ]] && [[ -n "$TOTAL_OUTPUT" ]]; then
    TOTAL_TOKENS=$((TOTAL_INPUT + TOTAL_OUTPUT))
    STATE_FILE="/tmp/claude-statusline-${SESSION_ID}.log"
    WINDOW=300

    echo "${NOW} ${TOTAL_TOKENS}" >> "$STATE_FILE"

    CUTOFF=$((NOW - WINDOW))
    if [[ -f "$STATE_FILE" ]]; then
        awk -v cutoff="$CUTOFF" '$1 >= cutoff' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"

        OLDEST_LINE=$(head -1 "$STATE_FILE")
        OLDEST_TIME=$(echo "$OLDEST_LINE" | awk '{print $1}')
        OLDEST_TOKENS=$(echo "$OLDEST_LINE" | awk '{print $2}')

        if [[ -n "$OLDEST_TIME" ]] && [[ -n "$OLDEST_TOKENS" ]]; then
            ELAPSED=$((NOW - OLDEST_TIME))
            TOKEN_DIFF=$((TOTAL_TOKENS - OLDEST_TOKENS))
            if [[ "$ELAPSED" -gt 5 ]] && [[ "$TOKEN_DIFF" -gt 0 ]]; then
                TPM=$((TOKEN_DIFF * 60 / ELAPSED))
                if [[ "$TPM" -gt 0 ]]; then
                    TPM_STR="${MAGENTA}${TPM}/m${RESET} "
                fi
            fi
        fi
    fi
fi

# Combine rate parts
RATE_PART=""
if [[ -n "$FIVE_PART" ]] && [[ -n "$SEVEN_PART" ]]; then
    RATE_PART="${TPM_STR}${FIVE_PART} ${SEVEN_PART}"
elif [[ -n "$FIVE_PART" ]]; then
    RATE_PART="${TPM_STR}${FIVE_PART}"
elif [[ -n "$SEVEN_PART" ]]; then
    RATE_PART="${TPM_STR}${SEVEN_PART}"
fi

# === LINE 1: Identity + Config + Session stats ===
LINE1="${PROMPT_PART}"

# Model
[[ -n "$MODEL" ]] && LINE1="${LINE1} | ${CYAN}${MODEL}${RESET}"

# Output style (skip "default")
if [[ -n "$OUTPUT_STYLE" ]] && [[ "$OUTPUT_STYLE" != "default" ]]; then
    LINE1="${LINE1} | ${CYAN}${OUTPUT_STYLE}${RESET}"
fi

# Version
[[ -n "$VERSION" ]] && LINE1="${LINE1} | ${BOLD_BLUE}v${VERSION}${RESET}"

# Session duration
[[ -n "$DURATION_STR" ]] && LINE1="${LINE1} | ${CYAN}⏱ ${DURATION_STR}${RESET}"

# Session cost
[[ -n "$COST_STR" ]] && LINE1="${LINE1} | ${COST_STR}"

# Lines changed
[[ -n "$LINES_STR" ]] && LINE1="${LINE1} | ${LINES_STR}"

printf '%b\n' "$LINE1"

# === LINE 2: Resources + Limits + Path ===
GRAY='\033[38;5;245m'
SHORT_PROJECT="${PROJECT_DIR/#$HOME_DIR/~}"
LINE2="${GRAY}📂 ${SHORT_PROJECT}${RESET}"

if [[ -n "$ADDED_DIRS" ]]; then
    while IFS= read -r adir; do
        SHORT_ADIR="${adir/#$HOME_DIR/~}"
        LINE2="${LINE2} ${GRAY}+ ${SHORT_ADIR}${RESET}"
    done <<< "$ADDED_DIRS"
fi

# Context window progress bar
if [[ -n "$PCT" ]]; then
    PCT_INT=$(printf "%.0f" "$PCT")
    FILLED=$(( (PCT_INT * 10 + 50) / 100 ))
    EMPTY=$((10 - FILLED))
    printf -v FILL "%${FILLED}s"
    printf -v PAD "%${EMPTY}s"
    DIM='\033[2m'

    if [[ "$PCT_INT" -ge 90 ]]; then
        BAR_COLOR="$RED"
    elif [[ "$PCT_INT" -ge 70 ]]; then
        BAR_COLOR="$YELLOW"
    else
        BAR_COLOR="$GREEN"
    fi

    BAR="${BAR_COLOR}${FILL// /█}${RESET}${DIM}${PAD// /░}${RESET}"
    LINE2="${LINE2} | ${BAR} ${BAR_COLOR}${PCT_INT}%${RESET}"
fi

# Cache efficiency
[[ -n "$CACHE_STR" ]] && LINE2="${LINE2} | ${CACHE_STR}"

# Rate limits (with tokens/min)
[[ -n "$RATE_PART" ]] && LINE2="${LINE2} | ${RATE_PART}"

printf '%b' "$LINE2"
