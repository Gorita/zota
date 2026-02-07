import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case capture = "캡처"
    case dailyReview = "리뷰"
    case settings = "설정"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .capture: return "square.and.pencil"
        case .dailyReview: return "doc.text.magnifyingglass"
        case .settings: return "gear"
        }
    }
}

struct ContentView: View {
    @State private var selectedItem: SidebarItem = .capture

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selectedItem) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 140, ideal: 160)
        } detail: {
            switch selectedItem {
            case .capture:
                CaptureView()
            case .dailyReview:
                DailyReviewView()
            case .settings:
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings())
}
