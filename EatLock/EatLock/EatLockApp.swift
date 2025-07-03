//
//  EatLockApp.swift
//  EatLock
//
//  Created by arusu0629 on 2025/06/25.
//

import SwiftUI
import SwiftData
import UserNotifications

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
            ContentView()
                .onAppear {
                    setupApp()
                }
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
    
    /// アプリ初期設定
    private func setupApp() {
        Task {
            // 通知カテゴリを設定
            NotificationService.shared.setupNotificationCategories()
            
            // 通知許可をリクエスト
            let permissionGranted = await NotificationService.shared.requestNotificationPermission()
            
            if permissionGranted {
                // 習慣化サポート通知をスケジュール
                await NotificationService.shared.scheduleHabitReminder()
                print("✅ 通知許可が得られ、習慣化サポート機能が有効になりました")
            } else {
                print("ℹ️ 通知許可が拒否されました。基本機能はそのまま利用できます")
            }
        }
    }
}
