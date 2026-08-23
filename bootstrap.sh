#!/usr/bin/env bash
#
# claude-skills-kit — Claude × Codex 스킬/규칙 설치·동기화
#
#   ./bootstrap.sh            # 적용 (백업 → 링크 → @import 주입 → 훅 설치)
#   ./bootstrap.sh --pull     # git pull 먼저 한 뒤 적용
#   ./bootstrap.sh --dry-run  # 무엇이 바뀔지만 출력, 실제 변경 없음
#   ./bootstrap.sh --status   # 현재 연결 상태만 점검
#
# 멱등(idempotent): 몇 번을 돌려도 안전. 이미 올바른 링크는 건너뛴다.
# 기존 파일은 절대 삭제하지 않고 ~/.claude/backups/ 로 백업한다.
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$REPO_DIR/manifest.json"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/.claude/backups/skills-kit-$TS"

PULL=0; DRY=0; STATUS=0
for a in "$@"; do
  case "$a" in
    --pull) PULL=1 ;;
    --dry-run) DRY=1 ;;
    --status) STATUS=1 ;;
    -h|--help) grep '^#' "$0" | sed 's/^#//'; exit 0 ;;
    *) echo "알 수 없는 옵션: $a" >&2; exit 2 ;;
  esac
done

c_ok="\033[32m"; c_skip="\033[90m"; c_act="\033[36m"; c_warn="\033[33m"; c_err="\033[31m"; c_off="\033[0m"
say(){ printf "%b%s%b\n" "$1" "$2" "$c_off"; }

command -v node >/dev/null || { say "$c_err" "node가 필요합니다 (manifest 파싱). → brew install node"; exit 1; }
[ -f "$MANIFEST" ] || { say "$c_err" "manifest.json 없음: $MANIFEST"; exit 1; }

if [ "$PULL" = 1 ]; then
  say "$c_act" "▶ git pull ..."
  git -C "$REPO_DIR" pull --ff-only
fi

expand(){ printf '%s' "${1/#\~/$HOME}"; }
ensure_backup_dir(){ [ -d "$BACKUP_DIR" ] || { [ "$DRY" = 1 ] || mkdir -p "$BACKUP_DIR"; }; }

# manifest → 탭 구분 레코드
LINKS="$(node -e '
  const m=require(process.argv[1]);
  for(const l of m.links||[]) console.log(["L",l.repo,l.target,l.type||"file"].join("\t"));
  for(const i of m.imports||[]) console.log(["I",i.import_repo,i.into,i.marker].join("\t"));
' "$MANIFEST")"

changed=0; ok=0
do_link(){ # repo target type
  local repo="$1" target="$2"
  local src="$REPO_DIR/$repo"; local dst; dst="$(expand "$target")"
  if [ ! -e "$src" ]; then say "$c_err" "  ✗ 레포 원본 없음: $repo"; return; fi
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    say "$c_skip" "  = 이미 링크됨: $target"; ok=$((ok+1)); return
  fi
  if [ "$STATUS" = 1 ]; then say "$c_warn" "  ! 링크 아님: $target"; return; fi
  say "$c_act" "  → 링크 생성: $target  ⟶  $repo"
  changed=$((changed+1))
  [ "$DRY" = 1 ] && return
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    ensure_backup_dir
    mv "$dst" "$BACKUP_DIR/$(basename "$dst")"
    say "$c_skip" "    (원본 백업 → $BACKUP_DIR/)"
  fi
  ln -s "$src" "$dst"
}

