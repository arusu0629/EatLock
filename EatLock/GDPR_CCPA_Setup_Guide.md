# GDPR/CCPA対応 セットアップガイド

## 概要

このガイドでは、EatLockアプリにGDPR/CCPA対応のプライバシー配慮機能を実装するための手順を説明します。

## 必要なSDKの追加

### 1. Google Mobile Ads SDK

既に実装されていますが、最新版への更新を推奨します。

### 2. User Messaging Platform SDK

プライバシー同意管理のために、Google User Messaging Platform SDKを追加する必要があります。

#### Xcodeでの追加手順：

1. **Xcodeでプロジェクトを開く**
2. **File > Add Package Dependencies** を選択
3. **以下のURLを入力:**
   ```
   https://github.com/googleads/swift-package-manager-google-mobile-ads.git
   ```
4. **Version Rules:** "Up to Next Major Version" を選択
5. **Add to Target:** EatLock を選択
6. **追加するプロダクト:**
   - GoogleMobileAds
   - GoogleUserMessagingPlatform

#### または、Package.swiftを使用する場合：

```swift
dependencies: [
    .package(
        url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git",
        from: "11.0.0"
    )
],
targets: [
    .target(
        name: "EatLock",
        dependencies: [
            .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
            .product(name: "GoogleUserMessagingPlatform", package: "swift-package-manager-google-mobile-ads")
        ]
    )
]
```

## AdServiceの更新

SDK追加後、以下の手順でAdServiceを更新してください：

### 1. インポート文の更新

`AdService.swift`の先頭で、コメントアウトされているインポート文を有効化：

```swift
import UserMessagingPlatform // コメントアウトを解除
```

### 2. 実際のUMP実装に置き換え

`checkConsentStatus()`メソッド内の暫定実装を、実際のUMP SDKの実装に置き換え：

```swift
func checkConsentStatus() {
    logger.info("ユーザー同意状態を確認中...")
    
    let parameters = UMPRequestParameters()
    parameters.tagForUnderAgeOfConsent = false
    
    UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { [weak self] error in
        DispatchQueue.main.async {
            if let error = error {
                self?.logger.error("同意情報取得エラー: \(error.localizedDescription)")
                self?.consentStatus = .notRequired
            } else {
                let status = UMPConsentInformation.sharedInstance.consentStatus
                switch status {
                case .required:
                    self?.consentStatus = .required
                    self?.adLoadingState = .waitingForConsent
                    self?.logger.info("ユーザー同意が必要です")
                case .notRequired:
                    self?.consentStatus = .notRequired
                    self?.logger.info("ユーザー同意は不要です")
                case .obtained:
                    self?.consentStatus = .obtained
                    self?.logger.info("ユーザー同意を取得済みです")
                default:
                    self?.consentStatus = .unknown
                }
            }
        }
    }
}
```

### 3. 同意フォーム表示の実装

`presentConsentForm()`メソッドの暫定実装を実際の実装に置き換え：

```swift
func presentConsentForm() {
    guard consentStatus == .required else {
        logger.warning("同意フォームの表示が不要な状態です")
        return
    }
    
    logger.info("同意フォームを表示中...")
    
    guard UMPConsentForm.canPresent else {
        logger.error("同意フォームを表示できません")
        return
    }
    
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first,
          let rootViewController = window.rootViewController else {
        logger.error("ルートビューコントローラーが見つかりません")
        return
    }
    
    UMPConsentForm.present(from: rootViewController) { [weak self] error in
        DispatchQueue.main.async {
            if let error = error {
                self?.logger.error("同意フォーム表示エラー: \(error.localizedDescription)")
            } else {
                self?.consentStatus = .obtained
                self?.adLoadingState = .idle
                self?.logger.info("ユーザー同意を取得しました")
            }
        }
    }
}
```

## プライバシー設定の確認

### Info.plist

以下の設定が正しく追加されていることを確認：

- `NSUserTrackingUsageDescription`: ユーザー追跡の説明
- `GADApplicationIdentifier`: AdMob App ID
- `NSAppTransportSecurity`: ネットワークセキュリティ設定

### AdMob Console設定

1. **AdMob Console**にログイン
2. **プライバシーとメッセージング**セクションで以下を設定：
   - EEA/UK向けメッセージの作成
   - CCPA向けメッセージの作成
   - 適切な同意プロバイダーの選択

## テスト方法

### 1. EEA地域でのテスト

デバイスの地域設定をEEA地域（ドイツ、フランスなど）に変更してテスト：

1. **設定 > 一般 > 言語と地域**
2. **地域をEEA地域に変更**
3. **アプリを再起動**
4. **同意フォームが表示されることを確認**

### 2. 非EEA地域でのテスト

デバイスの地域設定を非EEA地域（日本、アメリカなど）に変更してテスト：

1. **設定 > 一般 > 言語と地域**
2. **地域を非EEA地域に変更**
3. **アプリを再起動**
4. **同意フォームが表示されないことを確認**

### 3. 同意状態のリセット

テスト中に同意状態をリセットする場合：

```swift
// デバッグ用のリセットメソッド（本番では削除）
#if DEBUG
func resetConsentForTesting() {
    UMPConsentInformation.sharedInstance.reset()
    consentStatus = .unknown
    adLoadingState = .idle
}
#endif
```

## 注意事項

1. **本番環境では、テスト用のApp IDを実際のApp IDに変更してください**
2. **プライバシーポリシーの更新が必要です**
3. **App Store審査時には、GDPR/CCPA対応について説明が必要な場合があります**
4. **定期的にGoogleの最新ガイドラインを確認してください**

## 関連リンク

- [Google Mobile Ads SDK Documentation](https://developers.google.com/admob/ios/quick-start)
- [User Messaging Platform Documentation](https://developers.google.com/admob/ump/ios/quick-start)
- [GDPR Compliance Guide](https://support.google.com/admob/answer/9760862)
- [CCPA Compliance Guide](https://support.google.com/admob/answer/9561022) 