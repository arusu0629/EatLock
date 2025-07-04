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
    @State private var selectedLogType: LogType = .other
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isRepositoryInitialized = false
    
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
        NavigationView {
            VStack(spacing: 0) {
                // カスタムタイトルバー
                TitleBarView()
                    .background(Color(.systemBackground))
                    .shadow(radius: 1)
                
                // メインコンテンツ
                VStack {
                    // 統計カード（仮実装）
                    if let stats = calculateStats() {
                        HStack(spacing: 16) {
                            StatCard(title: "記録回数", value: "\(stats.totalLogs)", color: .blue)
                            StatCard(title: "防いだカロリー", value: "\(stats.totalPreventedCalories)", color: .green)
                            StatCard(title: "継続日数", value: "\(stats.consecutiveDays)", color: .orange)
                        }
                        .padding()
                    }
                    
                    // 行動ログ一覧
                    List {
                        ForEach(actionLogs) { log in
                            ActionLogRow(log: log)
                        }
                        .onDelete(perform: deleteActionLogs)
                    }
                    
                    // 入力欄（下部固定風）
                    VStack {
                        HStack {
                            Picker("ログタイプ", selection: $selectedLogType) {
                                ForEach(LogType.allCases, id: \.self) { type in
                                    Text("\(type.emoji) \(type.displayName)")
                                        .tag(type)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        HStack {
                            TextField("今日の行動を入力...", text: $newLogContent)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button(action: addActionLog) {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(.blue)
                            }
                            .disabled(newLogContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                setupRepository()
            }
            .alert("エラー", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .disabled(!isRepositoryInitialized)
        }
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
        
        do {
            _ = try repository.createActionLog(content: content, logType: selectedLogType)
            newLogContent = ""
            selectedLogType = .other
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
    
    private func deleteActionLogs(offsets: IndexSet) {
        guard isRepositoryInitialized else {
            alertMessage = "データベースの初期化に失敗しました。アプリを再起動してください。"
            showingAlert = true
            return
        }
        
        do {
            let logsToDelete = offsets.map { actionLogs[$0] }
            try repository.deleteActionLogs(logsToDelete)
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
    
    private func calculateStats() -> ActionLogStats? {
        return ActionLog.calculateStats(from: actionLogs)
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

struct ActionLogRow: View {
    let log: ActionLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(log.logType.emoji)
                Text(log.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let calories = log.preventedCalories {
                    Text("\(calories) kcal")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            Text(log.content)
                .font(.body)
            
            if let feedback = log.aiFeedback {
                Text(feedback)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ActionLog.self, inMemory: true)
}
