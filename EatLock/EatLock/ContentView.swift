//
//  ContentView.swift
//  EatLock
//
//  Created by arusu0629 on 2025/06/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ActionLog.timestamp, order: .reverse) private var actionLogs: [ActionLog]
    @State private var repository: ActionLogRepository
    @State private var newLogContent = ""
    @State private var isProcessing = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isRepositoryInitialized = false
    @State private var showingLogDetail: ActionLog? = nil
    
    init() {
        // 仮の初期化（実際のmodelContextは後でsetupで設定）
        do {
            let container = try ModelContainer(for: ActionLog.self)
            let context = ModelContext(container)
            _repository = State(initialValue: ActionLogRepository(modelContext: context))
        } catch {
            // 初期化に失敗した場合は仮のコンテキストを作成
            let container = try! ModelContainer(for: ActionLog.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)
            _repository = State(initialValue: ActionLogRepository(modelContext: context))
        }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // タイトルバー（ロゴ＋日付）
                HeaderView()
                
                // 統計ダッシュボード
                if let stats = calculateStats() {
                    DashboardView(stats: stats)
                        .padding(.horizontal)
                        .padding(.top, 16)
                }
                
                // 区切り線
                Divider()
                    .padding(.vertical, 16)
                
                // ログ一覧
                if actionLogs.isEmpty {
                    EmptyStateView()
                } else {
                    LogListView(logs: actionLogs, selectedLog: $showingLogDetail)
                }
                
                Spacer()
                
                // 入力欄（下部固定）
                LogInputView(
                    inputText: $newLogContent,
                    isProcessing: $isProcessing,
                    onSubmit: addActionLog
                )
                
                // 広告バナー
                AdBannerView()
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            setupRepository()
        }
        .sheet(item: $showingLogDetail) { log in
            LogDetailView(log: log)
        }
        .alert("エラー", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .disabled(!isRepositoryInitialized)
    }
    
    private func setupRepository() {
        repository = ActionLogRepository(modelContext: modelContext)
        isRepositoryInitialized = true
    }
    
    private func addActionLog() {
        let content = newLogContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        guard isRepositoryInitialized else {
            alertMessage = "データベースの初期化に失敗しました。アプリを再起動してください。"
            showingAlert = true
            return
        }
        
        isProcessing = true
        
        Task {
            // AIフィードバック生成
            let aiResult = await AIFeedbackService.shared.generateFeedback(for: content)
            let logType = AIFeedbackService.shared.determineLogType(from: content)
            
            await MainActor.run {
                do {
                    // 行動ログを作成
                    let newLog = try repository.createActionLog(content: content, logType: logType)
                    
                    // AIフィードバックを設定
                    try repository.setAIFeedback(
                        for: newLog,
                        feedback: aiResult.feedback,
                        preventedCalories: aiResult.isSuccessful ? aiResult.preventedCalories : nil
                    )
                    
                    // 成功時に通知を送信
                    if aiResult.isSuccessful && aiResult.preventedCalories > 0 {
                        Task {
                            await NotificationService.shared.sendSuccessNotification(preventedCalories: aiResult.preventedCalories)
                        }
                    }
                    
                    // 継続日数チェック
                    let stats = calculateStats()
                    if let stats = stats, stats.consecutiveDays > 0 && stats.consecutiveDays % 7 == 0 {
                        Task {
                            await NotificationService.shared.sendStreakAchievementNotification(days: stats.consecutiveDays)
                        }
                    }
                    
                    newLogContent = ""
                    isProcessing = false
                } catch {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                    isProcessing = false
                }
            }
        }
    }
    
    private func calculateStats() -> ActionLogStats? {
        return ActionLog.calculateStats(from: actionLogs)
    }
}

// MARK: - Supporting Views

/// タイトルバー（ロゴ＋日付）
struct HeaderView: View {
    var body: some View {
        HStack {
            Text("🌱 HealthyChoice")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(dateString)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: Date())
    }
}

/// 統計ダッシュボード
struct DashboardView: View {
    let stats: ActionLogStats
    
    var body: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "記録回数",
                value: "\(stats.totalLogs)",
                subtitle: "回",
                icon: "doc.text.fill",
                color: .blue
            )
            
            StatCard(
                title: "防いだカロリー",
                value: "\(stats.totalPreventedCalories)",
                subtitle: "kcal",
                icon: "flame.fill",
                color: .orange
            )
            
            StatCard(
                title: "継続日数",
                value: "\(stats.consecutiveDays)",
                subtitle: "日",
                icon: "calendar.badge.checkmark",
                color: .green
            )
        }
    }
}

