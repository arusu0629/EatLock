//
//  LogListView.swift
//  EatLock
//
//  Created by AI Assistant on 2025/07/03.
//

import SwiftUI

struct LogListView: View {
    let actionLogs: [ActionLog]
    let repository: ActionLogRepository
    let onDelete: (IndexSet) -> Void
    private let router = NavigationRouter.shared
    
    // MARK: - Search and Filter States
    
    @State private var searchText = ""
    @State private var selectedLogType: LogType? = nil
    @State private var selectedDateRange: DateRange = .all
    @State private var isFilterExpanded = false
    @State private var cachedFilteredLogs: [ActionLog] = []
    @State private var isFilteringInProgress = false
    
    private let searchDebouncer = Debouncer(delay: 0.3)
    
    // MARK: - Computed Properties
    
    // 検索・フィルタリング後のログ（キャッシュ対応）
    private var filteredLogs: [ActionLog] {
        if isFilteringInProgress {
            return cachedFilteredLogs
        }
        return cachedFilteredLogs.isEmpty ? actionLogs : cachedFilteredLogs
    }
    
    private func triggerFilterUpdate() {
        guard !isFilteringInProgress else { return }
        
        isFilteringInProgress = true
        
        Task.detached(priority: .userInitiated) {
            let filtered = await performFiltering()
            
            await MainActor.run {
                self.cachedFilteredLogs = filtered
                self.isFilteringInProgress = false
            }
        }
    }
    
    private func performFiltering() async -> [ActionLog] {
        var filtered = actionLogs
        
        // テキスト検索（並列処理、バッチサイズ制限）
        if !searchText.isEmpty {
            let maxConcurrency = min(filtered.count, 8) // 最大8並列に制限
            
            let searchResults = await withTaskGroup(of: (ActionLog, Bool).self, returning: [ActionLog].self) { group in
                var results: [ActionLog] = []
                var iterator = filtered.makeIterator()
                var activeTasks = 0
                
                // 初期タスクを追加
                while activeTasks < maxConcurrency, let log = iterator.next() {
                    group.addTask {
                        let content = repository.getSecureContent(for: log)
                        let feedback = repository.getSecureAIFeedback(for: log) ?? ""
                        let matches = content.localizedCaseInsensitiveContains(searchText) ||
                                     feedback.localizedCaseInsensitiveContains(searchText) ||
                                     log.emotionTags.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
                        return (log, matches)
                    }
                    activeTasks += 1
                }
                
                // 結果を処理し、新しいタスクを追加
                for await (log, matches) in group {
                    if matches {
                        results.append(log)
                    }
                    
                    // 次のタスクを追加
                    if let nextLog = iterator.next() {
                        group.addTask {
                            let content = repository.getSecureContent(for: nextLog)
                            let feedback = repository.getSecureAIFeedback(for: nextLog) ?? ""
                            let matches = content.localizedCaseInsensitiveContains(searchText) ||
                                         feedback.localizedCaseInsensitiveContains(searchText) ||
                                         nextLog.emotionTags.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
                            return (nextLog, matches)
                        }
                    }
                }
                
                return results
            }
            filtered = searchResults
        }
        
        // ログタイプフィルタ
        if let selectedLogType = selectedLogType {
            filtered = filtered.filter { $0.logType == selectedLogType }
        }
        
        // 日付フィルタ
        switch selectedDateRange {
        case .today:
            filtered = filtered.filter { Calendar.current.isDateInToday($0.timestamp) }
        case .thisWeek:
            filtered = filtered.filter { Calendar.current.isDate($0.timestamp, equalTo: Date(), toGranularity: .weekOfYear) }
        case .thisMonth:
            filtered = filtered.filter { Calendar.current.isDate($0.timestamp, equalTo: Date(), toGranularity: .month) }
        case .all:
            break
        }
        
        return filtered
    }
    
    // 日付でグループ化されたログ
    private var groupedLogs: [(date: Date, logs: [ActionLog])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredLogs) { log in
            calendar.startOfDay(for: log.timestamp)
        }
        
        return grouped.map { (key, value) in
            (date: key, logs: value.sorted { $0.timestamp > $1.timestamp })
        }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 検索バー
            searchBarSection
            
            // フィルタセクション
            if isFilterExpanded {
                filterSection
            }
            
