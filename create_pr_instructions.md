# GitHub Pull Request 作成手順

## 方法1: GitHub CLI使用（推奨）

### 1. GitHub CLIのインストール（未インストールの場合）
```bash
# macOS
brew install gh

# Windows
winget install --id GitHub.cli

# Linux
sudo apt install gh
```

### 2. 認証
```bash
gh auth login
```

### 3. PR作成
```bash
# 現在のブランチからPRを作成
gh pr create --title "[Feature] ナビゲーション管理システムの構築" --body-file PR_TEMPLATE.md

# または対話形式で作成
gh pr create
```

## 方法2: Git + GitHub Web Interface

### 1. 変更をコミット
```bash
git add .
git commit -m "feat: ナビゲーション管理システムの構築

- NavigationDestination.swift: 型安全なナビゲーション先定義
- NavigationRouter.swift: ナビゲーション状態管理
- RootView.swift: アプリケーションルートビュー
- NavigationStackを使用したモダンなナビゲーション実装

Closes #19"
```

### 2. ブランチをプッシュ
```bash
git push origin feature/navigation-management-system
```

### 3. GitHub Web Interfaceでプル リクエストを作成
1. GitHubのリポジトリページに移動
2. "Compare & pull request" ボタンをクリック
3. `PR_TEMPLATE.md`の内容をコピー&ペーストしてPRの説明に使用

## 方法3: GitHub CLI使用（詳細設定）

```bash
# 特定のブランチに対してPRを作成
gh pr create \
  --title "[Feature] ナビゲーション管理システムの構築" \
  --body-file PR_TEMPLATE.md \
  --base main \
  --head feature/navigation-management-system \
  --label "enhancement,iOS" \
  --reviewer "reviewer-username" \
  --assignee "assignee-username"
```

## PR作成後の確認事項

### 1. PR内容の確認
- [ ] タイトルが適切
- [ ] 説明が詳細
- [ ] 変更ファイルが正しく表示されている
- [ ] 関連Issueがリンクされている

### 2. 設定確認
- [ ] 適切なレビュアーが設定されている
- [ ] ラベルが付与されている
- [ ] マイルストーンが設定されている（必要に応じて）

### 3. テスト実行
```bash
# プロジェクトのビルド確認
cd EatLock
# Xcodeでプロジェクトを開いてビルド確認
open EatLock.xcodeproj
```

## 注意事項

1. **ブランチ名**: `feature/navigation-management-system` を使用
2. **コミットメッセージ**: Conventional Commits形式を使用
3. **レビュー**: コード品質、アーキテクチャ、テストカバレッジを確認
4. **CI/CD**: 自動テストが通過することを確認

## 自動化オプション

### GitHub Actions Workflowの例
```yaml
name: Create PR
on:
  workflow_dispatch:
    inputs:
      title:
        description: 'PR Title'
        required: true
      body:
        description: 'PR Body'
        required: true

jobs:
  create-pr:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Create PR
        run: |
          gh pr create --title "${{ github.event.inputs.title }}" --body "${{ github.event.inputs.body }}"
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## 推奨手順

1. **GitHub CLIを使用** (最も効率的)
2. **PR_TEMPLATE.mdの内容を使用** (詳細な説明)
3. **適切なラベル付け** (enhancement, iOS)
4. **レビュアーの設定** (チームメンバー)
5. **自動テストの確認** (CI/CD)