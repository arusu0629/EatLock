//
//  BannerAdView.swift
//  EatLock
//
//  Created by arusu0629 on 2025/07/07.
//

import SwiftUI
import GoogleMobileAds

/// SwiftUI用のバナー広告ビュー
struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    let adSize: GADAdSize
    
    @StateObject private var adManager = AdManager.shared
    
    /// テスト広告Unit ID
    static let testAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    
    /// 初期化
    /// - Parameters:
    ///   - adUnitID: 広告ユニットID。指定しない場合はテスト広告IDを使用
    ///   - adSize: 広告サイズ。デフォルトはバナーサイズ
    init(adUnitID: String? = nil, adSize: GADAdSize = GADAdSizeBanner) {
        self.adUnitID = adUnitID ?? Self.testAdUnitID
        self.adSize = adSize
    }
    
    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: adSize)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = UIApplication.shared.activeWindow?.rootViewController
        
        // 広告を読み込み
        adManager.loadBannerAd(for: bannerView)
        
        return bannerView
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {
        // 必要に応じて広告を再読み込み
        if uiView.adUnitID != adUnitID {
            uiView.adUnitID = adUnitID
            adManager.loadBannerAd(for: uiView)
        }
    }
}

/// 固定バナー広告ビュー（画面下部固定用）
struct FixedBannerAdView: View {
    let adUnitID: String?
    let backgroundColor: Color
    
    /// 初期化
    /// - Parameters:
    ///   - adUnitID: 広告ユニットID。指定しない場合はテスト広告IDを使用
    ///   - backgroundColor: 背景色。デフォルトは白
    init(adUnitID: String? = nil, backgroundColor: Color = .white) {
        self.adUnitID = adUnitID
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
            
            BannerAdView(adUnitID: adUnitID)
                .frame(height: 50)
                .background(backgroundColor)
                .clipped()
        }
    }
}

/// 広告エラー表示ビュー
struct AdErrorView: View {
    let error: Error
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title2)
            
            Text("広告の読み込みに失敗しました")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("再試行") {
                retryAction()
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
    }
}

/// 広告読み込み中表示ビュー
struct AdLoadingView: View {
    var body: some View {
        VStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
            
            Text("広告を読み込み中...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
    }
}

/// 広告状態に応じた表示ビュー
struct AdaptiveBannerAdView: View {
    let adUnitID: String?
    
    @StateObject private var adManager = AdManager.shared
    
    init(adUnitID: String? = nil) {
        self.adUnitID = adUnitID
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
            
            Group {
                switch adManager.adLoadingState {
                case .idle, .loading:
                    AdLoadingView()
                case .loaded:
                    BannerAdView(adUnitID: adUnitID)
                        .frame(height: 50)
                case .failed(let error):
                    AdErrorView(error: error) {
                        // 広告読み込みを再試行
                        adManager.retryAdLoading()
                    }
                }
            }
            .background(Color.white)
            .clipped()
        }
    }
}

// MARK: - UIApplication Extension
extension UIApplication {
    var activeWindow: UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first
    }
}