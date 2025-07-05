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
    @State private var router = NavigationRouter.shared
    
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
        VStack(spacing: 0) {
            // カスタムタイトルバー
            TitleBarView()
                .background(Color(.systemBackground))
                .shadow(radius: 1)
            
            // メインコンテンツ
            VStack {
                // 統計カード
                StatsCardView(stats: calculateStats())
                
                // 行動ログ一覧
                LogListView(
                    actionLogs: actionLogs,
                    repository: repository,
                    onDelete: deleteActionLogs
                )
                
                // 入力欄（下部固定風）
                LogInputView(
                    newLogContent: $newLogContent,
                    selectedLogType: $selectedLogType,
                    onSubmit: addActionLog
                )
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupRepository()
            checkTutorialNeeded()
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
    
    private func checkTutorialNeeded() {
        let hasSeenTutorial = UserDefaults.standard.bool(forKey: "HasSeenTutorial")
        if !hasSeenTutorial {
            // 少し遅延させてから表示（アプリの初期化完了後）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                router.presentSheet(.tutorial)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ActionLog.self, inMemory: true)
}
