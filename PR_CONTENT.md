## 概要
Issue #32 の実装: フィードバック表示UIと履歴管理

## 変更内容

### 新規作成
- `Views/Components/FeedbackView.swift`: AIフィードバックを表示するモーダルUIコンポーネント
- `EatLockTests/FeedbackViewTests.swift`: FeedbackView関連のユニットテスト

### 修正
- `ContentView.swift`: フィードバック表示機能の統合、新規ログ作成時のAIフィードバック表示処理を追加
- `Navigation/NavigationDestination.swift`: ログ詳細画面での防いだカロリー表示を強化、UIの視覚的改善
- `ActionLogRepository.swift`: フィードバック履歴管理機能を追加（fetchActionLogsWithFeedback, fetchFeedbackHistoryWithCalories等）

## 技術詳細
- **フィードバック表示**: モーダル形式でAIフィードバックを表示、防いだカロリーをアニメーション付きで強調
- **履歴管理**: ActionLogRepositoryに新たなクエリメソッドを追加し、フィードバック履歴の効率的な取得を実現
- **UI/UX改善**: 防いだカロリーの視覚的強調、アイコンとカラーリングによる情報の直感的な理解を促進
- **データ整合性**: 既存の暗号化システムとの整合性を保ちながら、セキュアなフィードバック表示を実装

## 動作確認
- [x] 新規ログ作成時にAIフィードバックがモーダルで表示される
- [x] 防いだカロリーが強調表示される
- [x] ログ詳細画面で過去のフィードバックが閲覧できる
- [x] フィードバック履歴の取得機能が正常動作する
- [x] 既存機能に影響を与えない

## 関連Issue
Closes #32

## 特記事項
- FeedbackViewはモーダル形式で実装し、背景タップまたは閉じるボタンで解除可能
- 防いだカロリーが0以上の場合のみアニメーション付きで強調表示
- ActionLogRepositoryに追加した履歴管理機能は将来的な統計機能拡張にも活用可能
- 既存の暗号化システムとの整合性を保持し、セキュリティを損なわない実装