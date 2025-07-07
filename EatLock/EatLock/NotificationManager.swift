//
//  NotificationManager.swift
//  EatLock
//
//  Created by Issue #33 on 2025/07/04.
//

import Foundation
import UserNotifications
import SwiftUI
import os.log

/// 通知権限管理とローカル通知機能を提供するマネージャークラス
@MainActor
final class NotificationManager: ObservableObject {
    
    // MARK: - Properties
    
    static let shared = NotificationManager()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isInitialized = false
    @Published var lastError: NotificationError?
    @Published var isDailyReminderEnabled = true
    
    private let logger = Logger(subsystem: "com.eatlock.notification", category: "NotificationManager")
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // UserDefaults キー
    private let hasRequestedPermissionKey = "EatLock_HasRequestedNotificationPermission"
    private let permissionRequestDateKey = "EatLock_NotificationPermissionRequestDate"
    private let dailyReminderEnabledKey = "EatLock_DailyReminderEnabled"
    
    // MARK: - Motivation Messages
    
    private let motivationMessages = [
        "今日の行動を記録しましょう！小さな一歩が大きな変化につながります。",
        "継続は力なり。今日も頑張りましょう！",
        "あなたの健康目標に向かって、今日も一歩前進しましょう。",
        "記録を続けることで、きっと良い変化が見えてきます。",
        "今日も自分を大切にする行動を心がけましょう。",
        "小さな努力の積み重ねが、大きな成果を生み出します。",
        "今日の自分を振り返る時間を作りましょう。",
        "健康な習慣を続けることで、より良い毎日を送れます。",
        "今日も前向きな気持ちで取り組みましょう！",
        "あなたの努力は必ず報われます。継続していきましょう。"
    ]
    
    private let streakReminderMessages = [
        "連続記録が途切れそうです。今日の行動を記録して継続を保ちましょう！",
        "素晴らしい継続記録を保つために、今日も記録を忘れずに！",
        "継続は成功の鍵です。今日の記録を忘れずに入力しましょう。",
        "頑張っている自分を認めて、今日も記録を続けましょう。",
        "一日の振り返りの時間です。今日の行動を記録しましょう。"
    ]
    
    // MARK: - Initialization
    
    private init() {
        logger.info("NotificationManager initialized")
        setupNotificationDelegate()
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    /// 通知マネージャーを初期化
    func initialize() async {
        guard !isInitialized else {
            logger.info("NotificationManager already initialized")
            return
        }
        
        logger.info("Starting NotificationManager initialization")
        
        // 現在の権限状態を取得
        await updateAuthorizationStatus()
        
        // 通知カテゴリーを設定
        setupNotificationCategories()
        
        // デイリーリマインダーをスケジュール（権限があり、有効の場合）
        if await checkPermission() && isDailyReminderEnabled {
            await scheduleDailyReminder()
        }
        
        isInitialized = true
        logger.info("NotificationManager initialization completed")
    }
    
    /// 通知権限をリクエスト（初回のみ）
    func requestPermissionIfNeeded() async {
        // 既にリクエスト済みかチェック
        if hasRequestedPermission() {
            logger.info("Notification permission already requested, skipping")
            return
        }
        
        // 現在の権限状態を確認
        await updateAuthorizationStatus()
        
        // 既に権限が決定している場合はスキップ
        if authorizationStatus != .notDetermined {
            logger.info("Notification permission already determined: \(authorizationStatus)")
            markPermissionAsRequested()
            return
        }
        
        // 権限をリクエスト
        await requestPermission()
    }
    
    /// 通知権限をリクエスト
    func requestPermission() async {
        logger.info("Requesting notification permission")
        
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            await updateAuthorizationStatus()
            markPermissionAsRequested()
            
            if granted {
                logger.info("Notification permission granted")
                // 権限が許可されたら、デイリーリマインダーをスケジュール
                if isDailyReminderEnabled {
                    await scheduleDailyReminder()
                }
            } else {
                logger.info("Notification permission denied")
            }
            
        } catch {
            logger.error("Failed to request notification permission: \(error.localizedDescription)")
            lastError = .permissionRequestFailed(error)
        }
    }
    
    /// デイリーリマインダー通知をスケジュール
    /// - Parameter time: 通知時刻（オプション、デフォルトは21:00）
    func scheduleDailyReminder(time: DateComponents? = nil) async {
        guard await checkPermission() else {
            logger.warning("Cannot schedule daily reminder: permission not granted")
            return
        }
        
        guard isDailyReminderEnabled else {
            logger.info("Daily reminder is disabled, skipping schedule")
            return
        }
        
        logger.info("Scheduling daily reminder notification")
        
        // 既存のデイリーリマインダーを削除
        await cancelDailyReminder()
        
        // デフォルトの通知時刻を設定（21:00）
        let notificationTime = time ?? DateComponents(hour: 21, minute: 0)
        
        // 通知コンテンツを作成
        let content = UNMutableNotificationContent()
        content.title = "EatLock 習慣化サポート"
        content.body = motivationMessages.randomElement() ?? motivationMessages[0]
        content.sound = .default
        content.categoryIdentifier = "DAILY_REMINDER"
        
        // 毎日繰り返すトリガーを作成
        let trigger = UNCalendarNotificationTrigger(dateMatching: notificationTime, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            logger.info("Daily reminder notification scheduled successfully for \(notificationTime.hour ?? 21):\(notificationTime.minute ?? 0)")
        } catch {
            logger.error("Failed to schedule daily reminder: \(error.localizedDescription)")
            lastError = .schedulingFailed(error)
        }
    }
    
