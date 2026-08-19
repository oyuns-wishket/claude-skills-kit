# generate-spec — 프로젝트 기획 명세 생성기

6단계 순차 프로세스를 통해 프로젝트 계획서부터 기능 명세까지의 전체 기획 문서를 마크다운으로 생성한다. 템플릿 기반 품질 강제로 일관된 수준의 산출물을 보장한다.

## Usage

```
/generate-spec                  # 스킬 시작
/generate-spec                  # 이어서 진행 (자동으로 미완료 단계 감지)
```

Or say "프로젝트 기획", "명세 작성", "spec 생성" in natural language.

## 6-Stage Pipeline

```
1. 프로젝트 계획서  →  2. 메뉴 정의  →  3. 페이지 정의  →  4. 페이지 명세  →  5. 기능 정의  →  6. 기능 명세
```

각 단계는 이전 단계의 산출물을 `depends-on`으로 참조하여 일관성을 유지한다.

| 단계 | 산출물 | 반복 단위 | 목표 토큰 |
|------|--------|----------|----------|
| 1. 프로젝트 계획서 | 프로젝트 개요, 사용자, 요구사항, 제약, 용어, 디자인 방향 | 1회 | 2,000~3,000 |
| 2. 메뉴 정의 | 메뉴 트리 + 대메뉴별 하위 메뉴 상세 | 1회 | 1,500~2,500 |
| 3. 페이지 정의 | 페이지 개요, 기능 목록, 진입/이탈, 와이어프레임 힌트 | 페이지별 | 500~800 |
| 4. 페이지 명세 | 8개 필수 섹션 (목적, 여정, 상호작용, 레이아웃, 네비게이션, 상태, 성능, 접근성) | 페이지별 | 2,500~3,500 |
| 5. 기능 정의 | 설명, 우선순위, 컴포넌트 힌트, 복잡도 | 기능별 | 300~500 |
| 6. 기능 명세 | 8 필수 + 6 조건부 섹션 (개요, US/AC, UI/UX, 데이터모델, API, 비즈니스로직, 상태관리, 에러처리 + 연관기능, 의존성, 에셋, 테스트, KPI, MVP) | 기능별 | 4,500~10,000 |

## How It Works

### Entry Flow

1. `docs/specs/` 폴더를 스캔하여 완료된 단계 감지
2. 진행 상태 표시 (체크박스 형태)
3. 사용자가 시작할 단계 선택 (기본: 첫 미완료 단계)
4. 의존 파일 없으면 경고 후 이전 단계 권유

### Stage Loop (모든 단계 공통)

1. 해당 단계의 템플릿 파일 Read
2. `depends-on` 의존 파일 Read
3. 템플릿 섹션별로 사용자와 대화하며 초안 작성
4. 초안 제시 → 피드백 → 수정 (승인까지 반복)
5. 승인 시 md 파일 저장
6. 다음 단계/항목 안내

### Quality Gate

저장 전 분량 검증:
- 페이지 명세 < 2,000 토큰 → 섹션 누락 보완 요청
- 기능 명세 < 4,000 토큰 → 보완 요청
- 기능 명세 > 12,000 토큰 → 기능 분할 검토

## Output Structure

```
docs/specs/
  01-project-plan.md
  02-menu-definition.md
  pages/
    01-notification-center.md
    02-help.md
  page-specs/
    01-notification-center/
      00-page-spec.md
    02-help/
      00-page-spec.md
  features/
    01-notification-center/
      01-notification-list-view.md
    02-help/
      01-guide-list-and-detail.md
  feature-specs/
    01-notification-center/
      01-notification-list-view.md
    02-help/
      01-guide-list-and-detail.md
```

### Naming Convention

- 번호: 2자리 zero-pad, 메뉴 정의의 sortOrder 기준
- 파일명: 영문 kebab-case (한글 메뉴명을 의미 기반 번역)
- 모든 파일에 YAML frontmatter (`title`, `stage`, `depends-on`, `created-at`, `status`)

## Installation

Copy the `generate-spec/` directory to `~/.claude/skills/`:

```
~/.claude/skills/generate-spec/
  SKILL.md
  templates/
    01-project-plan.template.md
    02-menu-definition.template.md
    03-page-definition.template.md
    04-page-spec.template.md
    05-feature-definition.template.md
    06-feature-spec.template.md
```

## File Sizes

| File | Lines | Role |
|------|-------|------|
| SKILL.md | ~160 | Entry flow, stage control, naming rules, quality gates |
| 01-project-plan.template.md | ~130 | 6-section template with writing guides |
| 02-menu-definition.template.md | ~80 | Menu tree + detail template |
| 03-page-definition.template.md | ~70 | Lightweight page overview template |
| 04-page-spec.template.md | ~180 | 8 mandatory section template |
| 05-feature-definition.template.md | ~50 | Feature definition guide |
| 06-feature-spec.template.md | ~320 | 8 mandatory + 6 conditional section template |

## Notes

- **Korean-first.** 모든 템플릿과 가이드가 한글 기반. 영문 프로젝트에도 사용 가능.
- **단계별 대화.** 자동 생성이 아닌, 사용자와 대화를 통해 각 섹션을 채워가는 방식.
- **선택적 재개.** 이미 완료된 단계를 건너뛰고 원하는 단계부터 시작 가능.
- **명시적 의존성.** frontmatter `depends-on`으로 단계 간 참조를 강제하여 일관성 유지.