/// 統計カード
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                HStack(alignment: .bottom, spacing: 2) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

/// ログ一覧ビュー
struct LogListView: View {
    let logs: [ActionLog]
    @Binding var selectedLog: ActionLog?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(groupedLogs.keys.sorted(by: >), id: \.self) { date in
                    Section {
                        ForEach(groupedLogs[date] ?? []) { log in
                            LogRowView(log: log) {
                                selectedLog = log
                            }
                        }
                    } header: {
                        sectionHeader(for: date)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var groupedLogs: [String: [ActionLog]] {
        Dictionary(grouping: logs) { log in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd"
            return formatter.string(from: log.timestamp)
        }
    }
    
    private func sectionHeader(for dateString: String) -> some View {
        HStack {
            Text(formatSectionDate(dateString))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private func formatSectionDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今日"
        } else if calendar.isDateInYesterday(date) {
            return "昨日"
        } else {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "M月d日"
            return displayFormatter.string(from: date)
        }
    }
}

/// ログ行ビュー
struct LogRowView: View {
    let log: ActionLog
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // ステータスアイコン
                Image(systemName: log.logType == .success ? "checkmark.circle.fill" : 
                     log.logType == .failure ? "xmark.circle.fill" : 
                     log.logType == .struggle ? "heart.circle.fill" : "circle.fill")
                    .foregroundColor(log.logType == .success ? .green : 
                                   log.logType == .failure ? .red : 
                                   log.logType == .struggle ? .orange : .gray)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    // 時間とプレビューテキスト
                    HStack {
                        Text(log.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if let calories = log.preventedCalories, calories > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .font(.caption2)
                                Text("\(calories)kcal")
                                    .font(.caption2)
                            }
                            .foregroundColor(.orange)
                        }
                    }
                    
                    Text(log.content)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // 詳細矢印
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// 入力欄ビュー
struct LogInputView: View {
    @Binding var inputText: String
    @Binding var isProcessing: Bool
    let onSubmit: () -> Void
    
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // テキスト入力欄
                TextField("今日の行動を入力...", text: $inputText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(1...4)
                    .onSubmit {
                        if canSubmit {
                            onSubmit()
                        }
                    }
                    .disabled(isProcessing)
                
                // 送信ボタン
                Button(action: {
                    if canSubmit {
                        onSubmit()
                    }
                }) {
                    Group {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                        }
                    }
                    .frame(width: 32, height: 32)
                    .foregroundColor(canSubmit ? .blue : .secondary)
                }
                .disabled(!canSubmit || isProcessing)
                .scaleEffect(pulseScale)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseScale)
                .onAppear {
                    pulseScale = 1.1
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(Color(.systemBackground))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: -2)
            
            // ヒントテキスト
            if inputText.isEmpty && !isProcessing {
                hintView
            }
        }
    }
    
    private var canSubmit: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isProcessing
    }
    
    private var hintView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("💡 入力例:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("「夜中のアイスを我慢した」「デザートを一つだけにした」")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
    }
}

/// 空状態ビュー
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("まだログがありません")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("下の入力欄から今日の行動を記録してみましょう")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// ログ詳細ビュー
struct LogDetailView: View {
    let log: ActionLog
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: log.logType == .success ? "checkmark.circle.fill" : 
                             log.logType == .failure ? "xmark.circle.fill" : 
                             log.logType == .struggle ? "heart.circle.fill" : "circle.fill")
                            .foregroundColor(log.logType == .success ? .green : 
                                           log.logType == .failure ? .red : 
                                           log.logType == .struggle ? .orange : .gray)
                            .font(.title2)
                        
                        Text(log.formattedDate)
                            .font(.headline)
                        
                        Spacer()
                    }
                    
                    Text(log.content)
                        .font(.body)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
                
                Divider()
                
                if let feedback = log.aiFeedback {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AIフィードバック")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(feedback)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(12)
                    }
                }
                
                if let calories = log.preventedCalories, calories > 0 {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(calories) kcal 防いだ！")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("ログ詳細")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("閉じる") { dismiss() })
        }
    }
}

/// 広告バナービュー
struct AdBannerView: View {
    var body: some View {
        HStack {
            Spacer()
            Text("📱 健康アプリをもっと見る")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(height: 50)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ActionLog.self, inMemory: true)
}
