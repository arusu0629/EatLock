//
//  AdService.swift
//  EatLock
//
//  Created by arusu0629 on 2025/07/07.
//

import Foundation
import GoogleMobileAds
// import UserMessagingPlatform // 実際のSDK追加後にコメントアウトを解除
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
        
        // TODO: UserMessagingPlatform SDK追加後に実装
        // UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(...)
        
        // 暫定的な実装（実際のSDK追加後に置き換え）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            // EEA/UK地域の判定（簡易版）
            let locale = Locale.current
            let isEEARegion = self?.isEEARegion(locale: locale) ?? false
            
            if isEEARegion {
                self?.consentStatus = .required
                self?.adLoadingState = .waitingForConsent
                self?.logger.info("EEA地域のため、ユーザー同意が必要です")
            } else {
                self?.consentStatus = .notRequired
                self?.logger.info("非EEA地域のため、ユーザー同意は不要です")
            }
        }
    }
    
    /// EEA地域の判定（簡易版）
    private func isEEARegion(locale: Locale) -> Bool {
        guard let regionCode = locale.region?.identifier else { return false }
        
        // EEA/UK地域のコード（簡易リスト）
        let eeaRegions = [
            "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
            "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
            "PL", "PT", "RO", "SK", "SI", "ES", "SE", "GB", "IS", "LI", "NO"
        ]
        
        return eeaRegions.contains(regionCode)
    }
    
    /// 同意フォームの表示
    func presentConsentForm() {
        guard consentStatus == .required else {
            logger.warning("同意フォームの表示が不要な状態です")
            return
        }
        
        logger.info("同意フォームを表示中...")
        
        // TODO: UserMessagingPlatform SDK追加後に実装
        // UMPConsentForm.present(from: viewController) { [weak self] error in
        //     if let error = error {
        //         self?.logger.error("同意フォーム表示エラー: \(error.localizedDescription)")
        //     } else {
        //         self?.consentStatus = .obtained
        //         self?.logger.info("ユーザー同意を取得しました")
        //     }
        // }
        
        // 暫定的な実装（実際のSDK追加後に置き換え）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.consentStatus = .obtained
            self?.adLoadingState = .idle
            self?.logger.info("ユーザー同意を取得しました（暫定実装）")
        }
    }
    
    /// 初期化結果を処理
    private func handleInitializationResult(_ status: GADInitializationStatus) {
        if status.adapterStatuses.isEmpty {
            logger.error("AdMob SDK初期化失敗: アダプターが見つかりません")
        } else {
            logger.info("AdMob SDK初期化成功: \(status.adapterStatuses.count)個のアダプター")
        }
        setupTestDevices()
    }
    
    /// テストデバイスの設定
    private func setupTestDevices() {
        let request = GADRequestConfiguration()
        request.testDeviceIdentifiers = testDeviceIds
        GADMobileAds.sharedInstance().requestConfiguration = request
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
    
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        logger.error("バナー広告の読み込みに失敗しました: \(error.localizedDescription)")
        adLoadingState = .failed(error)
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