    /// 連続記録が途切れそうなタイミングでの通知をスケジュール
    func scheduleStreakReminderIfNeeded() async {
        guard await checkPermission() else {
            logger.warning("Cannot schedule streak reminder: permission not granted")
            return
        }
        
        guard isDailyReminderEnabled else {
            logger.info("Daily reminder is disabled, skipping streak reminder")
            return
        }
        
        logger.info("Scheduling streak reminder notification")
        
        // 既存の連続記録リマインダーを削除
        await cancelStreakReminder()
        
        // 2時間後に通知を送信
        let content = UNMutableNotificationContent()
        content.title = "EatLock 継続サポート"
        content.body = streakReminderMessages.randomElement() ?? streakReminderMessages[0]
        content.sound = .default
        content.categoryIdentifier = "STREAK_REMINDER"
        
        // 2時間後に発火（テスト用）
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 7200, repeats: false)
        let request = UNNotificationRequest(
            identifier: "streak_reminder",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            logger.info("Streak reminder notification scheduled successfully")
        } catch {
            logger.error("Failed to schedule streak reminder: \(error.localizedDescription)")
            lastError = .schedulingFailed(error)
        }
    }
    
    /// デイリーリマインダー通知を有効/無効にする
    func setDailyReminderEnabled(_ enabled: Bool) async {
        logger.info("Setting daily reminder enabled: \(enabled)")
        
        isDailyReminderEnabled = enabled
        saveDailyReminderEnabled(enabled)
        
        if enabled {
            if await checkPermission() {
                await scheduleDailyReminder()
            }
        } else {
            await cancelDailyReminder()
        }
    }
    
    /// デイリーリマインダーをキャンセル
    func cancelDailyReminder() async {
        logger.info("Canceling daily reminder")
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
    }
    
    /// 連続記録リマインダーをキャンセル
    func cancelStreakReminder() async {
        logger.info("Canceling streak reminder")
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["streak_reminder"])
    }
    
    /// テスト用ローカル通知を即時発火
    func scheduleTestNotification() async {
        guard await checkPermission() else {
            logger.warning("Cannot schedule test notification: permission not granted")
            return
        }
        
        logger.info("Scheduling test notification")
        
        let content = UNMutableNotificationContent()
        content.title = "EatLock テスト通知"
        content.body = "通知機能が正常に動作しています！"
        content.sound = .default
        content.badge = 1
        
        // 即時発火（1秒後）
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test_notification_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            logger.info("Test notification scheduled successfully")
        } catch {
            logger.error("Failed to schedule test notification: \(error.localizedDescription)")
            lastError = .schedulingFailed(error)
        }
    }
    
    /// 習慣化サポート通知をスケジュール
    func scheduleHabitReminderNotification(at time: DateComponents) async {
        guard await checkPermission() else {
            logger.warning("Cannot schedule habit reminder: permission not granted")
            return
        }
        
        logger.info("Scheduling habit reminder notification")
        
        let content = UNMutableNotificationContent()
        content.title = "EatLock 習慣化サポート"
        content.body = "今日の行動を記録しましょう！小さな一歩が大きな変化につながります。"
        content.sound = .default
        content.categoryIdentifier = "HABIT_REMINDER"
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(
            identifier: "habit_reminder",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            logger.info("Habit reminder notification scheduled successfully")
        } catch {
            logger.error("Failed to schedule habit reminder: \(error.localizedDescription)")
            lastError = .schedulingFailed(error)
        }
    }
    
    /// 全ての通知を削除
    func removeAllNotifications() {
        logger.info("Removing all notifications")
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    /// 特定のカテゴリの通知を削除
    func removeNotifications(withCategory category: String) async {
        logger.info("Removing notifications for category: \(category)")
        
        let requests = await notificationCenter.pendingNotificationRequests()
        let identifiers = requests
            .filter { $0.content.categoryIdentifier == category }
            .map { $0.identifier }
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    // MARK: - Private Methods
    
    /// 通知権限の状態を更新
    private func updateAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        logger.info("Authorization status updated: \(authorizationStatus)")
    }
    
    /// 通知権限をチェック
    private func checkPermission() async -> Bool {
        await updateAuthorizationStatus()
        return authorizationStatus == .authorized
    }
    
    /// 通知カテゴリーを設定
    private func setupNotificationCategories() {
        let dailyReminderCategory = UNNotificationCategory(
            identifier: "DAILY_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        let streakReminderCategory = UNNotificationCategory(
            identifier: "STREAK_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        let habitReminderCategory = UNNotificationCategory(
            identifier: "HABIT_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        notificationCenter.setNotificationCategories([
            dailyReminderCategory,
            streakReminderCategory,
            habitReminderCategory
        ])
        logger.info("Notification categories set up")
    }
    
    /// 通知デリゲートを設定
    private func setupNotificationDelegate() {
        notificationCenter.delegate = NotificationDelegate.shared
    }
    
    /// 権限リクエスト済みかチェック
    private func hasRequestedPermission() -> Bool {
        return UserDefaults.standard.bool(forKey: hasRequestedPermissionKey)
    }
    
    /// 権限リクエストを記録
    private func markPermissionAsRequested() {
        UserDefaults.standard.set(true, forKey: hasRequestedPermissionKey)
        UserDefaults.standard.set(Date(), forKey: permissionRequestDateKey)
        logger.info("Permission request marked as completed")
    }
    
    /// 権限リクエスト日時を取得
    func getPermissionRequestDate() -> Date? {
        return UserDefaults.standard.object(forKey: permissionRequestDateKey) as? Date
    }
    
    /// 権限状態の詳細情報を取得
    func getDetailedPermissionStatus() async -> NotificationPermissionStatus {
        let settings = await notificationCenter.notificationSettings()
        
        return NotificationPermissionStatus(
            authorization: settings.authorizationStatus,
            alertSetting: settings.alertSetting,
            badgeSetting: settings.badgeSetting,
            soundSetting: settings.soundSetting,
            hasRequestedPermission: hasRequestedPermission(),
            requestDate: getPermissionRequestDate()
        )
    }
    
    /// 設定を読み込み
    private func loadSettings() {
        isDailyReminderEnabled = UserDefaults.standard.bool(forKey: dailyReminderEnabledKey)
        if !UserDefaults.standard.bool(forKey: "\(dailyReminderEnabledKey)_initialized") {
            // 初回起動時はデフォルトでtrue
            isDailyReminderEnabled = true
            UserDefaults.standard.set(true, forKey: dailyReminderEnabledKey)
            UserDefaults.standard.set(true, forKey: "\(dailyReminderEnabledKey)_initialized")
        }
    }
    
    /// デイリーリマインダーの有効/無効設定を保存
    private func saveDailyReminderEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: dailyReminderEnabledKey)
    }
}

