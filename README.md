# Zota

Obsidian Vault 메모를 로컬 LLM으로 자동 정리하는 macOS 앱

## 주요 기능

**빠른 캡처** — 제목, 내용, 태그를 입력하면 Vault의 `Inbox/` 폴더에 마크다운 파일로 저장한다. `⌘+Return`으로 빠르게 저장 가능.

**AI 태그 제안** — 메모 내용을 기반으로 Ollama가 적절한 태그를 추천한다. 허용된 태그 목록 내에서만 제안하므로 안전하다.

**데일리 리뷰** — 오늘의 메모를 수집하고, LLM이 성과/아이디어/할 일로 분류하여 한줄 요약과 함께 데일리 노트에 기록한다.

## 요구사항

- macOS 14 (Sonoma) 이상
- [Ollama](https://ollama.com) 설치 및 실행
- Obsidian Vault (로컬 마크다운 폴더)

## 설치

```bash
# 1. 저장소 클론
git clone https://github.com/your-username/zota.git
cd zota

# 2. Xcode 프로젝트 생성 (xcodegen 필요)
brew install xcodegen
cd Zota && xcodegen generate

# 3. Xcode에서 빌드
open Zota.xcodeproj
# ⌘+R로 실행
```

## Ollama 준비

```bash
# Ollama 설치 후 모델 다운로드
ollama pull llama3

# 서버 실행 확인
curl http://localhost:11434
```

## 앱 설정

앱을 실행하면 사이드바에 **캡처**, **리뷰**, **설정** 3개 탭이 있다.

**설정** 탭에서 먼저 아래 항목을 설정한다:

| 항목 | 설명 | 기본값 |
|------|------|--------|
| Vault 경로 | Obsidian Vault 폴더 선택 | - |
| Ollama URL | Ollama 서버 주소 | `http://localhost:11434` |
| 모델 | 사용할 LLM 모델 | `llama3` |
| 태그 목록 | 캡처 시 선택 가능한 태그 (쉼표 구분) | 개발, 디자인, 업무, 학습, ... |

## 사용법

### 빠른 캡처

1. **캡처** 탭에서 제목과 내용을 입력
2. 태그를 선택하거나 ✨ 버튼으로 AI 태그 제안을 받음
3. **저장** (또는 `⌘+Return`)을 누르면 `Vault/Inbox/YYYY-MM-DD-제목.md`로 저장

### 데일리 리뷰

1. **리뷰** 탭에서 날짜를 선택
2. 해당 날짜의 데일리 노트(`Vault/Daily/YYYY-MM-DD.md`)에서 메모 항목을 로딩
3. **AI 리뷰 생성** 버튼을 누르면 Ollama가 메모를 분석
4. 미리보기를 확인하고 **데일리 노트에 저장**

## Vault 구조

Zota는 Vault 내 아래 폴더를 사용한다:

```
Vault/
├── Inbox/          # 캡처된 메모가 저장되는 폴더
├── Daily/          # 데일리 노트 (YYYY-MM-DD.md)
└── System/
    └── Prompts/    # LLM 프롬프트 (커스터마이징 가능)
        ├── DailySummary.md
        └── Tagger.md
```

## 프롬프트 커스터마이징

`prompts/` 폴더의 기본 프롬프트 파일을 Vault의 `System/Prompts/`에 복사하면 앱 업데이트 없이 프롬프트를 수정할 수 있다. Vault에 프롬프트 파일이 없으면 앱 내장 기본값을 사용한다.

## 테스트

```bash
cd Zota
xcodebuild test -scheme Zota -destination 'platform=macOS'
```

## 기술 스택

- Swift + SwiftUI (macOS 네이티브)
- Ollama REST API (로컬 LLM)
- XCTest (33개 테스트)
- xcodegen (프로젝트 관리)