do_import(){ # repo into marker
  local repo="$1" into="$2" marker="$3"
  local src="$REPO_DIR/$repo"; local file; file="$(expand "$into")"
  local begin="<!-- BEGIN $marker (auto) -->"
  local end="<!-- END $marker (auto) -->"
  local line="@$src"
  local block; block="$(printf '%s\n%s\n%s' "$begin" "$line" "$end")"
  [ -f "$file" ] || { [ "$DRY" = 1 ] || { mkdir -p "$(dirname "$file")"; : > "$file"; }; }
  if [ -f "$file" ] && grep -qF "$begin" "$file" 2>/dev/null; then
    local cur; cur="$(awk -v b="$begin" -v e="$end" '$0==b{f=1} f{print} $0==e{f=0}' "$file")"
    if [ "$cur" = "$block" ]; then say "$c_skip" "  = @import 이미 최신: $into"; ok=$((ok+1)); return; fi
    if [ "$STATUS" = 1 ]; then say "$c_warn" "  ! @import 갱신 필요: $into"; return; fi
    say "$c_act" "  → @import 갱신: $into"; changed=$((changed+1))
    [ "$DRY" = 1 ] && return
    ensure_backup_dir; cp "$file" "$BACKUP_DIR/$(basename "$file").pre-import"
    awk -v b="$begin" -v e="$end" -v repl="$block" '
      $0==b{print repl; skip=1; next} skip&&$0==e{skip=0; next} !skip{print}
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  else
    if [ "$STATUS" = 1 ]; then say "$c_warn" "  ! @import 없음: $into"; return; fi
    say "$c_act" "  → @import 주입: $into"; changed=$((changed+1))
    [ "$DRY" = 1 ] && return
    [ -s "$file" ] && { ensure_backup_dir; cp "$file" "$BACKUP_DIR/$(basename "$file").pre-import"; }
    { [ -s "$file" ] && printf '\n'; printf '%s\n' "$block"; } >> "$file"
  fi
}

say "$c_act" "▶ claude-skills-kit 적용  (repo: $REPO_DIR)"
[ "$DRY" = 1 ] && say "$c_warn" "  [DRY-RUN] 실제 변경 없음"
[ "$STATUS" = 1 ] && say "$c_warn" "  [STATUS] 점검만"

while IFS=$'\t' read -r kind a b c; do
  [ -z "${kind:-}" ] && continue
  case "$kind" in
    L) do_link "$a" "$b" "$c" ;;
    I) do_import "$a" "$b" "$c" ;;
  esac
done <<< "$LINKS"

# --- 스킬 노출 ---
# Claude(~/.claude/skills)와 Codex(~/.agents/skills) 양쪽에 스킬별 개별 링크를 건다.
# 개별 링크인 이유: 이미 쓰던 다른 스킬이 있어도 그대로 보존하기 위해서다.
say "$c_act" "▶ 스킬 링크 (Claude + Codex)"
phys(){ (cd "$1" 2>/dev/null && pwd -P) || true; }

link_skill(){ # src_dir dst label — dst가 src와 같은 실체면 건드리지 않는다
  local src="${1%/}" dst="$2" label="$3" n; n="$(basename "$src")"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    say "$c_skip" "  = 링크됨: $label/$n"; ok=$((ok+1)); return
  fi
  local sp dp; sp="$(phys "$src")"; dp="$(phys "$dst")"
  if [ -n "$sp" ] && [ "$sp" = "$dp" ]; then
    say "$c_skip" "  = 동일 실체(링크 불필요): $label/$n"; ok=$((ok+1)); return
  fi
  if [ "$STATUS" = 1 ]; then say "$c_warn" "  ! 링크 아님: $dst"; return; fi
  if [ -d "$dst" ] && [ ! -L "$dst" ] && ! diff -rq "$src" "$dst" >/dev/null 2>&1; then
    say "$c_warn" "  ! 같은 이름의 실디렉토리가 있고 내용이 다릅니다(수동 확인 필요): $dst"; return
  fi
  say "$c_act" "  → 링크: $label/$n"
  changed=$((changed+1))
  [ "$DRY" = 1 ] && return
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    ensure_backup_dir; mv "$dst" "$BACKUP_DIR/skill-$label-$n"
    say "$c_skip" "    (기존 항목 백업 → $BACKUP_DIR/)"
  fi
  ln -s "$src" "$dst"
}

