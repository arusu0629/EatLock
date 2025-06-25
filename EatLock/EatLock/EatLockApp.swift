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
        let schema = Schema([
            ActionLog.self,
        ])
        // セキュアなModelConfigurationを使用
        let modelConfiguration = DataSecurityManager.createSecureModelConfiguration()

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
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
        }
        .modelContainer(sharedModelContainer)
    }
}
