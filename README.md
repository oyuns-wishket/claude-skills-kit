# claude-skills-kit

Claude Code와 Codex CLI에서 **똑같이 동작하는** 개발 워크플로 스킬 모음이다.
한 번 설치하면 두 에이전트가 같은 규칙과 같은 스킬을 읽는다.

스킬은 "AI에게 매번 설명하던 절차"를 파일로 고정한 것이다. 예를 들어 `dev-protocol`을 깔면,
AI가 애매한 요청에 멋대로 짐작하고 코드를 갈아엎는 대신 **먼저 질문하고, 결정을 기록하고,
끝나고 나서 뭘 바꿨는지 설명**하게 된다.

---

## 설치 (2단계)

터미널에 그대로 붙여넣으면 된다.

```bash
git clone https://github.com/oyuns-wishket/claude-skills-kit.git ~/claude-skills-kit
cd ~/claude-skills-kit && ./bootstrap.sh
```

끝이다. Claude Code를 새로 켜면 스킬이 잡힌다.

**설치 전에 뭐가 바뀌는지 보고 싶다면:**

```bash
./bootstrap.sh --dry-run
```

실제로는 아무것도 바꾸지 않고 "무엇을 할 예정인지"만 출력한다.

**이미 쓰던 설정이 있어도 안전하다.** bootstrap은 기존 파일을 지우지 않고
`~/.claude/backups/` 아래로 백업한 뒤 링크를 건다. 여러 번 돌려도 결과가 같다(멱등).

---

## 업데이트

```bash
cd ~/claude-skills-kit && ./bootstrap.sh --pull
```

`--pull`은 최신 내용을 받아온 뒤 다시 적용한다.

## 상태 점검

```bash
./bootstrap.sh --status
```

무엇이 연결됐고 무엇이 안 됐는지만 보여준다. 변경은 하지 않는다.

---

## 들어 있는 스킬

| 스킬 | 언제 쓰나 | 무엇을 해주나 |
|---|---|---|
| `dev-protocol` | 코드를 쓰거나 고칠 때 (거의 항상) | 착수 전 인터뷰 → 구현 노트 기록 → 계획 이탈 검토 → 끝나고 이해도 퀴즈. **가장 먼저 켜볼 스킬.** |
| `generate-spec` | "뭘 만들지"부터 정해야 할 때 | 기획 → 메뉴 정의 → 페이지 정의 → 기능 명세까지 6단계, 템플릿 7종 포함 |
| `feature-flow` | git + Supabase + Vercel 프로젝트 | 브랜치 하나당 격리된 DB + preview URL을 만들어 운영을 안 건드리고 개발 |
| `design-workflow` | UI 만들거나 갈아엎을 때 | 제품 인터뷰 → 디자인 방향 → 시안 3개 승인 → 그 다음에야 코드 수정 |
| `multi-agent-dev` | 작업이 커서 혼자 돌리기 벅찰 때 | 작업을 쪼개 워커에게 분배, 워커마다 격리된 git worktree에서 작업 |
| `ssotify` | 반복하는 절차를 굳히고 싶을 때 | 질의응답으로 내용을 끌어내 새 스킬 파일을 만들어 준다 |
| `paseo-setup` | Paseo worktree를 쓰는 레포 | 스택을 분석해 `paseo.json`을 생성 |

전부 다 쓸 필요는 없다. `dev-protocol` 하나만 써도 체감이 크다.

---

## 글로벌 규칙도 같이 깔린다

`global/CLAUDE.md`에는 "한국어로 대화한다", "커밋 전에 확인받는다",
"build/lint 통과를 실제로 측정하기 전엔 완료라고 말하지 않는다" 같은 공통 규칙이 들어 있다.
bootstrap이 이걸 `~/.claude/CLAUDE.md`에 **마커로 감싼 `@import` 한 줄**로 주입하고,
Codex에는 `~/.codex/AGENTS.md`로 링크한다.

기존 `~/.claude/CLAUDE.md` 내용은 지우지 않는다. 마커 블록만 갱신된다.

마음에 안 드는 규칙은 `global/CLAUDE.md`를 직접 고치면 즉시 반영된다(링크라서 재실행 불필요).

---

## 훅(hook)

`hooks/` 아래 셸 스크립트가 `~/.claude/hooks/`로 복사되고,
`global/governance-hooks.json`이 기존 `settings.json`에 **병합**된다(통째 교체 아님).

| 훅 | 하는 일 |
|---|---|
| `block-dangerous.sh` | 위험한 명령(`rm -rf /` 류)을 실행 전에 차단 |
| `pre-tool.sh` / `post-tool.sh` | 작업 전후 컨텍스트 주입 |
| `session-start.sh` / `session-context.sh` | 세션 시작 시 프로젝트 상태 요약 |
| `handoff-sync.sh` | 세션 종료 시 HANDOFF 문서 갱신 |

훅이 부담스러우면 `~/.claude/settings.json`의 `hooks` 항목에서 지우면 된다.

---

## 필요한 것

| 도구 | 필수 여부 | 설치 |
|---|---|---|
| `git` | 필수 | macOS 기본 포함 |
| `node` | 필수 (manifest 파싱) | `brew install node` |
| `jq` | 권장 (settings 병합) | `brew install jq` |
| `gh` | 선택 (GitHub 연동 스킬) | `brew install gh` |
| `coreutils` | 선택 (`gtimeout`) | `brew install coreutils` |

`node`나 `jq`가 없으면 bootstrap이 어디서 막혔는지 알려준다.

---

## 되돌리기

```bash
ls ~/.claude/backups/          # 설치 시 백업된 원본
```

링크만 지우려면:

```bash
rm ~/.codex/AGENTS.md
rm ~/.claude/skills/dev-protocol   # 필요한 것만 골라서
```

`~/.claude/CLAUDE.md`의 `<!-- BEGIN AGENT-RULES (auto) -->` ~ `<!-- END ... -->` 블록을 지우면
글로벌 규칙 주입도 해제된다.

---

## 구조

```
.
├── bootstrap.sh          # 설치·동기화 (멱등)
├── manifest.json         # 무엇을 어디로 링크할지
├── global/
│   ├── CLAUDE.md             # 공통 작업 규칙
│   └── governance-hooks.json # settings.json에 병합될 훅 정의
├── hooks/                # ~/.claude/hooks/ 로 복사되는 셸 훅
├── skills/               # 스킬 본체 (양쪽 에이전트가 이걸 읽는다)
└── templates/            # 프로젝트에 복사해 쓰는 문서 템플릿
```