// MARK: - NotificationDelegate

/// 通知デリゲート実装
private class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    private let logger = Logger(subsystem: "com.eatlock.notification", category: "NotificationDelegate")
    
    /// アプリがフォアグラウンドで通知を受信した時の処理
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        logger.info("Notification received in foreground: \(notification.request.identifier)")
        
        // フォアグラウンドでも通知を表示
        completionHandler([.alert, .badge, .sound])
    }
    
    /// 通知をタップした時の処理
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        logger.info("Notification action received: \(response.actionIdentifier)")
        
        // 通知に対するアクションを処理
        handleNotificationResponse(response)
        
        completionHandler()
    }
    
    private func handleNotificationResponse(_ response: UNNotificationResponse) {
        let identifier = response.notification.request.identifier
        let categoryIdentifier = response.notification.request.content.categoryIdentifier
        
        logger.info("Handling notification response - ID: \(identifier), Category: \(categoryIdentifier)")
        
        // 通知の種類に応じた処理
        switch categoryIdentifier {
        case "DAILY_REMINDER", "STREAK_REMINDER":
            // デイリーリマインダーや連続記録リマインダーの場合
            // アプリを開いてログ入力画面に誘導
            // 実際の実装では、NavigationRouterを使用して適切な画面に遷移
            break
        case "HABIT_REMINDER":
            // 習慣化サポート通知の場合
            // アプリを開いてメイン画面に遷移
            break
        default:
            break
        }
    }
}

// MARK: - Supporting Types

/// 通知権限の詳細状態
struct NotificationPermissionStatus {
    let authorization: UNAuthorizationStatus
    let alertSetting: UNNotificationSetting
    let badgeSetting: UNNotificationSetting
    let soundSetting: UNNotificationSetting
    let hasRequestedPermission: Bool
    let requestDate: Date?
    
    var isFullyAuthorized: Bool {
        return authorization == .authorized &&
               alertSetting == .enabled &&
               badgeSetting == .enabled &&
               soundSetting == .enabled
    }
    
    var canShowNotifications: Bool {
        return authorization == .authorized
    }
}

/// 通知関連エラー
enum NotificationError: LocalizedError {
    case permissionRequestFailed(Error)
    case schedulingFailed(Error)
    case notInitialized
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .permissionRequestFailed(let error):
            return "通知権限のリクエストに失敗しました: \(error.localizedDescription)"
        case .schedulingFailed(let error):
            return "通知のスケジュールに失敗しました: \(error.localizedDescription)"
        case .notInitialized:
            return "通知マネージャーが初期化されていません"
        case .permissionDenied:
            return "通知権限が拒否されています"
        }
    }
}