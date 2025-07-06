# GitHub Issue 取得方法ガイド

本ドキュメントでは、GitHub Issue の情報を取得する複数の方法を説明します。

## 方法1: GitHub API を使用した取得（推奨）

### 基本的な使用方法

```bash
curl -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/{owner}/{repo}/issues/{issue_number}
```

### 実際の例

```bash
curl -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/arusu0629/EatLock/issues/23
```

### 認証が必要な場合

```bash
curl -H "Authorization: token YOUR_GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/{owner}/{repo}/issues/{issue_number}
```

### 取得できる情報

- `title`: Issue のタイトル
- `body`: Issue の本文
- `labels`: 付与されたラベル
- `state`: Issue の状態（open/closed）
- `assignees`: アサインされたユーザー
- `created_at`: 作成日時
- `updated_at`: 更新日時
- `html_url`: Issue の GitHub URL

## 方法2: GitHub CLI を使用した取得

### インストール

```bash
# Ubuntu/Debian
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh -y
```

### 使用方法

```bash
# 認証（初回のみ）
gh auth login

# Issue の詳細を取得
gh issue view {issue_number}

# JSON形式で取得
gh issue view {issue_number} --json title,body,labels,state,assignees,createdAt,updatedAt
```

### 実際の例

```bash
gh issue view 23 --json title,body,labels,state,assignees,createdAt,updatedAt
```

## 方法3: Web検索を使用した取得

### 検索クエリ例

```
site:github.com {owner}/{repo}/issues/{issue_number}
```

### 実際の例

```
site:github.com arusu0629/EatLock/issues/23
```

**注意**: この方法は正確性に欠ける場合があり、関連のないIssueが表示されることがあります。

## 事前準備

### リポジトリ情報の確認

```bash
# 現在のディレクトリがGitリポジトリかどうか確認
git status

# リモートリポジトリの情報を確認
git remote -v
```

### 結果の例

```
origin  https://github.com/arusu0629/EatLock (fetch)
origin  https://github.com/arusu0629/EatLock (push)
```

## 推奨フロー

1. **リポジトリ情報の確認**
   ```bash
   git remote -v
   ```

2. **GitHub API での取得**
   ```bash
   curl -H "Accept: application/vnd.github.v3+json" \
     https://api.github.com/repos/{owner}/{repo}/issues/{issue_number}
   ```

3. **GitHub CLI での取得（代替手段）**
   ```bash
   gh issue view {issue_number} --json title,body,labels,state,assignees,createdAt,updatedAt
   ```

## トラブルシューティング

### 認証エラー (401 Unauthorized)

GitHub API で認証エラーが発生した場合：

1. Personal Access Token を作成
2. 環境変数に設定
   ```bash
   export GITHUB_TOKEN=your_token_here
   ```
3. 認証ヘッダーを追加
   ```bash
   curl -H "Authorization: token $GITHUB_TOKEN" \
     -H "Accept: application/vnd.github.v3+json" \
     https://api.github.com/repos/{owner}/{repo}/issues/{issue_number}
   ```

### GitHub CLI が見つからない場合

```bash
# インストール状況を確認
which gh

# インストールされていない場合はインストール
sudo apt install gh -y
```

### レート制限に達した場合

GitHub API には時間あたりのリクエスト制限があります：

- 未認証: 60リクエスト/時
- 認証済み: 5,000リクエスト/時

認証を行うことで制限を大幅に緩和できます。

## 実用例

### Issue #23 の取得例

```bash
# 基本的な取得
curl -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/arusu0629/EatLock/issues/23

# 結果をファイルに保存
curl -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/arusu0629/EatLock/issues/23 > issue_23.json

# 特定の情報のみを抽出（jq使用）
curl -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/arusu0629/EatLock/issues/23 | jq '.title'
```

### 複数の Issue を一度に取得

```bash
# リポジトリの全Issue を取得
curl -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/arusu0629/EatLock/issues

# 特定の状態のIssueのみを取得
curl -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/arusu0629/EatLock/issues?state=open
```

## 関連リンク

- [GitHub REST API Documentation](https://docs.github.com/en/rest)
- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [GitHub Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)