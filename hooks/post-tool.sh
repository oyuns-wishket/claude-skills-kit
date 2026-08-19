#!/bin/sh
. "$HOME/.claude/hooks/lib.sh"
payload="$(cat)"
file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
[ -z "$file" ] && exit 0
out=""
# 쿨다운 스탬프를 repo별로 스코프(전역 단일 stamp는 한 repo 편집이 타 repo 리마인더를 침묵시킴).
rhash="$(cd "$(dirname "$file")" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null | shasum 2>/dev/null | cut -c1-12)"
rhash="${rhash:-global}"
# Rule 7 — ERP domain reminder (24h cooldown, repo-scoped)
case "$file" in
  */src/*/erp/*|*/erp/*)
    stamp="$HOME/.claude/.erp-domain-stamp-$rhash"
    if [ ! -f "$stamp" ] || [ -n "$(find "$stamp" -mtime +1 2>/dev/null)" ]; then
      out="$out
[Rule 7] ERP 도메인 변경 감지 — 프로젝트 전용 지식은 docs/erp-domain/, 여러 프로젝트에 공통이면 워크스페이스 공용 도메인 문서 갱신 검토."
      : > "$stamp"
    fi ;;
esac
# Rule 12 — 인프라성 파일 편집 시 docs/infra.md 갱신 리마인더 (24h 쿨다운)
case "$file" in
  */vercel.json|*/supabase/config.toml|*/.env*|*/docker-compose*|*/Dockerfile|*/next.config.*)
    istamp="$HOME/.claude/.infra-stamp-$rhash"
    if [ ! -f "$istamp" ] || [ -n "$(find "$istamp" -mtime +1 2>/dev/null)" ]; then
      out="$out
[Rule 12] 인프라성 파일 변경 감지 — docs/infra.md(배포·환경·브랜치 워크플로우) 갱신 검토."
      : > "$istamp"
    fi ;;
esac
# 브랜치 가드 — 앱 프로젝트에서 main/develop 직접 편집 시 경고(deny 아님).
# 정확히 $HOME/aidp/ 직속만(개인 SSOT 레포의 workspaces/aidp/ 같은 경로는 제외). develop→feat→develop→main.
case "$file" in
  "$HOME"/aidp/*)
    gbr="$(cd "$(dirname "$file")" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null)"
    case "$gbr" in
      main|master|develop)
        out="$out
[브랜치] '$gbr'에서 직접 편집 중 — aidp는 feature 브랜치 워크플로우(develop → feat/<x> → develop 머지 → main 배포). 'git checkout -b feat/<x>'(develop 기준) 후 작업 권장." ;;
    esac ;;
esac
# Rule 2 — TODO(issue): scan in the edited file
if grep -qE 'TODO\(issue\):|FIXME\(issue\):' "$file" 2>/dev/null; then
  out="$out
[Rule 2] '$file'에 TODO(issue) 발견 — GitHub 이슈 초안 작성 후 확인받아 등록 권장."
fi
[ -n "$out" ] && jq -n --arg c "$out" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$c}}'
exit 0
