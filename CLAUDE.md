# CLAUDE.md

このファイルは、このリポジトリでコードを操作する際のClaude Code (claude.ai/code) へのガイダンスを提供します。

## プロジェクト概要

EatLockは、SwiftUIとSwiftDataで構築されたiOSアプリで、ユーザーが食行動をログし、過食を防ぐためのAIフィードバックを提供します。データ暗号化、ローカルAI処理、広告統合、包括的な統計追跡機能を備えています。

## ビルドとテストコマンド

これはXcodeを使用するiOSプロジェクトです：

- **ビルド**: Xcodeで`EatLock.xcodeproj`を開いてビルド（⌘+B）または`xcodebuild`を使用
- **テスト実行**: XcodeのTest Navigatorを使用するか`xcodebuild test`を実行
- **アプリ実行**: XcodeのRunボタン（⌘+R）またはiOSシミュレーターを使用

プロジェクトはiOS 17+が必要で、依存関係にSwift Package Managerを使用しています。

## アーキテクチャ

### コアコンポーネント

- **ActionLogRepository**: SwiftDataで暗号化された行動ログを管理するデータアクセス層
- **AIManager**: フィードバック生成のためのローカルAIサービスを管理するシングルトン
- **NavigationRouter**: iOS 16+ NavigationStackを使用した集中型ナビゲーション状態管理
- **DataSecurityManager**: データの暗号化/復号化とセキュリティポリシーを処理
- **NotificationManager**: ローカル通知と権限を管理

### データフロー

1. ユーザーが食行動を入力 → ActionLogRepositoryが暗号化されたActionLogを作成
2. AIManagerがLocalAIServiceを使用してフィードバックを生成
3. 暗号化されたフィードバックがリポジトリ経由でActionLogに保存
4. 統計がリアルタイムで計算・キャッシュされる
5. @Observableクラスを通じてUIがリアクティブに更新

### 主要パターン

- **暗号化ファースト**: すべてのユーザーコンテンツはデバイス固有キーでデータベース保存前に暗号化
- **リポジトリパターン**: ActionLogRepositoryがSwiftDataの上にデータアクセス抽象化を提供
- **リアクティブUI**: @Observableクラスが自動的なUI更新をトリガー
- **シングルトンサービス**: AIManager、NavigationRouter、DataSecurityManagerは共有インスタンスを使用

## 重要なルール

### GitHub操作（docs/AI_OPERATION_RULES.mdより）

- **PRの自動マージは絶対禁止** - PR作成は可能だがマージにはユーザー承認が必要
- **イシュー修正時は必ずclosing keywordを使用**：
  - バグ修正の場合: `fix #123`
  - 機能完成の場合: `close #123`
  - 問題解決の場合: `resolve #123`
- closing keywordはコミットメッセージの最後に配置

### セキュリティ考慮事項

- すべてのActionLogコンテンツはDataSecurityManagerでデータベース保存前に暗号化
- 暗号化キーはデバイス固有でDataSecurityManagerが管理
- 暗号化されたコンテンツを平文でログ出力や露出させない
- ActionLogRepositoryが暗号化/復号化を透過的に処理

### テスト構造

- **EatLockTests/**: コア機能、AI統合、リポジトリ操作の単体テスト
- **EatLockUITests/**: UI自動化テスト、アクセシビリティテスト、エラーハンドリングテスト
- テストは暗号化/復号化、AIフィードバック生成、データ整合性を検証

## 開発ノート

- 同意管理付きGoogle Mobile Ads SDKを収益化に使用
- AI処理はLocalAIServiceを使用してローカルで実行（外部API呼び出しなし）
- 統計はオンデマンドで計算され、パフォーマンスのためにキャッシュ
- ナビゲーションはパスベースルーティングで最新のNavigationStackを使用
- ユーザー向けテキストはすべて日本語