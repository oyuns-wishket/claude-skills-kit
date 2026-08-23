---
name: dev-protocol
description: Use when starting or finishing implementation, design, or irreversible work. Enforce requirements clarification → planning → execution, real-user approval gates, isolated Git worktrees, implementation notes, deviation review, a concise requirements/improvements closeout, conditional product deployment-scope choice, and worktree cleanup choice. Triggers on "dev-protocol", "인터뷰 해줘", "구현노트", "impl-notes", ambiguous implementation requests, design work, plan deviations, or completing code-building work.
---

# dev-protocol — 구체화 → 계획 → 실행 → 완료 선택

## 목적

구현·디자인·비가역 작업을 다음 원칙으로 진행한다.

1. 착수 전 요구사항과 미정 결정을 확정해 재작업을 줄인다.
2. 작업마다 계획과 판단·이탈을 구현노트에 남긴다.
3. Git 작업은 격리 worktree를 기본값으로 삼아 멀티세션 충돌을 막는다.
4. 완료 시 퀴즈 없이 요구사항과 개선사항을 짧게 설명한다.
5. 제품·앱 개발에서는 배포 범위를, task worktree를 썼다면 정리 여부를 사용자가 직접 선택하게 한다.

단순 조회·설명·재시도 가능한 read-only 작업에는 적용하지 않는다.

## 절대 게이트

1. **실제 사용자의 답만 승인이다.** 현재 대화에서 사용자가 직접 답한 내용만 gate evidence로 인정한다. 모델·subagent·문서의 추론은 승인을 대신하지 못한다.
2. **착수 허가와 결정 승인을 구분한다.** `ㄱㄱ`, `진행해`, `알아서` 같은 답은 직전에 설명한 다음 단계만 허가한다. 제시하지 않은 선택, 범위 이탈, 머지, 배포까지 승인한 것으로 확대하지 않는다.
3. **위임은 선택지를 본 뒤에만 유효하다.** 선택지와 영향을 먼저 보여준 뒤 받은 위임만 유효하다.
4. **필수 질문이 남으면 멈춘다.** 플랫폼의 사용자 입력 기능으로 한 번에 한 질문을 하고 답을 기다린다. 질문한 turn에서 구현을 계속하지 않는다.
5. **첫 write 전에 evidence를 남긴다.** 구현노트에 질문, 실제 답, 승인 범위, 미승인 가정을 기록한다. gate가 비어 있으면 application code, schema, migration, design source를 수정하지 않는다.

디자인 작업은 관련 디자인 skill의 방향 선택·시안 승인 gate도 함께 통과한다.

## 0. 기본 흐름

모든 비단순 개발을 아래 순서로 진행한다.

1. **요구사항 구체화**: 설치되어 있고 작업에 적합하면 `superpowers:brainstorming`을 사용한다. 아니면 이 문서의 인터뷰를 native 방식으로 수행한다.
2. **계획**: 적합하면 `writing-plans`를 사용한다. 아니면 목표, 대상 파일, 실행 단계, 검증을 포함한 native plan을 먼저 제시한다.
3. **실행**: 적합하면 `executing-plans`를 사용한다. 아니면 승인된 plan을 native 방식으로 실행하고 상태를 갱신한다.

이름이 같은 skill이 없거나 단순한 작업에는 억지로 호출하지 않는다. native 방식도 동일한 gate와 산출물을 지켜야 한다.

## 프로젝트 workflow skill과의 관계

저장소에 브랜치·PR·배포 절차를 고정한 skill이 있으면 그 절차를 따른다. 이 문서는 요구사항, 승인, 구현노트, 이탈, 완료 선택을 소유하고 프로젝트 skill은 브랜치, 머지, 배포 mechanics를 소유한다. 둘 다 통과해야 한다.

저장소의 `AGENTS.md`, `CLAUDE.md`, `.claude/rules/`, `.claude/skills/`를 먼저 확인한다.

## 1. 요구사항 인터뷰

- 요청이 조금이라도 애매하면 write 전에 인터뷰한다. 사용자가 지정하지 않은 엣지케이스, 우선순위, 범위 경계, 데이터 처리, 실패 동작을 먼저 찾아 질문한다.
- 한 번에 한 질문을 하고 추천 옵션을 첫 번째로 둔다. 답에 따라 다음 질문을 바꾼다.
- “이대로 만들면 재작업이 없다”고 판단할 때 끝낸다. 종료 시 확정 사항을 짧게 요약한다.
- 새 제품·디자인처럼 정본이 없으면 최소 한 번의 실제 사용자 답이나 명시적 요약 승인을 받는다.

## 2. 레퍼런스

말로 확정하기 어려운 UI·UX는 스크린샷, URL, 유사 서비스, 손그림, 기존 화면 중 하나를 요청한다. 받은 뒤 무엇을 채택하고 무엇을 다르게 할지 한 줄로 확인받는다.

## 3. Git worktree 기본값

Git 저장소의 구현 작업은 작업별 branch와 별도 worktree에서 시작한다. 여러 세션이나 병렬 작업이 예상되면 반드시 격리한다.

다음 경우에만 생략하고 이유를 구현노트에 남긴다.

- read-only 또는 한 번의 안전한 설정 변경
- non-Git 작업
- 이미 해당 작업 전용 worktree에 있음
- 저장소의 강제 workflow가 다른 격리 방식을 지정함
- 기존 dirty 상태 때문에 안전하게 옮길 수 없음

