//
//  NavigationRouter.swift
//  EatLock
//
//  Created by NavigationSystem on 2025/06/25.
//

import SwiftUI

/// ナビゲーション状態を管理するRouter
/// iOS 16以降のNavigationStackに対応
/// 
/// ⚠️ 重要: このシングルトンは`@State`ではなく`private let`で保存してください
/// 例: `private let router = NavigationRouter.shared`
@Observable
class NavigationRouter {
    /// ナビゲーションパス（NavigationStack用）
    var navigationPath = NavigationPath()
    
    /// モーダル表示状態
    var presentedSheet: NavigationDestination?
    
    /// フルスクリーン表示状態
    var presentedFullScreen: NavigationDestination?
    
    /// アラート表示状態
    var alertInfo: AlertInfo?
    
    /// 共有インスタンス
    static let shared = NavigationRouter()
    
    private init() {}
    
    // MARK: - Navigation Methods
    
    /// 画面をプッシュ
    func push(_ destination: NavigationDestination) {
        navigationPath.append(destination)
    }
    
    /// 前の画面に戻る
    func pop() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }
    
    /// ルートまで戻る
    func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }
    
    /// 特定の画面までポップ
    func popTo(_ destination: NavigationDestination) {
        // NavigationPathは型安全性のため、直接的な操作は制限される
        // 必要に応じて、カスタムロジックを実装
    }
    
    // MARK: - Modal Methods
    
    /// シートを表示
    func presentSheet(_ destination: NavigationDestination) {
        presentedSheet = destination
    }
    
    /// シートを閉じる
    func dismissSheet() {
        presentedSheet = nil
    }
    
    /// フルスクリーン表示
    func presentFullScreen(_ destination: NavigationDestination) {
        presentedFullScreen = destination
    }
    
    /// フルスクリーンを閉じる
    func dismissFullScreen() {
        presentedFullScreen = nil
    }
    
    // MARK: - Alert Methods
    
    /// アラートを表示
    func showAlert(title: String, message: String, actions: [AlertAction] = []) {
        alertInfo = AlertInfo(title: title, message: message, actions: actions)
    }
    
    /// エラーアラートを表示
    func showError(_ error: Error) {
        showAlert(title: "エラー", message: error.localizedDescription)
    }
    
    /// 確認アラートを表示
    func showConfirmation(
        title: String,
        message: String,
        confirmAction: @escaping () -> Void,
        cancelAction: (() -> Void)? = nil
    ) {
        let actions = [
            AlertAction(title: "キャンセル", style: .cancel, action: cancelAction),
            AlertAction(title: "確認", style: .default, action: confirmAction)
        ]
        alertInfo = AlertInfo(title: title, message: message, actions: actions)
    }
    
    /// アラートを閉じる
    func dismissAlert() {
        alertInfo = nil
    }
    
    // MARK: - Utility Methods
    
    /// 現在のナビゲーションの深さを取得
    var navigationDepth: Int {
        navigationPath.count
    }
    
    /// ナビゲーションスタックが空かどうか
    var isAtRoot: Bool {
        navigationPath.isEmpty
    }
    
    /// 現在モーダルが表示されているかどうか
    var hasModalPresented: Bool {
        presentedSheet != nil || presentedFullScreen != nil
    }
}

// MARK: - Alert Support Types

/// アラート情報を格納する構造体
struct AlertInfo {
    let title: String
    let message: String
    let actions: [AlertAction]
    
    init(title: String, message: String, actions: [AlertAction] = []) {
        self.title = title
        self.message = message
        self.actions = actions.isEmpty ? [AlertAction(title: "OK", style: .default)] : actions
    }
}

/// アラートアクションを定義する構造体
struct AlertAction {
    let title: String
    let style: AlertActionStyle
    let action: (() -> Void)?
    
    init(title: String, style: AlertActionStyle = .default, action: (() -> Void)? = nil) {
        self.title = title
        self.style = style
        self.action = action
    }
}

/// アラートアクションのスタイル
enum AlertActionStyle {
    case `default`
    case cancel
    case destructive
}

// MARK: - SwiftUI Extensions

extension View {
    /// NavigationRouterを使用してナビゲーション機能を追加
    func withNavigationRouter(_ router: NavigationRouter = NavigationRouter.shared) -> some View {
        NavigationRouterWrapper(content: self, router: router)
    }
}

/// NavigationRouterの機能を提供するラッパービュー
private struct NavigationRouterWrapper<Content: View>: View {
    let content: Content
    let router: NavigationRouter
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        content
            .sheet(item: Binding(
                get: { router.presentedSheet },
                set: { _ in router.dismissSheet() }
            )) { destination in
                destination.destination(repository: ActionLogRepository(modelContext: modelContext))
                    .modelContainer(modelContext.container)
            }
            .fullScreenCover(item: Binding(
                get: { router.presentedFullScreen },
                set: { _ in router.dismissFullScreen() }
            )) { destination in
                destination.destination(repository: ActionLogRepository(modelContext: modelContext))
                    .modelContainer(modelContext.container)
            }
            .alert(
                router.alertInfo?.title ?? "",
                isPresented: Binding(
                    get: { router.alertInfo != nil },
                    set: { _ in router.dismissAlert() }
                )
            ) {
                if let alertInfo = router.alertInfo {
                    ForEach(alertInfo.actions.indices, id: \.self) { index in
                        let alertAction = alertInfo.actions[index]
                        Button(alertAction.title, role: alertAction.style.buttonRole) {
                            alertAction.action?()
                        }
                    }
                }
            } message: {
                if let alertInfo = router.alertInfo {
                    Text(alertInfo.message)
                }
            }
    }
}

// MARK: - NavigationDestination Identifiable Conformance

extension NavigationDestination: Identifiable {
    var id: String {
        switch self {
        case .home:
            return "home"
        case .logDetail(let log):
            return "logDetail_\(log.id)"
        case .settings:
            return "settings"
        case .statistics:
            return "statistics"
        case .tutorial:
            return "tutorial"
        case .notificationTest:
            return "notificationTest"
        }
    }
}

// MARK: - AlertActionStyle Extension

extension AlertActionStyle {
    var buttonRole: ButtonRole? {
        switch self {
        case .default:
            return nil
        case .cancel:
            return .cancel
        case .destructive:
            return .destructive
        }
    }
}