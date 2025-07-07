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
    var sharedModelContainer: ModelContainer = {
        // セキュアなModelContainerを使用
        do {
            return try DataSecurityManager.createSecureModelContainer()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

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
                    // アプリ起動時にAIを初期化
                    await AIManager.shared.initialize()
                    
                    // アプリ起動時に通知マネージャーを初期化
                    await NotificationManager.shared.initialize()
                    
                    // 通知権限を初回のみリクエスト
                    await NotificationManager.shared.requestPermissionIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
