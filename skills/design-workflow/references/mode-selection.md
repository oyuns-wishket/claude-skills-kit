# Mode selection

## Decision table

| 사용자 요청·프로젝트 상태 | 모드 | 기본 범위 | 하지 않는 것 |
|---|---|---|---|
| 새 제품, 신규 랜딩, 빈 화면 | `new` | 제품 맥락, 디자인 언어, 토큰, 첫 대표 화면 | 모든 페이지 동시 제작 |
| 로고·색·서체·톤을 새 브랜드로 교체 | `rebrand` | 브랜드 정본과 단계별 화면 전환 | 기능·데이터 모델 재작성 |
| 낡거나 제네릭한 UI를 개선 | `refactor` | 정보 위계, layout, component, responsive | 승인 없는 브랜드 전환 |
| 메뉴·탭·모달·폼·한 화면 추가 | `small-feature` | 인접 UI 패턴을 복제한 최소 diff | 전역 palette·typography 변경 |
| 문제와 개선안만 요청 | `audit` | 읽기, 캡처, finding과 우선순위 | 파일 수정, 설치, issue/commit |

## Ambiguous cases

- "대시보드 예쁘게": 기존 브랜드가 있으면 `refactor`, 없고 새 제품이면 `new`.
- "메뉴 추가하면서 전반적으로 정리": 먼저 `small-feature`; 전반 정리는 별도 `refactor` 제안.
- "브랜드 컬러만 바꿔": token 영향 범위를 확인한다. 전체 인상을 바꾸려는 목적이면 `rebrand`, 지정 토큰 치환이면 좁은 refactor.
- "레퍼런스처럼 만들어": 기능·콘텐츠 구조가 같지 않으면 시각 요소만 분해해 채택한다. 복제 요청으로 해석하지 않는다.
- "모바일 화면도": 별도 제품이 아니라 기존 범위의 responsive acceptance criterion으로 포함한다.

## Scope guards

### New

- 첫 대표 화면과 공통 토큰으로 방향을 검증한 뒤 확장한다.
- `PRODUCT.md`와 `DESIGN.md` 없이 구현부터 시작하지 않는다.

### Rebrand

- 브랜드 자산, legal name, 로고 사용 규칙을 사용자 제공 또는 공식 자료로 확인한다.
- old/new token mapping과 rollout 순서를 남긴다.
- 모든 화면을 한 번에 바꾸기보다 shell 또는 대표 flow에서 승인받는다.

### Refactor

- 사용자 flow, route, API, analytics event, permission을 acceptance criterion에 보존 대상으로 적는다.
- DOM 구조 변경이 테스트나 접근성에 미치는 영향을 확인한다.

### Small feature

- 인접 화면 2개 이상에서 typography, spacing, color, radius, state pattern을 추출한다.
- 새 token은 기존 token으로 표현할 수 없을 때만 추가한다.
- 공통 component 변경은 해당 메뉴 밖 영향 범위를 캡처하고 검증한다.

### Audit

- 심각도보다 사용자 영향과 수정 비용을 함께 표시한다.
- 자동 finding, 직접 관찰, 추론을 구분한다.