# ~/.claude/skills 가 다른 레포로 가는 통째 심링크면 개별 링크를 만들 수 없다 — 명확히 알린다.
CLAUDE_SKILLS="$HOME/.claude/skills"
if [ -L "$CLAUDE_SKILLS" ]; then
  say "$c_warn" "  ! ~/.claude/skills 가 이미 다른 디렉토리로 가는 심링크입니다 → Claude 쪽 링크 생략"
  say "$c_skip" "    (대상: $(readlink "$CLAUDE_SKILLS"))"
  SKIP_CLAUDE=1
else
  SKIP_CLAUDE=0
fi

for d in "$REPO_DIR"/skills/*/; do
  [ -d "$d" ] || continue
  [ "$SKIP_CLAUDE" = 0 ] && link_skill "$d" "$HOME/.claude/skills/$(basename "$d")" "claude"
  link_skill "$d" "$HOME/.agents/skills/$(basename "$d")" "codex"
done

# --- 훅 설치 + settings 병합 ---
if [ "$STATUS" != 1 ] && [ "$DRY" != 1 ]; then
  say "$c_act" "▶ 훅 설치"
  mkdir -p "$HOME/.claude/hooks"
  cp "$REPO_DIR"/hooks/*.sh "$HOME/.claude/hooks/" 2>/dev/null || true
  cp "$REPO_DIR"/hooks/*.mjs "$HOME/.claude/hooks/" 2>/dev/null || true
  chmod +x "$HOME"/.claude/hooks/*.sh "$HOME"/.claude/hooks/*.mjs 2>/dev/null || true
  say "$c_ok" "  훅 $(ls "$REPO_DIR"/hooks/ 2>/dev/null | wc -l | tr -d " ")개 설치"

  # settings.json: 훅 정의만 병합(통째 교체 X — 각 머신 고유 설정·토큰 보존). command 기준 dedup.
  GOV="$REPO_DIR/global/governance-hooks.json"; SET="$HOME/.claude/settings.json"
  if [ -f "$GOV" ] && command -v jq >/dev/null 2>&1; then
    ensure_backup_dir
    if [ -L "$SET" ]; then
      _c="$(cat "$SET")"; cp "$SET" "$BACKUP_DIR/settings.json.was-symlink" 2>/dev/null || true; rm "$SET"; printf '%s' "$_c" > "$SET"
      say "$c_act" "  → settings.json 심링크 해제(실파일 전환)"
    fi
    [ -f "$SET" ] || echo '{}' > "$SET"
    cp "$SET" "$BACKUP_DIR/settings.json.pre-merge" 2>/dev/null || true
    _m="$(jq -s '.[0] as $cur | .[1].hooks as $gov | $cur | .hooks = (reduce ($gov|keys[]) as $ev ((.hooks // {}); .[$ev] = (((.[$ev] // []) + $gov[$ev]) | unique_by(.hooks[0].command))))' "$SET" "$GOV" 2>/dev/null)"
    if [ -n "$_m" ] && printf '%s' "$_m" | jq -e . >/dev/null 2>&1; then
      printf '%s\n' "$_m" > "$SET"; say "$c_ok" "  settings.json 훅 병합(기존 설정 보존)"
    else
      say "$c_err" "  ✗ settings 병합 실패 — 원본 유지"
    fi
  elif [ -f "$GOV" ]; then
    say "$c_warn" "  ! jq 없음 → 훅 병합 생략 (brew install jq 후 다시 실행)"
  fi

  for dep in jq gh; do command -v "$dep" >/dev/null 2>&1 || say "$c_warn" "  ! 없는 도구: $dep  (brew install $dep)"; done
fi

echo
if [ "$STATUS" = 1 ]; then
  say "$c_ok" "점검 완료: 정상 $ok 개"
elif [ "$DRY" = 1 ]; then
  say "$c_ok" "DRY-RUN 완료: 변경예정 $changed 개 / 정상 $ok 개"
else
  say "$c_ok" "적용 완료: 변경 $changed 개 / 정상 $ok 개"
  [ -d "$BACKUP_DIR" ] && say "$c_skip" "백업: $BACKUP_DIR"
  echo
  say "$c_act" "Claude Code를 새로 켜면 스킬이 잡힙니다."
fi
