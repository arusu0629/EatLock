//
//  EatLockApp.swift
//  EatLock
//
//  Created by arusu0629 on 2025/06/25.
//

import SwiftUI
import SwiftData

@main
struct EatLockApp: App {
    @MainActor
    private static var _sharedModelContainer: ModelContainer?
    
    @MainActor
    var sharedModelContainer: ModelContainer {
        if let container = Self._sharedModelContainer {
            return container
        }
        
        do {
            let container = try DataSecurityManager.createSecureModelContainer()
            Self._sharedModelContainer = container
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    // アプリがバックグラウンドに移行する際のセキュリティ処理
                    DataSecurityManager.shared.handleAppWillResignActive()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // アプリがフォアグラウンドに復帰する際のセキュリティ処理
                    Task {
                        await DataSecurityManager.shared.handleAppDidBecomeActive()
                    }
                }
                .task {
                    // アプリ起動時の重要な初期化を並列実行
                    await withTaskGroup(of: Void.self) { group in
                        // 最重要: AIマネージャーの初期化
                        group.addTask {
                            await AIManager.shared.initialize()
                        }
                        
                        // 重要: 通知マネージャーの初期化
                        group.addTask {
                            await NotificationManager.shared.initialize()
                            await NotificationManager.shared.requestPermissionIfNeeded()
                        }
                        
                        // 低優先度: 広告マネージャーは遅延初期化
                        group.addTask {
                            // UI表示後に遅延実行
                            try? await Task.sleep(for: .milliseconds(500))
                            await AdManager.shared.initialize()
                        }
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
