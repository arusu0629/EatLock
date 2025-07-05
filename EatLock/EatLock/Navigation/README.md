# ナビゲーション管理システム

## 概要
EatLock アプリのナビゲーション管理システムは、iOS 16以降の `NavigationStack` を使用して実装されています。
型安全性とモダンなナビゲーション体験を提供します。

## 構成ファイル

### 1. NavigationDestination.swift
- **目的**: ナビゲーション先を定義するenum
- **機能**: 
  - 型安全なナビゲーション管理
  - ビュー生成機能
  - 将来的な拡張画面の準備

### 2. NavigationRouter.swift
- **目的**: ナビゲーション状態の管理とルーティング
- **機能**:
  - NavigationStack パス管理
  - モーダル表示管理
  - アラート管理
  - ユーティリティメソッド

### 3. RootView.swift
- **目的**: アプリケーションのルートビュー
- **機能**:
  - NavigationStack の設定
  - ナビゲーション統合

## 使用方法

### 基本的な画面遷移

```swift
// 画面をプッシュ
NavigationRouter.shared.push(.settings)

// 前の画面に戻る
NavigationRouter.shared.pop()

// ルートまで戻る
NavigationRouter.shared.popToRoot()
```

### モーダル表示

```swift
// シートを表示
NavigationRouter.shared.presentSheet(.logDetail(log))

// フルスクリーンを表示
NavigationRouter.shared.presentFullScreen(.tutorial)

// モーダルを閉じる
NavigationRouter.shared.dismissSheet()
```

### アラート表示

```swift
// 基本的なアラート
NavigationRouter.shared.showAlert(
    title: "エラー",
    message: "処理に失敗しました"
)

// 確認アラート
NavigationRouter.shared.showConfirmation(
    title: "削除確認",
    message: "本当に削除しますか？",
    confirmAction: { 
        // 削除処理
    }
)

// エラーアラート
NavigationRouter.shared.showError(error)
```

## 将来的な拡張

### 新しい画面の追加
1. `NavigationDestination.swift` にcaseを追加
2. `destination(repository:)` メソッドに対応するビューを追加
3. 必要に応じて新しいビューファイルを作成

### カスタムナビゲーション
- `NavigationRouter` を継承して独自のロジックを実装
- 特定の画面に対する特殊な遷移ロジック

## 注意点

1. **iOS 16以降対応**: NavigationStack を使用するため、iOS 16以降が必要
2. **型安全性**: NavigationDestination enumを使用して型安全なナビゲーションを実現
3. **シングルトン**: NavigationRouter.shared を使用して状態を統一管理
4. **データ一貫性**: すべてのモーダルで同じModelContextを共有し、データの一貫性を保証
5. **リソース管理**: モーダルが閉じられた際の適切なリソース管理

## アーキテクチャ

```
RootView
├── NavigationStack
│   ├── ContentView (ホーム画面)
│   └── navigationDestination (動的画面)
├── Sheet Modal
├── FullScreen Modal
└── Alert System
```

## 実装時の考慮事項

- **仕様書対応**: 基本的に「ホーム画面のみで完結」という仕様に準拠
- **将来的な拡張性**: 追加機能に対応できる柔軟な設計
- **型安全性**: Swift の型システムを活用した堅牢な実装
- **パフォーマンス**: 効率的なナビゲーション管理
- **データ一貫性**: 環境のModelContextを活用した統一されたデータ管理

## データ一貫性の保証

ナビゲーションシステムは、すべてのモーダルビューで同じ`ModelContext`を共有することで、データの一貫性を保証します。

### 修正済みの問題
- **問題**: 各モーダルが独自の`ModelContainer`を作成し、データの不整合が発生
- **解決**: 環境の`ModelContext`を使用し、全てのビューで同じデータコンテキストを共有
- **改善**: `try!`による強制アンラップを除去し、クラッシュリスクを軽減
- **ナビゲーション競合**: シート内で`NavigationStack`を使用することで発生する競合を解決

### 技術的な実装

#### データ一貫性の修正
```swift
// 修正前: 各モーダルが独自のModelContainerを作成
destination.destination(repository: ActionLogRepository(modelContext: ModelContext(try! ModelContainer(for: ActionLog.self))))

// 修正後: 環境のModelContextを使用
destination.destination(repository: ActionLogRepository(modelContext: modelContext))
    .modelContainer(modelContext.container)
```

#### ナビゲーション競合の修正
```swift
// 修正前: シート内でNavigationStackを使用（競合発生）
struct LogDetailView: View {
    var body: some View {
        NavigationStack {
            VStack { /* コンテンツ */ }
                .navigationTitle("記録詳細")
        }
    }
}

// 修正後: シート内では直接コンテンツを表示
struct LogDetailView: View {
    var body: some View {
        VStack { /* コンテンツ */ }
            .navigationTitle("記録詳細")
    }
}
```

**理由**: シートとして表示される際、`NavigationRouterWrapper`が提供するNavigationStackが既に存在するため、子ビューで新しいNavigationStackを作成すると競合が発生します。モーダルビューは親のナビゲーションコンテキストを使用します。

**結果**: 各モーダルビューは適切なナビゲーションバーとツールバーを持ちながら、ナビゲーション競合を回避できます。

## テスト

各ビューのPreviewを使用して、ナビゲーション機能をテストできます。