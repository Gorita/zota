import SwiftUI

struct DailyReviewView: View {
    @EnvironmentObject var appSettings: AppSettings
    @State private var selectedDate: Date = Date()
    @State private var memos: [String] = []
    @State private var reviewResult: DailyReviewResult? = nil
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var saveMessage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 상단: 날짜 선택
            HStack {
                Text("데일리 리뷰")
                    .font(.title2)

                Spacer()

                Button(action: { moveDate(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)

                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.field)

                Button(action: { moveDate(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
            }

            Divider()

            if memos.isEmpty && reviewResult == nil && !isLoading {
                // 메모가 없을 때
                VStack(spacing: 8) {
                    Text("이 날짜의 메모가 없습니다")
                        .foregroundStyle(.secondary)
                    Text("데일리 노트의 ## Memos 섹션에 메모를 작성하세요")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // 메모 목록
                        if !memos.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("오늘의 메모 (\(memos.count)건)")
                                    .font(.headline)

                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(memos, id: \.self) { memo in
                                        HStack(alignment: .top, spacing: 6) {
                                            Text("•")
                                                .foregroundStyle(.secondary)
                                            Text(memo)
                                        }
                                        .font(.body)
                                    }
                                }
                                .padding(12)
                                .background(Color.secondary.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }

                        // AI 리뷰 생성 버튼
                        if reviewResult == nil && !memos.isEmpty {
                            HStack {
                                Spacer()
                                Button(action: generateReview) {
                                    if isLoading {
                                        ProgressView()
                                            .controlSize(.small)
                                            .padding(.trailing, 4)
                                        Text("AI 리뷰 생성 중...")
                                    } else {
                                        Image(systemName: "sparkles")
                                        Text("AI 리뷰 생성")
                                    }
                                }
                                .disabled(isLoading)
                                Spacer()
                            }
                        }

                        // 에러 메시지
                        if let error = errorMessage {
                            Label(error, systemImage: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        // AI 생성 결과
                        if let result = reviewResult {
                            Divider()

                            Text("AI 생성 결과")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            ReviewResultView(result: result)

                            // 저장 버튼
                            HStack {
                                if let msg = saveMessage {
                                    Label(msg, systemImage: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }

                                Spacer()

                                Button("데일리 노트에 저장") {
                                    saveReview()
                                }
                                .keyboardShortcut(.return, modifiers: .command)

                                Button("다시 생성") {
                                    reviewResult = nil
                                    errorMessage = nil
                                    generateReview()
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onChange(of: selectedDate) { _, _ in
            loadMemos()
            reviewResult = nil
            saveMessage = nil
            errorMessage = nil
        }
        .onAppear { loadMemos() }
    }

    private func moveDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
        }
    }

    private func loadMemos() {
        guard let vaultURL = appSettings.vaultURL else {
            memos = []
            return
        }

        let service = VaultService(vaultPath: vaultURL)
        do {
            memos = try service.extractMemos(from: selectedDate)
        } catch {
            memos = []
            errorMessage = error.localizedDescription
        }
    }

    private func generateReview() {
        guard let vaultURL = appSettings.vaultURL else {
            errorMessage = "Vault 경로가 설정되지 않았습니다"
            return
        }

        guard !memos.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                // 프롬프트 로딩
                let promptService = PromptService(vaultPath: vaultURL)
                let systemPrompt: String
                do {
                    systemPrompt = try promptService.loadPrompt(named: "DailySummary")
                } catch {
                    // 프롬프트 파일이 없으면 기본 프롬프트 사용
                    systemPrompt = defaultDailySummaryPrompt
                }

                // 메모를 프롬프트에 포함
                let memosText = memos.map { "- \($0)" }.joined(separator: "\n")
                let userPrompt = "다음 메모들을 분석해줘:\n\n\(memosText)"

                // Ollama API 호출
                guard let baseURL = URL(string: appSettings.ollamaURL) else {
                    throw ZotaError.ollamaNotRunning
                }

                let ollamaService = OllamaService(
                    baseURL: baseURL,
                    model: appSettings.ollamaModel
                )

                let result = try await ollamaService.generate(
                    prompt: userPrompt,
                    system: systemPrompt,
                    responseType: DailyReviewResult.self,
                    timeout: 60
                )

                await MainActor.run {
                    reviewResult = result
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func saveReview() {
        guard let vaultURL = appSettings.vaultURL,
              let result = reviewResult else { return }

        let service = VaultService(vaultPath: vaultURL)
        do {
            try service.updateDailyReview(for: selectedDate, reviewContent: result.toMarkdown())
            saveMessage = "데일리 노트에 저장됨"

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { saveMessage = nil }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - 리뷰 결과 표시 뷰

struct ReviewResultView: View {
    let result: DailyReviewResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !result.achievements.isEmpty {
                SectionView(title: "오늘의 성과", icon: "checkmark.circle", items: result.achievements)
            }

            if !result.ideas.isEmpty {
                SectionView(title: "아이디어", icon: "lightbulb", items: result.ideas)
            }

            if !result.todos.isEmpty {
                SectionView(title: "할 일", icon: "checklist", items: result.todos)
            }

            // 한줄 요약
            HStack(alignment: .top, spacing: 4) {
                Image(systemName: "quote.opening")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Text(result.summary)
                    .italic()
                    .foregroundStyle(.secondary)
            }
            .padding(8)
            .background(Color.accentColor.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}

struct SectionView: View {
    let title: String
    let icon: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 6) {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(item)
                }
                .font(.body)
                .padding(.leading, 4)
            }
        }
    }
}

// MARK: - 기본 프롬프트

private let defaultDailySummaryPrompt = """
You are a personal assistant that organizes daily memos.

Given a list of memo items from today, organize them into these categories:
- **achievements**: Things completed or progress made
- **ideas**: New ideas, insights, or things to explore
- **todos**: Action items or tasks to do

Also provide a one-sentence summary of the day in Korean.

Output strictly in JSON format:
{
  "achievements": ["achievement 1", "achievement 2"],
  "ideas": ["idea 1"],
  "todos": ["todo 1", "todo 2"],
  "summary": "한국어로 오늘 하루 한줄 요약"
}
"""

#Preview {
    DailyReviewView()
        .environmentObject(AppSettings())
        .frame(width: 500, height: 600)
}
