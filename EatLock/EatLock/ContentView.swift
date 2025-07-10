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
    @State private var showFeedback = false
    @State private var currentFeedback: AIFeedback?
    @State private var scrollOffset: CGFloat = 0
    @State private var isInputFocused = false
    @FocusState private var textFieldIsFocused: Bool
    private let router = NavigationRouter.shared
    
    init() {
        // 仮の初期化（実際のmodelContextは後でsetupで設定）
        do {
            let container = try ModelContainer(for: ActionLog.self)
            let context = ModelContext(container)
            _repository = State(initialValue: ActionLogRepository(modelContext: context))
        } catch {
            // 初期化に失敗した場合は仮のコンテキストを作成
            do {
                let container = try ModelContainer(for: ActionLog.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
                let context = ModelContext(container)
                _repository = State(initialValue: ActionLogRepository(modelContext: context))
            } catch {
                // 最終的なフォールバック：エラーログを出力して基本的なリポジトリを作成
                print("Fatal error: Could not create ModelContainer: \(error)")
                let container = try! ModelContainer(for: ActionLog.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
                let context = ModelContext(container)
                _repository = State(initialValue: ActionLogRepository(modelContext: context))
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    // カスタムタイトルバー
                    TitleBarView()
                        .background(Color(.systemBackground))
                        .shadow(radius: 1)
                        .zIndex(1)
                    
                    // メインコンテンツ
                    ScrollView {
                        VStack(spacing: 16) {
                            // スクロール位置監視用のリーダー
                            ScrollOffsetReader()
                            
                            // 統計カード
                            StatsCardView(stats: repository.currentStats)
                            
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
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        scrollOffset = -value
                    }
                    
                    // 下部固定入力欄
                    VStack(spacing: 0) {
                        LogInputView(
                            newLogContent: $newLogContent,
                            selectedLogType: $selectedLogType,
                            onSubmit: addActionLog
                        )
                        
                        // 広告バナー（Safe Area下端に固定、キーボード対応）
                        AdaptiveBannerAdView()
                    }
                    .background(Color(.systemBackground))
                }
                
                // フローティングボタン
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        FloatingAddButton(
                            onTap: {
                                focusTextInput()
                            },
                            isInputFocused: $isInputFocused,
                            scrollOffset: $scrollOffset
                        )
                        .padding(.trailing, 20)
                        .padding(.bottom, 120) // 入力欄の上に配置
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // Safe Area下端への確実な固定を保証
            EmptyView()
        }
        .onAppear {
            setupRepository()
            setupKeyboardObservers()
        }
        .onDisappear {
            removeKeyboardObservers()
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
        .overlay(
            // フィードバック表示用のオーバーレイ
            ZStack {
                if showFeedback, let feedback = currentFeedback {
                    FeedbackView(
                        feedback: feedback,
                        isPresented: $showFeedback
                    )
                }
            }
            .allowsHitTesting(showFeedback)
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
        
        // AIフィードバック付きでログを作成
        Task { @MainActor in
            do {
                let createdLog = try await repository.createActionLogWithAIFeedback(content: content, logType: selectedLogType)
                
                // UI更新（すでにMainActorで実行されている）
                newLogContent = ""
                selectedLogType = .other
                
                // 入力成功時のハプティックフィードバック
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                // AIフィードバックが生成されていれば表示
                if let aiFeedback = repository.getSecureAIFeedback(for: createdLog) {
                    
                    // AIFeedbackオブジェクトを作成（preventedCaloriesがnilの場合は0を使用）
                    let feedback = AIFeedback(
                        message: aiFeedback,
                        preventedCalories: createdLog.preventedCalories ?? 0,
                        type: determineFeedbackType(for: createdLog.logType),
                        generatedAt: createdLog.updatedAt
                    )
                    
                    // 少し遅延してフィードバックを表示
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(500))
                        guard !Task.isCancelled else { return }
                        self.currentFeedback = feedback
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.showFeedback = true
                        }
                    }
                } else {
                    // AIフィードバックが生成されていない場合は通常のToast
                    showToast(message: "行動ログを保存しました", type: .success)
                }
                
            } catch {
                // エラー時のToast表示（すでにMainActorで実行されている）
                showToast(message: error.localizedDescription, type: .error)
            }
        }
    }
    
    private func deleteActionLogs(offsets: IndexSet) {
        guard isRepositoryInitialized else {
            showToast(message: "データベースの初期化に失敗しました。アプリを再起動してください。", type: .error)
            return
        }
        
        do {
            let logsToDelete = offsets.compactMap { index in
                guard index < actionLogs.count else { return nil }
                return actionLogs[index]
            }
            
            guard !logsToDelete.isEmpty else {
                showToast(message: "削除対象のログが見つかりません", type: .error)
                return
            }
            
            try repository.deleteActionLogs(logsToDelete)
            showToast(message: "行動ログを削除しました", type: .success)
        } catch {
            showToast(message: error.localizedDescription, type: .error)
        }
    }
    
    private func calculateStats() -> ActionLogStats? {
        // 現在は repository.currentStats を使用するため、このメソッドは不要
        // 後方互換性のために残している
        return repository.currentStats
    }
    
    private func showToast(message: String, type: ToastType) {
        toastMessage = message
        toastType = type
        withAnimation {
            showToast = true
        }
    }
    
    private func determineFeedbackType(for logType: LogType) -> AIFeedback.FeedbackType {
        switch logType {
        case .success:
            return .achievement
        case .failure:
            return .support
        case .struggle:
            return .encouragement
        case .other:
            return .support
        }
    }
    

    
    private func focusTextInput() {
        // フローティングボタンタップ時にテキスト入力にフォーカス
        // @FocusStateを使った適切なフォーカス管理はLogInputView内で実装
        // ここではスクロールを最下部に移動してユーザーの注意を入力欄に向ける
        withAnimation(.easeInOut(duration: 0.5)) {
            scrollOffset = 0
        }
        
        // ハプティックフィードバックでユーザーに操作完了を知らせる
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    @State private var keyboardShowObserver: NSObjectProtocol?
    @State private var keyboardHideObserver: NSObjectProtocol?
    
    private func setupKeyboardObservers() {
        keyboardShowObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { _ in
            isInputFocused = true
        }
        
        keyboardHideObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            isInputFocused = false
        }
    }
    
    private func removeKeyboardObservers() {
        if let observer = keyboardShowObserver {
            NotificationCenter.default.removeObserver(observer)
            keyboardShowObserver = nil
        }
        
        if let observer = keyboardHideObserver {
            NotificationCenter.default.removeObserver(observer)
            keyboardHideObserver = nil
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ActionLog.self, inMemory: true)
}
