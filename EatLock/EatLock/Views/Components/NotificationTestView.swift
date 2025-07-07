//
//  NotificationTestView.swift
//  EatLock
//
//  Created by Issue #33 on 2025/07/04.
//

import SwiftUI
import UserNotifications

/// 通知機能をテストするためのビュー
struct NotificationTestView: View {
    @ObservedObject private var notificationManager = NotificationManager.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var detailStatus: NotificationPermissionStatus?
    
    var body: some View {
        List {
                // 権限状態セクション
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("権限状態")
                                .font(.headline)
                            Spacer()
                            StatusIndicator(status: notificationManager.authorizationStatus)
                        }
                        
                        Text(statusDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("通知権限")
                }
                
                // 詳細情報セクション
                if let status = detailStatus {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(title: "アラート", value: settingDescription(status.alertSetting))
                            DetailRow(title: "バッジ", value: settingDescription(status.badgeSetting))
                            DetailRow(title: "サウンド", value: settingDescription(status.soundSetting))
                            
                            if let requestDate = status.requestDate {
                                DetailRow(title: "リクエスト日時", value: formatDate(requestDate))
                            }
                        }
                    } header: {
                        Text("詳細設定")
                    }
                }
                
                // アクションセクション
                Section {
                    VStack(spacing: 12) {
                        // 権限リクエスト
                        Button(action: {
                            Task {
                                await notificationManager.requestPermission()
                                await updateDetailStatus()
                            }
                        }) {
                            HStack {
                                Image(systemName: "bell.badge")
                                    .foregroundColor(.blue)
                                Text("権限をリクエスト")
                            }
                        }
                        .disabled(!canRequestPermission)
                        
                        // 設定アプリへの誘導（権限が拒否されている場合）
                        if notificationManager.authorizationStatus == .denied {
                            Button(action: {
                                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "gear")
                                        .foregroundColor(.orange)
                                    Text("設定アプリで権限を有効にする")
                                }
                            }
                        }
                        
                        // テスト通知
                        Button(action: {
                            Task {
                                await notificationManager.scheduleTestNotification()
                                showAlert(message: "テスト通知をスケジュールしました")
                            }
                        }) {
                            HStack {
                                Image(systemName: "bell.circle")
                                    .foregroundColor(.green)
                                Text("テスト通知を発火")
                            }
                        }
                        .disabled(!canScheduleNotification)
                        
                        // 習慣化サポート通知
                        Button(action: {
                            Task {
                                // 毎日20時に通知
                                var dateComponents = DateComponents()
                                dateComponents.hour = 20
                                dateComponents.minute = 0
                                
                                await notificationManager.scheduleHabitReminderNotification(at: dateComponents)
                                showAlert(message: "習慣化サポート通知をスケジュールしました（毎日20時）")
                            }
                        }) {
                            HStack {
                                Image(systemName: "clock.badge")
                                    .foregroundColor(.orange)
                                Text("習慣化サポート通知をスケジュール")
                            }
                        }
                        .disabled(!canScheduleNotification)
                        
                        // 全通知削除
                        Button(action: {
                            notificationManager.removeAllNotifications()
                            showAlert(message: "全ての通知を削除しました")
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                Text("全ての通知を削除")
                            }
                        }
                    }
                } header: {
                    Text("アクション")
                }
                
                // エラー情報
                if let error = notificationManager.lastError {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("エラー")
                                .font(.headline)
                                .foregroundColor(.red)
                            
                            Text(error.localizedDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 8)
                    } header: {
                        Text("エラー情報")
                    }
                }
        }
        .navigationTitle("通知テスト")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("更新") {
                    Task {
                        await updateDetailStatus()
                    }
                }
            }
        }
        .alert("通知", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .task {
            await updateDetailStatus()
        }
    }
    
    // MARK: - Private Methods
    
    private func updateDetailStatus() async {
        detailStatus = await notificationManager.getDetailedPermissionStatus()
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showingAlert = true
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func settingDescription(_ setting: UNNotificationSetting) -> String {
        switch setting {
        case .enabled:
            return "有効"
        case .disabled:
            return "無効"
        case .notSupported:
            return "サポート外"
        @unknown default:
            return "不明"
        }
    }
    
    private var statusDescription: String {
        switch notificationManager.authorizationStatus {
        case .notDetermined:
            return "通知権限がまだ決定されていません。権限をリクエストしてください。"
        case .denied:
            return "通知権限が拒否されています。下の「設定アプリで権限を有効にする」ボタンから設定を変更してください。"
        case .authorized:
            return "通知権限が許可されています。通知を送信できます。"
        case .provisional:
            return "仮の通知権限が許可されています。"
        case .ephemeral:
            return "一時的な通知権限が許可されています。"
        @unknown default:
            return "不明な権限状態です。"
        }
    }
    
    private var canRequestPermission: Bool {
        return notificationManager.authorizationStatus == .notDetermined
    }
    
    private var canScheduleNotification: Bool {
        return notificationManager.authorizationStatus == .authorized
    }
}

// MARK: - Supporting Views

struct StatusIndicator: View {
    let status: UNAuthorizationStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    private var color: Color {
        switch status {
        case .notDetermined:
            return .gray
        case .denied:
            return .red
        case .authorized:
            return .green
        case .provisional:
            return .yellow
        case .ephemeral:
            return .blue
        @unknown default:
            return .gray
        }
    }
    
    private var text: String {
        switch status {
        case .notDetermined:
            return "未決定"
        case .denied:
            return "拒否"
        case .authorized:
            return "許可"
        case .provisional:
            return "仮許可"
        case .ephemeral:
            return "一時"
        @unknown default:
            return "不明"
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NotificationTestView()
    }
}