//
//  AdService.swift
//  EatLock
//
//  Created by arusu0629 on 2025/07/07.
//

import Foundation
import GoogleMobileAds
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
}

/// 広告読み込み状態
enum AdLoadingState {
    case idle
    case loading
    case loaded
    case failed(Error)
}

/// AdMobを使用した広告サービス実装
@MainActor
class AdManager: NSObject, AdServiceProtocol, ObservableObject {
    static let shared = AdManager()
    
    @Published var adLoadingState: AdLoadingState = .idle
    
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
            return true
        default:
            return false
        }
    }
    
    private override init() {
        super.init()
    }
    
    /// 広告SDKを初期化
    func initialize() {
        GADMobileAds.sharedInstance().start { [weak self] status in
            self?.handleInitializationResult(status)
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
        adLoadingState = .loading
        currentBannerView = view
        
        let request = GADRequest()
        view.delegate = self
        view.load(request)
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
    
    var errorDescription: String? {
        switch self {
        case .bannerViewNotFound:
            return "バナービューが見つかりません"
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