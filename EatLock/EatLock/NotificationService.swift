import Foundation
import UserNotifications

/// 習慣化サポート通知サービス
class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    /// 通知許可をリクエスト
    func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("通知許可の取得に失敗: \(error)")
            return false
        }
    }
    
    /// 習慣化サポート通知をスケジュール
    func scheduleHabitReminder() async {
        let center = UNUserNotificationCenter.current()
        
        // 既存の定期通知をキャンセル
        center.removePendingNotificationRequests(withIdentifiers: ["evening_reminder", "night_reminder"])
        
        // 夕方の振り返り通知（19:00）
        let eveningContent = UNMutableNotificationContent()
        eveningContent.title = "🌱 今日の振り返り"
        eveningContent.body = "今日はどんな健康的な選択をしましたか？記録してみましょう"
        eveningContent.sound = .default
        eveningContent.categoryIdentifier = "HABIT_REMINDER"
        
        var eveningDateComponents = DateComponents()
        eveningDateComponents.hour = 19
        eveningDateComponents.minute = 0
        
        let eveningTrigger = UNCalendarNotificationTrigger(dateMatching: eveningDateComponents, repeats: true)
        let eveningRequest = UNNotificationRequest(identifier: "evening_reminder", content: eveningContent, trigger: eveningTrigger)
        
        // 就寝前の注意喚起通知（22:00）
        let nightContent = UNMutableNotificationContent()
        nightContent.title = "🌙 就寝前のチェック"
        nightContent.body = "夜食の誘惑に負けそうになったら、まず水を一杯飲んでみませんか？"
        nightContent.sound = .default
        nightContent.categoryIdentifier = "HABIT_REMINDER"
        
        var nightDateComponents = DateComponents()
        nightDateComponents.hour = 22
        nightDateComponents.minute = 0
        
        let nightTrigger = UNCalendarNotificationTrigger(dateMatching: nightDateComponents, repeats: true)
        let nightRequest = UNNotificationRequest(identifier: "night_reminder", content: nightContent, trigger: nightTrigger)
        
        do {
            try await center.add(eveningRequest)
            try await center.add(nightRequest)
            print("✅ 習慣化サポート通知をスケジュールしました")
        } catch {
            print("❌ 通知のスケジュールに失敗: \(error)")
        }
    }
    
    /// 成功時の即座の励まし通知
    func sendSuccessNotification(preventedCalories: Int) async {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "🎉 素晴らしい判断！"
        content.body = "\(preventedCalories) kcal防ぐことができました。継続が力になります！"
        content.sound = .default
        content.categoryIdentifier = "SUCCESS_FEEDBACK"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "success_\(UUID().uuidString)", content: content, trigger: trigger)
        
        do {
            try await center.add(request)
        } catch {
            print("❌ 成功通知の送信に失敗: \(error)")
        }
    }
    
    /// 継続日数達成時の祝福通知
    func sendStreakAchievementNotification(days: Int) async {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "🏆 継続記録達成！"
        content.body = "\(days)日連続で記録しています！素晴らしい習慣作りですね"
        content.sound = .default
        content.categoryIdentifier = "ACHIEVEMENT"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "streak_\(days)", content: content, trigger: trigger)
        
        do {
            try await center.add(request)
        } catch {
            print("❌ 継続記録通知の送信に失敗: \(error)")
        }
    }
    
    /// 全ての通知をキャンセル
    func cancelAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        print("📵 全ての通知をキャンセルしました")
    }
    
    /// 通知設定状況をチェック
    func checkNotificationSettings() async -> UNAuthorizationStatus {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }
    
    /// 通知カテゴリを設定
    func setupNotificationCategories() {
        let center = UNUserNotificationCenter.current()
        
        // 習慣リマインダーカテゴリ
        let habitReminderCategory = UNNotificationCategory(
            identifier: "HABIT_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        // 成功フィードバックカテゴリ
        let successFeedbackCategory = UNNotificationCategory(
            identifier: "SUCCESS_FEEDBACK",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        // 達成記録カテゴリ
        let achievementCategory = UNNotificationCategory(
            identifier: "ACHIEVEMENT",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([
            habitReminderCategory,
            successFeedbackCategory,
            achievementCategory
        ])
    }
}