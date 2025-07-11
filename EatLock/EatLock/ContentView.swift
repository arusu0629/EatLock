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
                            if let stats = viewModel.repository?.currentStats {
                                StatsCardView(stats: stats)
                            } else {
                                StatsCardView(stats: ActionLogStats(totalLogs: 0, successLogs: 0, totalPreventedCalories: 0, consecutiveDays: 0))
                            }

                            // 行動ログ一覧
                            LogListSection(
                                actionLogs: actionLogs,
                                repository: viewModel.repository,
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
                        viewModel.updateScrollOffset(value)
                    }

                    // 下部固定入力欄
                    VStack(spacing: 0) {
                        // リポジトリの初期化状態に関係なく、常に表示
                        LogInputView(
                            newLogContent: $viewModel.newLogContent,
                            selectedLogType: $viewModel.selectedLogType,
                            onSubmit: addActionLog
                        )
                        .frame(minHeight: 120)
                        .background(Color(.systemBackground))
                        .disabled(!viewModel.isRepositoryInitialized)
                        .overlay(
                            // 初期化中のオーバーレイ
                            Group {
                                if !viewModel.isRepositoryInitialized {
                                    Color.black.opacity(0.3)
                                        .overlay(
                                            VStack {
                                                ProgressView()
                                                    .tint(.white)
                                                Text("初期化中...")
                                                    .font(.caption)
                                                    .foregroundColor(.white)
                                            }
                                        )
                                        .cornerRadius(12)
                                }
                            }
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
        .onAppear {
            viewModel.setupRepository(modelContext: modelContext)
            viewModel.setupKeyboardObservers()
        }
        .onChange(of: actionLogs) { _, newLogs in
            // ログが追加された際の処理（必要に応じて追加）
        }
        .onDisappear {
            viewModel.removeKeyboardObservers()
        }
        .alert("エラー", isPresented: $viewModel.showingAlert) {
            Button("OK") { }
        } message: {
            Text(viewModel.alertMessage)
        }
        // 全体を無効化しない - 個別のコンポーネントで制御
        .overlay(
            // デバッグ用のステータス表示
            VStack {
                if !viewModel.isRepositoryInitialized {
                    HStack {
                        Spacer()
                        VStack {
                            Text("データベース初期化中...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(8)
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                                .shadow(radius: 2)
                        }
                        Spacer()
                    }
                    .padding(.top, 100)
                }
                Spacer()
            }
            .allowsHitTesting(false)
        )
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
        let logsToDelete: [ActionLog] = offsets.compactMap { index in
            guard index < actionLogs.count else { return nil }
            return actionLogs[index]
        }
        viewModel.deleteActionLogs(logsToDelete)
    }




    private func focusTextInput() {
        viewModel.focusTextInput()
    }
}

// MARK: - LogListSection Component

struct LogListSection: View {
    let actionLogs: [ActionLog]
    let repository: ActionLogRepository?
    let onDelete: (IndexSet) -> Void
    
    var body: some View {
        if let repository = repository {
            LogListView(
                actionLogs: actionLogs,
                repository: repository,
                onDelete: onDelete
            )
        } else {
            // リポジトリ未初期化時の表示
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("データベースを準備中...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(minHeight: 200)
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ActionLog.self, inMemory: true)
}
