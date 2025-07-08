//
//  BannerAdView.swift
//  EatLock
//
//  Created by arusu0629 on 2025/07/07.
//

import SwiftUI
import GoogleMobileAds
import Combine

/// SwiftUI用のバナー広告ビュー
struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    let adSize: GADAdSize
    let onRetry: (() -> Void)?
    
    @ObservedObject private var adManager = AdManager.shared
    
    /// 初期化
    /// - Parameters:
    ///   - adUnitID: 広告ユニットID。指定しない場合はAppConfigから取得
    ///   - adSize: 広告サイズ。デフォルトはバナーサイズ
    ///   - onRetry: リトライ時のコールバック
    init(adUnitID: String? = nil, adSize: GADAdSize = GADAdSizeBanner, onRetry: (() -> Void)? = nil) {
        self.adUnitID = adUnitID ?? AppConfig.currentBannerAdUnitID
        self.adSize = adSize
        self.onRetry = onRetry
    }
    
    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: adSize)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = findRootViewController()
        
        // 広告を読み込み
        adManager.loadBannerAd(for: bannerView)
        
        return bannerView
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {
        // 必要に応じて広告を再読み込み
        if uiView.adUnitID != adUnitID {
            uiView.adUnitID = adUnitID
            uiView.rootViewController = findRootViewController()
            adManager.loadBannerAd(for: uiView)
        }
    }
    
    /// 安全にrootViewControllerを取得
    private func findRootViewController() -> UIViewController? {
        // UIApplication.shared.activeWindow を使用
        return UIApplication.shared.activeWindow?.rootViewController
    }
    
    /// 広告を再読み込み
    func retryAd(for bannerView: GADBannerView) {
        adManager.loadBannerAd(for: bannerView)
    }
}

/// キーボード状態監視用のObservableObject
class KeyboardObserver: ObservableObject {
    @Published var isKeyboardVisible = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] _ in
                self?.isKeyboardVisible = true
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                self?.isKeyboardVisible = false
            }
            .store(in: &cancellables)
    }
}

/// 固定バナー広告ビュー（画面下部固定用、キーボード対応）
struct FixedBannerAdView: View {
    let adUnitID: String?
    let backgroundColor: Color
    
    @ObservedObject private var keyboardObserver = KeyboardObserver()
    @ObservedObject private var adManager = AdManager.shared
    
    /// 初期化
    /// - Parameters:
    ///   - adUnitID: 広告ユニットID。指定しない場合はAppConfigから取得
    ///   - backgroundColor: 背景色。デフォルトは白
    init(adUnitID: String? = nil, backgroundColor: Color = .white) {
        self.adUnitID = adUnitID
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        // キーボード表示中またはローディング失敗時は非表示
        if !keyboardObserver.isKeyboardVisible && shouldShowAd {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 1)
                
                BannerAdView(adUnitID: adUnitID)
                    .frame(height: 50)
                    .background(backgroundColor)
                    .clipped()
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    /// 広告を表示すべきかどうか
    private var shouldShowAd: Bool {
        switch adManager.adLoadingState {
        case .loaded, .loading:
            return true
        case .idle, .failed:
            return false
        }
    }
}

/// 広告エラー表示ビュー
struct AdErrorView: View {
    let error: Error
    let retryAction: () -> Void
    
    @State private var isRetrying = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title2)
            
            Text("広告の読み込みに失敗しました")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: {
                isRetrying = true
                retryAction()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isRetrying = false
                }
            }) {
                HStack {
                    if isRetrying {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                    Text("再試行")
                }
            }
            .font(.caption)
            .foregroundColor(.blue)
            .disabled(isRetrying)
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

/// 広告状態に応じた表示ビュー（キーボード対応、失敗時非表示）
struct AdaptiveBannerAdView: View {
    let adUnitID: String?
    
    @ObservedObject private var adManager = AdManager.shared
    @ObservedObject private var keyboardObserver = KeyboardObserver()
    @State private var retryTrigger = false
    
    init(adUnitID: String? = nil) {
        self.adUnitID = adUnitID
    }
    
    var body: some View {
        // キーボード表示中は非表示
        if !keyboardObserver.isKeyboardVisible {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 1)
                
                Group {
                    switch adManager.adLoadingState {
                    case .idle:
                        // アイドル状態では何も表示しない
                        EmptyView()
                    case .loading:
                        AdLoadingView()
                    case .loaded:
                        BannerAdView(adUnitID: adUnitID)
                            .frame(height: 50)
                            .id(retryTrigger) // トリガーでビューを再生成
                    case .failed:
                        // 失敗時は完全に非表示（要件に従い）
                        EmptyView()
                    }
                }
                .background(Color.white)
                .clipped()
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

// MARK: - UIApplication Extension
extension UIApplication {
    var activeWindow: UIWindow? {
        // iOS 18.0以上のみサポートのため、常にscene ベースのAPIを使用

        // 1. 現在のアクティブなシーンの keyWindow を取得
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
           let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
            return keyWindow
        }
        
        // 2. フォールバック: アクティブなシーンの最初のウィンドウ
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
           let window = windowScene.windows.first {
            return window
        }
        
        // 3. 最終フォールバック: 最初のシーンの最初のウィンドウ
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
           let window = windowScene.windows.first {
            return window
        }
        
        // 4. 最後の手段: 全てのシーンから最初のウィンドウを取得
        return UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first
    }
}