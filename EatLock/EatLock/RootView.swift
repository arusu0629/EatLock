//
//  RootView.swift
//  EatLock
//
//  Created by NavigationSystem on 2025/06/25.
//

import SwiftUI
import SwiftData

/// アプリケーションのルートビュー
/// NavigationStackを使用して最新のナビゲーション管理を提供
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    private let router = NavigationRouter.shared
    @State private var repository: ActionLogRepository?
    @ObservedObject private var adManager = AdManager.shared
    @State private var showConsentForm = false
    
    var body: some View {
        NavigationStack(path: $router.navigationPath) {
            // ホーム画面をベースとして表示
            ContentView()
                .navigationDestination(for: NavigationDestination.self) { destination in
                    destinationView(for: destination)
                }
        }
        .withNavigationRouter(router)
        .sheet(isPresented: $showConsentForm) {
            ConsentFormView()
        }
        .onAppear {
            setupRepository()
        }
        .onChange(of: adManager.consentStatus) { _, newStatus in
            // 同意が必要な場合はフォームを表示
            if newStatus == .required {
                showConsentForm = true
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupRepository() {
        guard repository == nil else { return }
        repository = ActionLogRepository(modelContext: modelContext)
    }
    
    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        if let repository = repository {
            destination.destination(repository: repository)
        } else {
            ProgressView("読み込み中...")
                .onAppear {
                    setupRepository()
                }
        }
    }
}

// MARK: - Preview

#Preview {
    RootView()
        .modelContainer(for: ActionLog.self, inMemory: true)
}