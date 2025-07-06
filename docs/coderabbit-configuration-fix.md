# CodeRabbit 設定ファイル修正ガイド

本ドキュメントでは、CodeRabbit設定ファイル（`.coderabbit.yaml`）のパースエラーの解決方法を説明します。

## 発生したエラー

### エラーメッセージ

```
💥 Parsing errors (1)
Validation error: Expected object, received boolean at "reviews.auto_review"
```

### 原因

CodeRabbit v2では、`reviews.auto_review` の設定形式が変更され、単純なboolean値ではなく、オブジェクト形式での設定が必要になりました。

## 修正内容

### 1. スキーマの追加

ファイルの先頭にyaml-language-serverの設定を追加：

```yaml
# yaml-language-server: $schema=https://coderabbit.ai/integrations/schema.v2.json
```

**効果**: エディタでの自動補完と検証が有効になります。

### 2. auto_review設定の修正

#### 修正前（エラーの原因）

```yaml
reviews:
  auto_review: true
```

#### 修正後

```yaml
reviews:
  auto_review:
    enabled: true
    on_push: true
    on_pull_request: true
    exclude:
      - "**/xcuserdata/**"
      - "**/DerivedData/**"
      - "**/Pods/**"
      - "**/.build/**"
      - "**/Preview Content/**"
      - "**/*.xcassets/**"
      - "**/fastlane/**"
```

### 3. その他の標準化

#### path_instructions の使用

```yaml
path_instructions:
  - path: "**/*.swift"
    instructions: |
      - SwiftUIのベストプラクティスに従っているかチェック
      - メモリ管理（ARC）の問題がないかチェック
      - プロトコル準拠が適切かチェック
```

#### カスタムルールの修正

```yaml
custom_rules:
  - name: "privacy_check"
    description: "プライバシー関連のコードをチェック"
    severity: "error"
    patterns:
      - "UserDefaults"
      - "CoreData"
      - "CloudKit"
      - "HealthKit"
```

## 設定ファイルの検証方法

### 1. YAML構文チェック

```bash
# yamllintを使用した構文チェック
yamllint .coderabbit.yaml

# またはオンラインYAMLバリデーターを使用
```

### 2. CodeRabbitでの検証

```bash
# GitHub CLIを使用してPRを作成し、CodeRabbitの反応を確認
gh pr create --title "test: CodeRabbit設定テスト" --body "設定ファイルのテスト"
```

## トラブルシューティング

### よくあるエラーと解決方法

#### 1. "Expected object, received boolean"

**原因**: v2では多くの設定項目がオブジェクト形式に変更された  
**解決**: boolean値をオブジェクト形式に変更

```yaml
# ❌ 古い形式
auto_review: true

# ✅ 新しい形式
auto_review:
  enabled: true
```

#### 2. "Unknown field"

**原因**: v2で廃止または名前変更された設定項目を使用  
**解決**: 公式スキーマを確認し、対応する新しい設定項目を使用

#### 3. "Invalid YAML syntax"

**原因**: YAMLの構文エラー（インデント、クォートなど）  
**解決**: yamllintやオンラインバリデーターで構文チェック

### デバッグ手順

1. **スキーマの確認**
   ```bash
   curl -s https://coderabbit.ai/integrations/schema.v2.json | jq .
   ```

2. **段階的テスト**
   - 最小限の設定から開始
   - 少しずつ設定を追加
   - 各段階でPRを作成してテスト

3. **ログの確認**
   - GitHub PRのCodeRabbitコメントを確認
   - エラーメッセージから具体的な問題箇所を特定

## 推奨設定テンプレート

### 基本的な設定

```yaml
# yaml-language-server: $schema=https://coderabbit.ai/integrations/schema.v2.json

reviews:
  auto_review:
    enabled: true
    on_push: true
    on_pull_request: true
  review_status: true
  high_level_summary: true

language: "ja"

path_instructions:
  - path: "**/*.swift"
    instructions: |
      - コード品質とSwiftのベストプラクティスをチェック
      - セキュリティとプライバシーの観点から評価
```

### iOS/Swift プロジェクト向け設定

```yaml
# yaml-language-server: $schema=https://coderabbit.ai/integrations/schema.v2.json

reviews:
  auto_review:
    enabled: true
    on_push: true
    on_pull_request: true
    exclude:
      - "**/xcuserdata/**"
      - "**/DerivedData/**"
      - "**/Pods/**"
      - "**/*.xcassets/**"

language: "ja"

path_instructions:
  - path: "**/*.swift"
    instructions: |
      - SwiftUIのベストプラクティスに従っているかチェック
      - メモリ管理（ARC）の問題がないかチェック
      - セキュリティとプライバシーの観点から評価

focus_areas:
  - "security"
  - "code_quality"
  - "performance"
  - "swiftui_best_practices"

custom_rules:
  - name: "privacy_check"
    description: "プライバシー関連のコードをチェック"
    severity: "error"
    patterns:
      - "UserDefaults"
      - "CoreData"
```

## 関連リンク

- [CodeRabbit v2 Documentation](https://coderabbit.ai/docs)
- [Configuration Schema](https://coderabbit.ai/integrations/schema.v2.json)
- [YAML Validator](https://www.yamllint.com/)
- [GitHub Integration Guide](https://docs.github.com/en/developers/overview/managing-deploy-keys)

## 変更履歴

| 日付 | 変更内容 | 担当者 |
|------|----------|--------|
| 2025-07-04 | 初版作成、v2スキーマ対応 | AI Assistant |