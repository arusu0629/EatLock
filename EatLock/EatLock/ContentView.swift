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
    @StateObject private var viewModel = ContentViewModel()
    private let router = NavigationRouter.shared
    

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
                            StatsCardView(stats: viewModel.repository?.currentStats)
                            
                            // 行動ログ一覧
                            if let repository = viewModel.repository {
                                LogListView(
                                    actionLogs: actionLogs,
                                    repository: repository,
                                    onDelete: deleteActionLogs
                                )
                            }
                            
                            // 下部の余白（入力欄の分）
                            Color.clear
                                .frame(height: 140)
                        }
                        .padding(.horizontal)
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        viewModel.updateScrollOffset(value)
                    }
                    
                    // 下部固定入力欄
                    VStack(spacing: 0) {
                        LogInputView(
                            newLogContent: $viewModel.newLogContent,
                            selectedLogType: $viewModel.selectedLogType,
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
                            isInputFocused: $viewModel.isInputFocused,
                            scrollOffset: $viewModel.scrollOffset
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
            viewModel.setupRepository(modelContext: modelContext)
            viewModel.setupKeyboardObservers()
        }
        .onDisappear {
            viewModel.removeKeyboardObservers()
        }
        .alert("エラー", isPresented: $viewModel.showingAlert) {
            Button("OK") { }
        } message: {
            Text(viewModel.alertMessage)
        }
        .disabled(!viewModel.isRepositoryInitialized)
        .overlay(
            // Toast表示用のオーバーレイ
            ZStack {
                if viewModel.showToast {
                    ToastView(
                        message: viewModel.toastMessage,
                        type: viewModel.toastType,
                        isPresented: $viewModel.showToast
                    )
                }
            }
            .allowsHitTesting(false)
        )
        .overlay(
            // フィードバック表示用のオーバーレイ
            ZStack {
                if viewModel.showFeedback, let feedback = viewModel.currentFeedback {
                    FeedbackView(
                        feedback: feedback,
                        isPresented: $viewModel.showFeedback
                    )
                }
            }
            .allowsHitTesting(viewModel.showFeedback)
        )
    }
    
    
    private func addActionLog() {
        Task {
            await viewModel.addActionLog()
        }
    }
    
    private func deleteActionLogs(offsets: IndexSet) {
        let logsToDelete = offsets.compactMap { index in
            guard index < actionLogs.count else { return nil }
            return actionLogs[index]
        }
        viewModel.deleteActionLogs(logsToDelete)
    }
    
    

    
    private func focusTextInput() {
        viewModel.focusTextInput()
    }
    
}

#Preview {
    ContentView()
        .modelContainer(for: ActionLog.self, inMemory: true)
}