            // ログ一覧
            if filteredLogs.isEmpty {
                emptyStateView
            } else {
                logListView
            }
        }
    }
    
    // MARK: - Search Bar Section
    
    private var searchBarSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("記録内容、AIフィードバック、感情タグから検索...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isFilterExpanded.toggle()
                    }
                }) {
                    Image(systemName: isFilterExpanded ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                .accessibilityLabel("フィルタ設定")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // 検索結果の概要
            if !searchText.isEmpty || selectedLogType != nil || selectedDateRange != .all {
                HStack {
                    Text("\(filteredLogs.count)件の記録")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if !searchText.isEmpty || selectedLogType != nil || selectedDateRange != .all {
                        Button("クリア") {
                            searchText = ""
                            selectedLogType = nil
                            selectedDateRange = .all
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        VStack(spacing: 12) {
            // ログタイプフィルタ
            VStack(alignment: .leading, spacing: 8) {
                Text("記録タイプ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            title: "すべて",
                            isSelected: selectedLogType == nil,
                            action: { selectedLogType = nil }
                        )
                        
                        ForEach(LogType.allCases, id: \.self) { logType in
                            FilterChip(
                                title: "\(logType.emoji) \(logType.displayName)",
                                isSelected: selectedLogType == logType,
                                action: { selectedLogType = logType }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // 日付フィルタ
            VStack(alignment: .leading, spacing: 8) {
                Text("期間")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(DateRange.allCases, id: \.self) { range in
                            FilterChip(
                                title: range.displayName,
                                isSelected: selectedDateRange == range,
                                action: { selectedDateRange = range }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "doc.text" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty ? "まだログがありません" : "検索結果が見つかりません")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty ? "下の入力欄から行動ログを記録してみましょう" : "検索条件を変更して再度お試しください")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 200)
        .accessibilityLabel(searchText.isEmpty ? "行動ログが空です。下の入力欄から記録を開始してください。" : "検索結果がありません。条件を変更してください。")
    }
    
    // MARK: - Log List View
    
    private var logListView: some View {
        List {
            ForEach(groupedLogs, id: \.date) { group in
                Section {
                    ForEach(group.logs) { log in
                        ActionLogRow(log: log, repository: repository)
                            .onTapGesture {
                                router.presentSheet(.logDetail(log))
                            }
                            .accessibilityLabel(actionLogAccessibilityLabel(for: log))
                    }
                    .onDelete { indexSet in
                        // 特定の日付グループ内での削除に対応
                        let logsToDelete = indexSet.map { group.logs[$0] }
                        let globalIndices = IndexSet(logsToDelete.compactMap { logToDelete in
                            actionLogs.firstIndex(where: { $0.id == logToDelete.id })
                        })
                        onDelete(globalIndices)
                    }
                } header: {
                    DateHeaderView(date: group.date)
                }
            }
        }
        .listStyle(PlainListStyle())
        .accessibilityLabel("行動ログ一覧")
    }
    .onAppear {
        // 初回表示時にフィルタを初期化
        if cachedFilteredLogs.isEmpty {
            triggerFilterUpdate()
        }
    }
    .onChange(of: selectedLogType) { _ in
        triggerFilterUpdate()
    }
    .onChange(of: selectedDateRange) { _ in
        triggerFilterUpdate()
    }
    .onChange(of: searchText) { _ in
        searchDebouncer.debounce {
            Task { @MainActor in
                triggerFilterUpdate()
            }
        }
    }
    .onChange(of: actionLogs) { _ in
        // データが更新されたらキャッシュをクリア
        cachedFilteredLogs = []
        triggerFilterUpdate()
    }
    
    // MARK: - Accessibility Helper
    private func actionLogAccessibilityLabel(for log: ActionLog) -> String {
        let content = repository.getSecureContent(for: log)
        let timeString = DateFormatter.timeFormatter.string(from: log.timestamp)
        var label = "\(log.logType.displayName)のログ、\(timeString)、\(content)"
        
        if let calories = log.preventedCalories {
            label += "、\(calories)キロカロリー防止"
        }
        
        if let feedback = repository.getSecureAIFeedback(for: log) {
            label += "、AIフィードバック: \(feedback)"
        }
        
        return label
    }
}

// MARK: - Filter Chip Component

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                )
                .foregroundColor(isSelected ? .white : .primary)
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Date Range Enum

enum DateRange: CaseIterable {
    case all
    case today
    case thisWeek
    case thisMonth
    
    var displayName: String {
        switch self {
        case .all:
            return "すべて"
        case .today:
            return "今日"
        case .thisWeek:
            return "今週"
        case .thisMonth:
            return "今月"
        }
    }
}

// MARK: - DateHeaderView Component
struct DateHeaderView: View {
    let date: Date
    
    var body: some View {
        HStack {
            Text(formattedDate)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(dayOfWeek)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityLabel("\(formattedDate), \(dayOfWeek)")
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "今日"
        } else if calendar.isDateInYesterday(date) {
            return "昨日"
        } else {
            formatter.dateFormat = "M月d日"
            return formatter.string(from: date)
        }
    }
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

// MARK: - ActionLogRow Component
struct ActionLogRow: View {
    let log: ActionLog
    let repository: ActionLogRepository
    
    var body: some View {
        HStack(spacing: 12) {
            // アイコン
            Text(log.logType.emoji)
                .font(.title2)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color(.systemGray6))
                )
            
            // メインコンテンツ
            VStack(alignment: .leading, spacing: 4) {
                // 時刻とカロリー情報
                HStack {
                    Text(timeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let calories = log.preventedCalories {
                        Text("\(calories) kcal")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }
                
                // ログ内容
                Text(repository.getSecureContent(for: log))
                    .font(.body)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                // AIフィードバック
                if let feedback = repository.getSecureAIFeedback(for: log) {
                    Text(feedback)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
                
                // 感情タグ
                if !log.emotionTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(log.emotionTags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.purple.opacity(0.2))
                                    .foregroundColor(.purple)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle()) // タップ領域を全体に拡張
    }
    
    private var timeString: String {
        DateFormatter.timeFormatter.string(from: log.timestamp)
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

#Preview {
    let sampleLogs = [
        ActionLog(content: "夜中にアイスクリームを食べたくなったが、水を飲んで我慢した", logType: .success),
        ActionLog(content: "お昼にデザートを我慢できなかった", logType: .failure),
        ActionLog(content: "今とてもポテトチップスが食べたい", logType: .struggle),
        ActionLog(content: "朝食後のデザートをやめることができた", logType: .success),
        ActionLog(content: "友達とのランチで食べ過ぎてしまった", logType: .failure)
    ]
    
    // 異なる日付を設定してグループ化をテスト
    let calendar = Calendar.current
    sampleLogs[0].timestamp = Date() // 今日
    sampleLogs[1].timestamp = Date() // 今日
    sampleLogs[2].timestamp = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date() // 昨日
    sampleLogs[3].timestamp = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date() // 昨日
    sampleLogs[4].timestamp = calendar.date(byAdding: .day, value: -2, to: Date()) ?? Date() // 一昨日
    
    // サンプルデータにAIフィードバックを追加
    sampleLogs[0].setAIFeedback("素晴らしい自制心です！水を飲むのは良い方法ですね。", preventedCalories: 200)
    sampleLogs[1].setAIFeedback("大丈夫です。次回は必ず成功しましょう！")
    sampleLogs[2].setAIFeedback("その気持ちはよく分かります。深呼吸をしてみましょう。")
    sampleLogs[3].setAIFeedback("朝からとても良いスタートですね！", preventedCalories: 150)
    sampleLogs[4].setAIFeedback("友達との時間も大切です。バランスを取りながら頑張りましょう。")
    
    // 感情タグを追加
    sampleLogs[0].addEmotionTag("達成感")
    sampleLogs[0].addEmotionTag("安心")
    sampleLogs[1].addEmotionTag("後悔")
    sampleLogs[2].addEmotionTag("誘惑")
    sampleLogs[3].addEmotionTag("満足")
    sampleLogs[4].addEmotionTag("楽しい")
    
    // プレビュー用の仮のRepository
    let container = try! ModelContainer(for: ActionLog.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = ModelContext(container)
    let repository = ActionLogRepository(modelContext: context)
    
    return LogListView(
        actionLogs: sampleLogs,
        repository: repository,
        onDelete: { _ in
            print("Delete action triggered")
        }
    )
    .padding()
}