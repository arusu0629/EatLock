//
//  AdService.swift
//  EatLock
//
//  Created by arusu0629 on 2025/07/07.
//

import Foundation
import GoogleMobileAds
import SwiftUI

/// 広告サービスのプロトコル
protocol AdServiceProtocol {
    /// 広告SDKを初期化
    func initialize()
    
    /// バナー広告を読み込み
    func loadBannerAd(for view: GADBannerView)
    
    /// 広告が利用可能かどうか
    var isAdAvailable: Bool { get }
    
    /// 広告読み込み状態の通知
    var adLoadingStatePublisher: Published<AdLoadingState>.Publisher { get }
}

/// 広告読み込み状態
enum AdLoadingState {
    case idle
    case loading
    case loaded
    case failed(Error)
}

/// AdMobを使用した広告サービス実装
class AdManager: NSObject, AdServiceProtocol, ObservableObject {
    static let shared = AdManager()
    
    @Published var adLoadingState: AdLoadingState = .idle
    
    // Published プロパティへのアクセス
    var adLoadingStatePublisher: Published<AdLoadingState>.Publisher {
        return $adLoadingState
    }
    
    private var testDeviceIds: [String] = []
    
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
        setupTestDeviceIds()
    }
    
    /// テストデバイスIDの設定
    private func setupTestDeviceIds() {
        testDeviceIds = [
            GADSimulatorID,  // シミュレーター用
            // 実機のテストデバイスIDをここに追加
        ]
    }
    
    /// 広告SDKを初期化
    func initialize() {
        GADMobileAds.sharedInstance().start { [weak self] status in
            DispatchQueue.main.async {
                print("AdMob SDK initialized with status: \(status)")
                self?.setupTestDevices()
            }
        }
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
        
        let request = GADRequest()
        view.delegate = self
        view.load(request)
    }
    
    /// 広告読み込みを再試行
    func retryAdLoading() {
        adLoadingState = .loading
    }
}

// MARK: - GADBannerViewDelegate
extension AdManager: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("Banner ad loaded successfully")
        adLoadingState = .loaded
    }
    
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        print("Banner ad failed to load: \(error.localizedDescription)")
        adLoadingState = .failed(error)
    }
    
    func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("Banner ad will present screen")
    }
    
    func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("Banner ad will dismiss screen")
    }
    
    func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("Banner ad did dismiss screen")
    }
}