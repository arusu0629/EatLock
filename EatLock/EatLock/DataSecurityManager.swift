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
import Security

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
    
    // MARK: - Keychain Operations
    
    /// Keychainにデータを保存
    private func saveToKeychain(_ data: Data, forKey key: String) -> Bool {
        let service = "com.eatlock.encryption"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // 既存のアイテムを削除
        SecItemDelete(query as CFDictionary)
        
        // 新しいアイテムを追加
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Keychainからデータを読み込み
    private func loadFromKeychain(forKey key: String) -> Data? {
        let service = "com.eatlock.encryption"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        }
        
        return nil
    }
    
    /// Keychainからデータを削除
    private func deleteFromKeychain(forKey key: String) -> Bool {
        let service = "com.eatlock.encryption"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    /// デバイス固有の暗号化キーを取得/生成する
    /// キャッシュ機能付きでパフォーマンスを向上
    private var cachedEncryptionKey: Data?
    private let keyCache = NSLock()
    
    func getDeviceEncryptionKey() -> Data {
        keyCache.lock()
        defer { keyCache.unlock() }
        
        // キャッシュされたキーがあれば返す
        if let cachedKey = cachedEncryptionKey {
            return cachedKey
        }
        
        let keyIdentifier = "EatLock_DeviceEncryptionKey"
        
        // まずKeychainから読み込みを試行
        if let existingKey = loadFromKeychain(forKey: keyIdentifier) {
            cachedEncryptionKey = existingKey
            return existingKey
        }
        
        // UserDefaultsから既存のキーを移行（後方互換性のため）
        let userDefaultsKey = "EatLock_DeviceEncryptionKey"
        if let legacyKey = UserDefaults.standard.data(forKey: userDefaultsKey) {
            // Keychainに移行
            if saveToKeychain(legacyKey, forKey: keyIdentifier) {
                // 移行成功後、UserDefaultsから削除
                UserDefaults.standard.removeObject(forKey: userDefaultsKey)
                print("暗号化キーをUserDefaultsからKeychainに移行しました")
                cachedEncryptionKey = legacyKey
                return legacyKey
            } else {
                // Keychain保存に失敗した場合でも、レガシーキーを使用
                print("警告: Keychainへの移行に失敗しましたが、レガシーキーを使用します")
                cachedEncryptionKey = legacyKey
                return legacyKey
            }
        }
        
        // 新しいキーを生成してKeychainに保存
        let newKey = generateEncryptionKey()
        if saveToKeychain(newKey, forKey: keyIdentifier) {
            print("新しい暗号化キーをKeychainに保存しました")
            cachedEncryptionKey = newKey
            return newKey
        } else {
            // Keychainへの保存に失敗した場合の緊急フォールバック
            print("警告: Keychainへの保存に失敗しました。一時的なキーを使用します。")
            // 一時的なキーはキャッシュしない（次回取得時に再試行）
            return newKey
        }
    }
    
    /// キャッシュをクリアする（テスト用）
    func clearKeyCache() {
        keyCache.lock()
        cachedEncryptionKey = nil
        keyCache.unlock()
    }
    
    /// 暗号化キーを削除する（アプリリセット時などに使用）
    func deleteDeviceEncryptionKey() -> Bool {
        let keyIdentifier = "EatLock_DeviceEncryptionKey"
        
        // キャッシュをクリア
        clearKeyCache()
        
        // Keychainから削除
        let keychainDeleted = deleteFromKeychain(forKey: keyIdentifier)
        
        // UserDefaultsからも削除（レガシーキーがある場合）
        let userDefaultsKey = "EatLock_DeviceEncryptionKey"
        if UserDefaults.standard.data(forKey: userDefaultsKey) != nil {
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
            print("UserDefaultsからレガシーキーを削除しました")
        }
        
        return keychainDeleted
    }
    
    /// 文字列データの暗号化（追加のセキュリティレイヤー用）
    func encryptString(_ string: String, using key: Data) throws -> Data {
        // 暗号化キーが空または短すぎる場合はエラーを投げる
        guard !key.isEmpty && key.count >= 32 else {
            throw DataSecurityError.invalidKeySize
        }
        
        guard let data = string.data(using: .utf8) else {
            throw DataSecurityError.encodingFailed
        }
        
        do {
            let symmetricKey = SymmetricKey(data: key)
            let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
            
            // combined プロパティが nil の場合は暗号化失敗として扱う
            guard let combinedData = sealedBox.combined else {
                throw DataSecurityError.encryptionFailed
            }
            
            return combinedData
        } catch {
            throw DataSecurityError.encryptionFailed
        }
    }
    
    /// 暗号化されたデータの復号化
    func decryptData(_ encryptedData: Data, using key: Data) throws -> String {
        // 暗号化キーが空または短すぎる場合はエラーを投げる
        guard !key.isEmpty && key.count >= 32 else {
            throw DataSecurityError.invalidKeySize
        }
        
        // 暗号化されたデータが空の場合は即座にエラーを投げる
        guard !encryptedData.isEmpty else {
            throw DataSecurityError.emptyData
        }
        
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
    case keychainSaveFailed
    case keychainLoadFailed
    case keychainDeleteFailed
    case invalidKeySize
    case emptyData
    
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
        case .keychainSaveFailed:
            return "Keychainへの保存に失敗しました"
        case .keychainLoadFailed:
            return "Keychainからの読み込みに失敗しました"
        case .keychainDeleteFailed:
            return "Keychainからの削除に失敗しました"
        case .invalidKeySize:
            return "暗号化キーのサイズが無効です"
        case .emptyData:
            return "暗号化データが空です"
        }
    }
} 