import SwiftUI

struct CaptureView: View {
    @EnvironmentObject var appSettings: AppSettings
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedTags: Set<String> = []
    @State private var saveResult: SaveResult? = nil
    @State private var isSuggestingTags = false
    @FocusState private var titleFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 제목
            TextField("제목", text: $title)
                .textFieldStyle(.plain)
                .font(.title2)
                .focused($titleFocused)

            Divider()

            // 내용
            TextEditor(text: $content)
                .font(.body)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 150)

            Divider()

            // 태그 선택
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("태그")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button(action: suggestTags) {
                        if isSuggestingTags {
                            ProgressView()
                                .controlSize(.mini)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("AI 태그 제안")
                    .disabled(isSuggestingTags || (title.isEmpty && content.isEmpty))
                }

                FlowLayout(spacing: 6) {
                    ForEach(appSettings.availableTags, id: \.self) { tag in
                        TagChip(
                            tag: tag,
                            isSelected: selectedTags.contains(tag),
                            action: { toggleTag(tag) }
                        )
                    }
                }
            }

            Spacer()

            // 하단: 저장 결과 + 버튼
            HStack {
                if let result = saveResult {
                    Label(result.message, systemImage: result.icon)
                        .font(.caption)
                        .foregroundStyle(result.isSuccess ? .green : .red)
                        .transition(.opacity)
                }

                Spacer()

                Button("저장") {
                    save()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(title.isEmpty && content.isEmpty)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { titleFocused = true }
    }

    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }

    private func suggestTags() {
        guard let vaultURL = appSettings.vaultURL else { return }
        guard !title.isEmpty || !content.isEmpty else { return }

        isSuggestingTags = true

        Task {
            do {
                let promptService = PromptService(vaultPath: vaultURL)
                let systemPrompt: String
                do {
                    systemPrompt = try promptService.loadPrompt(named: "Tagger")
                } catch {
                    systemPrompt = defaultTaggerPrompt
                }

                let userPrompt = TagSuggestionResult.buildPrompt(
                    title: title,
                    content: content,
                    availableTags: appSettings.availableTags
                )

                guard let baseURL = URL(string: appSettings.ollamaURL) else { return }

                let ollamaService = OllamaService(
                    baseURL: baseURL,
                    model: appSettings.ollamaModel
                )

                let result = try await ollamaService.generate(
                    prompt: userPrompt,
                    system: systemPrompt,
                    responseType: TagSuggestionResult.self,
                    timeout: 30
                )

                await MainActor.run {
                    let validTags = result.filteredTags(allowedTags: appSettings.availableTags)
                    for tag in validTags {
                        selectedTags.insert(tag)
                    }
                    isSuggestingTags = false
                }
            } catch {
                await MainActor.run {
                    isSuggestingTags = false
                }
            }
        }
    }

    private func save() {
        guard let vaultURL = appSettings.vaultURL else {
            saveResult = SaveResult(isSuccess: false, message: "Vault 경로가 설정되지 않았습니다")
            return
        }

        let noteTitle = title.isEmpty ? "메모" : title
        let noteContent = content.isEmpty ? "" : content

        let service = VaultService(vaultPath: vaultURL)

        do {
            let filePath = try service.createNote(
                title: noteTitle,
                content: noteContent,
                tags: Array(selectedTags)
            )
            let filename = filePath.lastPathComponent
            saveResult = SaveResult(isSuccess: true, message: "Inbox/\(filename) 저장됨")

            // 필드 초기화
            title = ""
            content = ""
            selectedTags = []
            titleFocused = true

            // 3초 후 결과 메시지 숨기기
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { saveResult = nil }
            }
        } catch {
            saveResult = SaveResult(isSuccess: false, message: error.localizedDescription)
        }
    }
}

// MARK: - 태그 칩 컴포넌트

struct TagChip: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 저장 결과

struct SaveResult {
    let isSuccess: Bool
    let message: String

    var icon: String {
        isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill"
    }
}

// MARK: - FlowLayout (태그 칩 줄바꿈 레이아웃)

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxX = max(maxX, currentX)
        }

        return (positions, CGSize(width: maxX, height: currentY + rowHeight))
    }
}

// MARK: - 기본 Tagger 프롬프트

private let defaultTaggerPrompt = """
You are a tag suggestion assistant. Given a note's title and content, suggest the most relevant tags from the provided allowed tag list.

Rules:
- Select 1-3 tags that best describe the note
- Only return tags from the allowed list
- If no tags fit, return empty array

Output strictly in JSON: {"tags": ["태그1", "태그2"]}
"""

#Preview {
    CaptureView()
        .environmentObject(AppSettings())
        .frame(width: 500, height: 400)
}
