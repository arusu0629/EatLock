//
//  AdService.swift
//  EatLock
//
//  Created by arusu0629 on 2025/07/07.
//

import Foundation
import GoogleMobileAds
import UserMessagingPlatform // 実際のSDK追加後にコメントアウトを解除
import SwiftUI
import os.log

/// 広告サービスのプロトコル
protocol AdServiceProtocol {
    /// 広告SDKを初期化
    func initialize()
    
    /// バナー広告を読み込み
    func loadBannerAd(for view: GADBannerView)
    
    /// 広告読み込みを再試行
    func retryAdLoading()
    
    /// 広告が利用可能かどうか
    var isAdAvailable: Bool { get }
    
    /// 広告読み込み状態の通知
    var adLoadingStatePublisher: Published<AdLoadingState>.Publisher { get }
    
    /// 広告読み込み状態をリセット
    func resetAdLoadingState()
    
    /// ユーザー同意状態の確認
    func checkConsentStatus()
    
    /// 同意フォームの表示
    func presentConsentForm()
}

/// 広告読み込み状態
enum AdLoadingState {
    case idle
    case loading
    case loaded
    case failed(Error)
    case waitingForConsent // ユーザー同意待ち
}

/// ユーザー同意状態
enum ConsentStatus {
    case unknown
    case required
    case notRequired
    case obtained
}

/// AdMobを使用した広告サービス実装
@MainActor
class AdManager: NSObject, AdServiceProtocol, ObservableObject {
    static let shared = AdManager()
    
    @Published var adLoadingState: AdLoadingState = .idle
    @Published var consentStatus: ConsentStatus = .unknown
    
    // 現在のバナービューの弱参照（簡素化）
    private weak var currentBannerView: GADBannerView?
    
    // ログ用のOSLog
    private let logger = Logger(subsystem: "com.arusu0629.EatLock", category: "AdService")
    
    // Published プロパティへのアクセス
    var adLoadingStatePublisher: Published<AdLoadingState>.Publisher {
        return $adLoadingState
    }
    
    private lazy var testDeviceIds: [String] = {
        #if DEBUG
        return [
            GADSimulatorID,  // シミュレーター用
            // 実機のテストデバイスIDをここに追加
        ]
        #else
        return [] // 本番環境ではテストデバイスIDを使用しない
        #endif
    }()
    
    /// 広告が利用可能かどうか
    var isAdAvailable: Bool {
        switch adLoadingState {
        case .loaded:
            return consentStatus == .obtained || consentStatus == .notRequired
        default:
            return false
        }
    }
    
    private override init() {
        super.init()
    }
    
    /// 広告SDKを初期化
    func initialize() {
        // プライバシー同意状態を先に確認
        checkConsentStatus()
        
        // AdMob SDKの初期化
        GADMobileAds.sharedInstance().start { [weak self] status in
            self?.handleInitializationResult(status)
        }
    }
    
    /// ユーザー同意状態の確認
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
                        self?.logger.warning("不明な同意状態です")
                    }
                }
            }
        }
    }
    
    /// 同意フォームの表示
    func presentConsentForm() {
        guard consentStatus == .required else {
            logger.warning("同意フォームの表示が不要な状態です")
            return
        }
        
        logger.info("同意フォームを表示中...")
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            logger.error("ルートビューコントローラーが見つかりません")
            return
        }
        
        UMPConsentForm.load { [weak self] form, loadError in
            DispatchQueue.main.async {
                if let loadError = loadError {
                    self?.logger.error("同意フォーム読み込みエラー: \(loadError.localizedDescription)")
                    return
                }
                
                guard let form = form else {
                    self?.logger.error("同意フォームが取得できませんでした")
                    return
                }
                
                form.present(from: rootViewController) { [weak self] dismissError in
                    if let dismissError = dismissError {
                        self?.logger.error("同意フォーム表示エラー: \(dismissError.localizedDescription)")
                    } else {
                        self?.consentStatus = .obtained
                        self?.adLoadingState = .idle
                        self?.logger.info("ユーザー同意を取得しました")
                    }
                }
            }
        }
    }
    
    /// 初期化結果を処理
    private func handleInitializationResult(_ status: GADInitializationStatus) {
        // 新しいSDKバージョンではadapterStatusesプロパティは利用できません
        logger.info("AdMob SDK初期化完了")
        setupTestDevices()
    }
    
    /// テストデバイスの設定
    private func setupTestDevices() {
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = testDeviceIds
    }
    
    /// バナー広告を読み込み
    func loadBannerAd(for view: GADBannerView) {
        // ユーザー同意が必要な場合は読み込みを待機
        guard consentStatus == .obtained || consentStatus == .notRequired else {
            logger.info("ユーザー同意待ちのため、広告読み込みを待機します")
            adLoadingState = .waitingForConsent
            return
        }
        
        adLoadingState = .loading
        currentBannerView = view
        
        let request = GADRequest()
        view.delegate = self
        view.load(request)
        
        logger.info("バナー広告の読み込みを開始しました")
    }
    
    /// 広告読み込みを再試行
    func retryAdLoading() {
        guard let bannerView = currentBannerView else {
            logger.warning("再試行に失敗: バナービューが見つかりません")
            adLoadingState = .failed(AdLoadingError.bannerViewNotFound)
            return
        }
        
        logger.info("広告の再読み込みを開始")
        loadBannerAd(for: bannerView)
    }
    
    /// 広告読み込み状態をリセット
    func resetAdLoadingState() {
        adLoadingState = .idle
    }
    
    /// デバッグ用のリセットメソッド（テスト用）
    #if DEBUG
    func resetConsentForTesting() {
        UMPConsentInformation.sharedInstance.reset()
        consentStatus = .unknown
        adLoadingState = .idle
        logger.info("同意状態をリセットしました（テスト用）")
    }
    #endif
}

/// 広告読み込みエラー
enum AdLoadingError: Error, LocalizedError {
    case bannerViewNotFound
    case consentRequired
    
    var errorDescription: String? {
        switch self {
        case .bannerViewNotFound:
            return "バナービューが見つかりません"
        case .consentRequired:
            return "ユーザー同意が必要です"
        }
    }
}

// MARK: - GADBannerViewDelegate
extension AdManager: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        logger.info("バナー広告の読み込みが成功しました")
        adLoadingState = .loaded
    }
    
    nonisolated func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        logger.error("バナー広告の読み込みに失敗しました: \(error.localizedDescription)")
        Task { @MainActor in
            adLoadingState = .failed(error)
        }
    }
    
    func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        logger.debug("バナー広告が画面を表示します")
    }
    
    func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
        logger.debug("バナー広告が画面を非表示にします")
    }
    
    func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
        logger.debug("バナー広告が画面を非表示にしました")
    }
}