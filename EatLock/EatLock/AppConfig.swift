//
//  AppConfig.swift
//  EatLock
//
//  Created by arusu0629 on 2025/07/08.
//

import Foundation

/// アプリケーション設定管理クラス
struct AppConfig {
    
    // MARK: - 広告設定
    
    /// テスト用バナー広告Unit ID
    static let testBannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    
    /// 本番用バナー広告Unit ID (現在はテスト用と同じ)
    /// 本番リリース時は実際の広告IDに変更してください
    static let productionBannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    
    /// 現在の環境に応じた広告Unit IDを取得
    static var currentBannerAdUnitID: String {
        #if DEBUG
        return testBannerAdUnitID
        #else
        return productionBannerAdUnitID
        #endif
    }
    
    // MARK: - アプリ設定
    
    /// アプリの最小サポートiOSバージョン
    static let minimumIOSVersion = "18.0"
    
    /// アプリのバンドルID
    static let bundleIdentifier = "com.arusu0629.EatLock"
    
    // MARK: - 通知設定
    
    /// デフォルトの通知時間（時）
    static let defaultNotificationHours = [20, 21, 22]
    
    /// 通知リマインダーの間隔（秒）
    static let streakReminderInterval: TimeInterval = 7200 // 2時間
} 