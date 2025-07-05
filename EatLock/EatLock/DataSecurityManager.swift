//
//  DataSecurityManager.swift
//  EatLock
//
//  Created by arusu0629 on 2025/06/25.
//

import Foundation
import SwiftData
import LocalAuthentication
import CryptoKit

/// データセキュリティとプライバシー保護を管理するクラス
class DataSecurityManager {
    static let shared = DataSecurityManager()
    
    private init() {}
    
    // MARK: - Model Configuration with Security
    
    /// セキュアなModelContainerを作成
    static func createSecureModelContainer() throws -> ModelContainer {
        // SwiftDataでの暗号化設定
        // 注意: SwiftDataはiOS 17以降でファイルシステムレベルでの暗号化を提供
        // 追加のセキュリティが必要な場合は、データ保存前に個別に暗号化を行う
        
        let configuration = ModelConfiguration(
            schema: Schema([ActionLog.self]),
            isStoredInMemoryOnly: false,
            allowsSave: true
            // CloudKitは使用しない（プライバシー保護のため）
        )
        
        return try ModelContainer(for: ActionLog.self, configurations: configuration)
    }
    
    // MARK: - Biometric Authentication
    
    /// 生体認証が利用可能かチェック
    func isBiometricAuthenticationAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// 生体認証を実行
    func authenticateWithBiometrics() async throws -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "パスコードを使用"
        
        do {
            let result = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "EatLockのデータにアクセスするために認証が必要です"
            )
            return result
        } catch {
            throw BiometricAuthError.authenticationFailed(error)
        }
    }
    
    // MARK: - Data Encryption (Additional Layer)
    
    /// 暗号化キーを生成する
    func generateEncryptionKey() -> Data {
        let key = SymmetricKey(size: .bits256)
        return key.withUnsafeBytes { Data($0) }
    }
    
    /// デバイス固有の暗号化キーを取得/生成する
    func getDeviceEncryptionKey() -> Data {
        let keyIdentifier = "EatLock_DeviceEncryptionKey"
        
        if let existingKey = UserDefaults.standard.data(forKey: keyIdentifier) {
            return existingKey
        }
        
        let newKey = generateEncryptionKey()
        UserDefaults.standard.set(newKey, forKey: keyIdentifier)
        return newKey
    }
    
    /// 文字列データの暗号化（追加のセキュリティレイヤー用）
    func encryptString(_ string: String, using key: Data) throws -> Data {
        guard let data = string.data(using: .utf8) else {
            throw DataSecurityError.encodingFailed
        }
        
        do {
            let symmetricKey = SymmetricKey(data: key)
            let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
            return sealedBox.combined ?? Data()
        } catch {
            throw DataSecurityError.encryptionFailed
        }
    }
    
    /// 暗号化されたデータの復号化
    func decryptData(_ encryptedData: Data, using key: Data) throws -> String {
        do {
            let symmetricKey = SymmetricKey(data: key)
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
            
            guard let string = String(data: decryptedData, encoding: .utf8) else {
                throw DataSecurityError.decodingFailed
            }
            
            return string
        } catch {
            throw DataSecurityError.decryptionFailed
        }
    }
    
    // MARK: - Privacy Settings
    
    /// プライバシー設定の管理
    struct PrivacySettings {
        var requireBiometricAuth: Bool = false
        var autoDeleteAfterDays: Int? = nil
        var allowScreenshots: Bool = false
        var allowBackgroundAppRefresh: Bool = false
        
        static let `default` = PrivacySettings()
    }
    
    /// プライバシー設定の保存
    func savePrivacySettings(_ settings: PrivacySettings) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(settings) {
            UserDefaults.standard.set(encoded, forKey: "EatLock_PrivacySettings")
        }
    }
    
    /// プライバシー設定の読み込み
    func loadPrivacySettings() -> PrivacySettings {
        guard let data = UserDefaults.standard.data(forKey: "EatLock_PrivacySettings"),
              let settings = try? JSONDecoder().decode(PrivacySettings.self, from: data) else {
            return .default
        }
        return settings
    }
    
    // MARK: - Data Cleanup
    
    /// 古いデータの自動削除
    func performDataCleanupIfNeeded(repository: ActionLogRepository) {
        let settings = loadPrivacySettings()
        
        guard let deleteAfterDays = settings.autoDeleteAfterDays else { return }
        
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(byAdding: .day, value: -deleteAfterDays, to: Date()) else {
            return
        }
        
        do {
            try repository.deleteOldActionLogs(olderThan: cutoffDate)
            print("古いデータを削除しました: \(deleteAfterDays)日以前")
        } catch {
            print("データ削除エラー: \(error)")
        }
    }
    
    // MARK: - App Background Security
    
    /// アプリがバックグラウンドに移行する際のセキュリティ処理
    func handleAppWillResignActive() {
        let settings = loadPrivacySettings()
        
        if !settings.allowScreenshots {
            // スクリーンショット防止のための処理
            // 実際の実装では、センシティブな情報を隠すViewを表示
        }
    }
    
    /// アプリがフォアグラウンドに復帰する際のセキュリティ処理
    func handleAppDidBecomeActive() async {
        let settings = loadPrivacySettings()
        
        if settings.requireBiometricAuth {
            do {
                let authenticated = try await authenticateWithBiometrics()
                if !authenticated {
                    // 認証失敗時の処理
                    print("生体認証に失敗しました")
                }
            } catch {
                print("認証エラー: \(error)")
            }
        }
    }
}

// MARK: - Privacy Settings Codable Extension
extension DataSecurityManager.PrivacySettings: Codable {}

// MARK: - Error Types
enum BiometricAuthError: LocalizedError {
    case authenticationFailed(Error)
    case notAvailable
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let error):
            return "生体認証に失敗しました: \(error.localizedDescription)"
        case .notAvailable:
            return "生体認証が利用できません"
        }
    }
}

enum DataSecurityError: LocalizedError {
    case encodingFailed
    case decodingFailed
    case encryptionFailed
    case decryptionFailed
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "データのエンコードに失敗しました"
        case .decodingFailed:
            return "データのデコードに失敗しました"
        case .encryptionFailed:
            return "データの暗号化に失敗しました"
        case .decryptionFailed:
            return "データの復号化に失敗しました"
        }
    }
} 