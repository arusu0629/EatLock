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
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastType = .info
    private let router = NavigationRouter.shared
    
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
                // カスタムタイトルバー
                TitleBarView()
                    .background(Color(.systemBackground))
                    .shadow(radius: 1)
                    .zIndex(1)
                
                // メインコンテンツ
                ScrollView {
                    VStack(spacing: 16) {
                        // 統計カード
                        StatsCardView(stats: calculateStats())
                        
                        // 行動ログ一覧
                        LogListView(
                            actionLogs: actionLogs,
                            repository: repository,
                            onDelete: deleteActionLogs
                        )
                        
                        // 下部の余白（入力欄の分）
                        Color.clear
                            .frame(height: 140)
                    }
                    .padding(.horizontal)
                }
                
                // 下部固定入力欄
                VStack(spacing: 0) {
                    LogInputView(
                        newLogContent: $newLogContent,
                        selectedLogType: $selectedLogType,
                        onSubmit: addActionLog
                    )
                }
                .background(Color(.systemBackground))
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(.keyboard, edges: .bottom)
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
        .overlay(
            // Toast表示用のオーバーレイ
            ZStack {
                if showToast {
                    ToastView(
                        message: toastMessage,
                        type: toastType,
                        isPresented: $showToast
                    )
                }
            }
            .allowsHitTesting(false)
        )
    }
    
    private func setupRepository() {
        repository = ActionLogRepository(modelContext: modelContext)
        isRepositoryInitialized = true
    }
    
    private func addActionLog() {
        let content = newLogContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        // 文字数チェック
        guard content.count <= 500 else {
            showToast(message: "文字数が上限（500文字）を超えています", type: .error)
            return
        }
        
        guard isRepositoryInitialized else {
            showToast(message: "データベースの初期化に失敗しました。アプリを再起動してください。", type: .error)
            return
        }
        
        do {
            _ = try repository.createActionLog(content: content, logType: selectedLogType)
            newLogContent = ""
            selectedLogType = .other
            
            // 入力成功時のハプティックフィードバック
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // 成功時のToast表示
            showToast(message: "行動ログを保存しました", type: .success)
            
        } catch {
            // エラー時のToast表示
            showToast(message: error.localizedDescription, type: .error)
        }
    }
    
    private func deleteActionLogs(offsets: IndexSet) {
        guard isRepositoryInitialized else {
            showToast(message: "データベースの初期化に失敗しました。アプリを再起動してください。", type: .error)
            return
        }
        
        do {
            let logsToDelete = offsets.map { actionLogs[$0] }
            try repository.deleteActionLogs(logsToDelete)
            showToast(message: "行動ログを削除しました", type: .success)
        } catch {
            showToast(message: error.localizedDescription, type: .error)
        }
    }
    
    private func calculateStats() -> ActionLogStats? {
        return ActionLog.calculateStats(from: actionLogs)
    }
    
    private func showToast(message: String, type: ToastType) {
        toastMessage = message
        toastType = type
        withAnimation {
            showToast = true
        }
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