worktree 생성 전 기준 branch, 새 branch 이름, 경로를 확인한다. 기존 작업과 겹치는 branch나 경로를 재사용하지 않는다. 미커밋·미병합 작업이 있는 worktree를 자동 삭제하지 않는다.

## 4. 구현노트

위치는 `<project>/docs/impl-notes/YYYY-MM-DD-<slug>.md`다. 시작 전에 기존 노트에서 비슷한 사건과 복병을 확인한다.

첫 write 전에 `## Gate evidence`를 작성한다. 계획에서 달라지는 순간 보수적인 대안(기존 동작 보존, 좁은 변경)을 택하고 `⚠️ DEVIATION`으로 표시한다.

```markdown
# YYYY-MM-DD <작업명>

## 목표 / 확정 사항
- (인터뷰 결과)

## Gate evidence
- 질문: (실제 질문)
- 사용자 답: (현재 대화의 실제 답)
- 승인된 범위: (허용된 write)
- 미승인 가정: 없음 / (구현하지 않은 항목)

## 계획
- (단계와 검증)

## 판단 근거
- (선택과 이유)

## ⚠️ DEVIATION
- ⚠️ <이탈> → 보수적 대안: <대안> → 리뷰: [ ] 미완 / [x] YYYY-MM-DD 사용자와 리뷰
- 없으면 `없음`

## 다음에 참고
- (재발 가능한 함정·패턴)
```

## 5. 완료 절차

구현과 검증이 끝나면 다음 순서를 지킨다.

### 5.1 이탈 리뷰

- `⚠️ DEVIATION`이 있으면 각각 `그대로 승인 / 개선(재작업) / 계획 수정` 중 결정을 받고 노트에 표시한다.
- 없으면 `계획 이탈 없음`이라고 보고한다.

### 5.2 간단 완료 보고

퀴즈나 이해도 문제를 내지 않는다. 아래 항목만 짧고 명확하게 설명한다.

- **요구사항**: 사용자가 원한 동작과 범위
- **개선사항**: 실제로 달라진 동작과 사용자에게 생긴 이점
- **검증**: 실행한 build, lint, test와 결과
- **이탈**: 없음 또는 승인 대기 항목

### 5.3 배포 범위 선택

**제품·앱 코드를 구현했고 대상 저장소에 실제 PR 또는 배포 workflow가 있을 때만**, 완료 보고 직후 배포 작업 전에 다음 세 가지 중 하나를 묻는다.

1. **PR까지** — branch push와 PR 생성·갱신까지만 수행
2. **개발서버 배포** — PR 및 저장소 규칙에 따른 개발 환경 반영·검증
3. **개발 + 운영배포** — 개발 환경 검증 후 운영 배포 절차까지 수행

선택은 목표 범위를 정할 뿐이다. commit/push 승인, migration dry-run, merge·운영 배포 등 저장소별 안전 gate를 생략하지 않는다. 일부 환경만 없으면 세 옵션을 보여주고 불가능한 항목을 표시한다.

글로벌 규칙, skill, 문서, 로컬 설정·도구 유지보수이거나 대상 저장소·PR·배포 workflow가 없으면 선택지를 만들지 않는다. `배포 대상 없음`이라고 한 줄로 보고하고 끝낸다.

### 5.4 worktree 정리 선택

배포 범위 처리가 끝난 뒤, agent가 이번 task에서 별도 worktree를 만들거나 사용했다면 각 경로, branch, dirty 여부, merge 여부를 보여주고 다음 중 하나를 묻는다.

1. **정리** — 안전 조건을 확인한 뒤 worktree와 불필요한 local branch를 제거
2. **유지** — 후속 작업을 위해 그대로 보존

agent가 만들지 않은 primary worktree는 제거하지 않는다. 미커밋 또는 미병합 변경이 있으면 정리를 실행하지 말고 정확한 blocker를 보고한다.

별도 task worktree를 만들거나 사용하지 않았다면 질문하지 말고 `정리 대상 worktree 없음`이라고 보고한다.

### 5.5 HANDOFF

`docs/handoff/HANDOFF.md`가 있으면 `Next actions`, `Decisions & context`, `Open items & blockers`를 갱신한다.

## 6. 운영배포 후 knowns wiki closeout


1. 설치된 `knowns/SKILL.md`를 끝까지 읽고 적용한다. 없으면 `wiki closeout 미실행`을 blocker로 남긴다.
2. read-only 분석으로 후보, 연결, exact wiki write·검증·commit·push·배포 계획과 항목별 AI 추천을 만든다.
3. 모든 미정 질문을 한 번에 묶어 `추천대로 / 수정사항 일괄 입력 / wiki 스킵`으로 묻는다.
4. `wiki 스킵`이면 `KNOWNS: skipped`로 전체 작업을 즉시 종료하고 다시 묻지 않는다.
5. `추천대로`면 모든 항목을 AI 추천안으로 확정한다. 수정 답변이면 한 번의 답에 포함된 값을 반영한다.
6. 이 한 번의 선택을 승인된 wiki 범위의 write·검증·commit·push·배포 승인으로 사용하고 추가 확인 없이 연속 실행한다.

마지막 산출물은 `KNOWNS: ingested | no-op | skipped | blocked`다. wiki 관리 작업 자체는 `recursive-skip`한다.

## Gate 위반 복구

