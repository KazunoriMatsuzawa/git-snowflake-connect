# ユーザー向け：Snowflake Workspaces で GitHub リポジトリを使う手順

## 概要

このドキュメントは、Snowflake Workspaces を使って GitHub のリポジトリをクローンし、ブラウザ上で編集・コミット・プッシュするための**ユーザー向け**手順書です。

### できること

- GitHubリポジトリをSnowflake Workspacesにクローン
- ブラウザ上でファイルを編集
- 変更をコミットしてGitHubにプッシュ
- ブランチの作成・切り替え
- リモートリポジトリからの最新変更の取得（pull）
- 競合の解決

### 前提条件

- 管理者によってAPI INTEGRATION（`GITHUB_OAUTH_INTEGRATION`）が作成・設定されている
- 自分のロールに対して、API INTEGRATIONの`USAGE`権限が付与されている
- GitHubアカウントを持っている
- github.com でホストされているリポジトリへのアクセス権限がある

---

## 1. Snowsight でGit同期Workspaceを作成

### ステップ1: Snowsight にサインイン

Snowflakeアカウントにサインインし、Snowsightにアクセスします。

### ステップ2: Projects → Workspaces へ移動

左側のナビゲーションメニューから **Projects → Workspaces** を選択します。

### ステップ3: 新しいWorkspaceを作成

1. **＋ Workspace** ボタンをクリック
2. **From Git repository** を選択

### ステップ4: リポジトリ情報を入力

以下の情報を入力します：

| 項目 | 入力内容 | 例 |
|------|----------|-----|
| **Repository URL** | クローンしたいGitHubリポジトリのURL | `https://github.com/KazunoriMatsuzawa/dbt-handson` |
| **API Integration** | 管理者が作成したAPI INTEGRATION名 | `GITHUB_OAUTH_INTEGRATION` |
| **Authentication method** | 認証方式 | **OAuth2** を選択 |

### ステップ5: GitHubでOAuth認証

1. **Sign in** ボタンをクリック
2. GitHubのログイン画面が表示されるのでサインイン
3. Snowflake アプリ（`Snowflake Computing` / `snowflakedb app`）の権限リクエストが表示されます
4. 以下の権限が含まれていることを確認：
   - **Read access to metadata**（リポジトリのメタデータ読み取り）
   - **Read and write access to code**（コードの読み書き - プッシュに必要）
5. **Authorize** ボタンをクリックして権限を承認

### ステップ6: Workspace作成の完了

- Workspace名を入力（デフォルトはリポジトリ名）
- **Create** をクリック

これで、GitHubリポジトリがSnowflake Workspacesにクローンされました！

---

## 2. Workspacesでの基本操作

### 2.1 ファイルの編集

1. 左側のファイルツリーから編集したいファイルを選択
2. エディタでファイルを編集
3. 変更は自動的に保存されます

### 2.2 変更の確認

画面下部または左側の **Changes** タブで、以下を確認できます：

- 変更されたファイルの一覧
- 各ファイルの差分（diff）
- 新規追加・削除されたファイル

### 2.3 変更をコミット

1. **Changes** タブを開く
2. コミットメッセージを入力（変更内容を簡潔に記述）
3. **Commit** ボタンをクリック

### 2.4 リモートリポジトリにプッシュ

1. コミット後、**Push** ボタンが表示されます
2. **Push** をクリックして、変更をGitHubにアップロード
3. GitHubで変更が反映されていることを確認

### 2.5 リモートから最新変更を取得（Pull）

他の人が変更をプッシュした場合、最新の変更を取得します：

1. 画面上部の **Pull** ボタンをクリック
2. リモートの最新変更がローカルに取り込まれます

---

## 3. ブランチの操作

### 3.1 新しいブランチを作成

1. 画面上部のブランチドロップダウンをクリック
2. **Create new branch** を選択
3. ブランチ名を入力（例: `feature/new-model`, `fix/bug-123`）
4. 作成元のブランチを選択（通常は `main` または `master`）
5. **Create** をクリック

### 3.2 ブランチを切り替え

1. 画面上部のブランチドロップダウンをクリック
2. 切り替えたいブランチを選択

### 3.3 リモートブランチを取得

1. **Fetch** ボタンをクリック
2. リモートの最新ブランチ情報が取得されます
3. ブランチドロップダウンに新しいリモートブランチが表示されます

---

## 4. 競合の解決

複数人で同じファイルを編集した場合、Pullやマージ時に競合が発生する可能性があります。

### 競合が発生した場合

1. Workspacesが競合を検出し、通知を表示
2. 競合しているファイルが **Changes** タブに表示されます
3. ファイルを開くと、競合箇所が以下のようにマークされています：

```
あなたの変更
他の人の変更
```

4. 競合箇所を手動で修正（どちらを残すか、または統合するか決定）
5. 競合マーカー（`<<<<<<<`, `=======`, `>>>>>>>`）を削除
6. ファイルを保存
7. 変更をコミット・プッシュ

---

## 5. よくある質問（FAQ）

### Q1. どのリポジトリにアクセスできますか？

管理者が `API_ALLOWED_PREFIXES` で設定した組織・ユーザー配下のリポジトリにアクセスできます。現在の設定：

- `https://github.com/powertrain-dx/*`（組織）
- `https://github.com/KazunoriMatsuzawa/*`（個人）

それ以外のリポジトリにアクセスする必要がある場合は、管理者に連絡してPrefixの追加を依頼してください。

### Q2. 公開リポジトリでもOAuth認証が必要ですか？

- **読み取りのみ**の場合: 公開リポジトリなら認証なしでも可能
- **プッシュする場合**: OAuth認証（または個人アクセストークン）が必須です

Workspacesで編集・プッシュする場合はOAuth認証が推奨されます。

### Q3. OAuth認証で許可する権限は何ですか？

以下の権限が必要です：

- **Read access to metadata**: リポジトリのメタデータを読み取る
- **Read and write access to code**: ファイルの読み書き・プッシュを行う

これらの権限は、Snowflake アプリがGitHub上で操作を行うために必要です。

### Q4. エラー: "API integration not found" が表示されます

以下を確認してください：

- 管理者がAPI INTEGRATIONを作成しているか
- 自分のロールに `USAGE` 権限が付与されているか
- API INTEGRATION名が正しく入力されているか（大文字小文字も確認）

問題が解決しない場合は、管理者に連絡してください。

### Q5. エラー: "URL not allowed by API_ALLOWED_PREFIXES" が表示されます

アクセスしようとしているリポジトリのURLが、管理者が設定した `API_ALLOWED_PREFIXES` に含まれていません。

管理者に連絡して、該当する組織・ユーザーのPrefixを追加してもらってください。

### Q6. GitHubでのコミット履歴に自分の名前が表示されません

GitHubアカウントのメール設定を確認してください。Gitの設定で使用しているメールアドレスが、GitHubアカウントに登録されている必要があります。

---

## 6. 推奨されるワークフロー

### 基本的な開発フロー

1. **ブランチを作成**: メインブランチから作業用ブランチを作成
2. **編集・コミット**: ファイルを編集し、適切なコミットメッセージでコミット
3. **プッシュ**: 変更をGitHubにプッシュ
4. **プルリクエスト**: GitHub上でプルリクエストを作成
5. **レビュー・マージ**: チームメンバーのレビュー後、メインブランチにマージ

### コミットメッセージのベストプラクティス

- 簡潔で分かりやすく（50文字以内を推奨）
- 何を変更したかを明確に記述
- 例：
  - `Add customer segmentation model`
  - `Fix typo in sales report`
  - `Update README with setup instructions`

---

## 7. サポート・お問い合わせ

### 管理者への連絡が必要な場合

- 新しい組織・ユーザーのリポジトリへのアクセス権限が必要
- API INTEGRATIONの設定に問題がある
- `USAGE` 権限が付与されていない

### GitHub側の問題

- リポジトリへのアクセス権限がない
- OAuth認証で問題が発生している

→ リポジトリのオーナーまたは組織の管理者に連絡してください。

---

## 8. 参考資料

- [Snowflake公式ドキュメント: Gitワークスペースの作成](https://docs.snowflake.com/ja/user-guide/ui-snowsight/workspaces-git.html)
- [Snowflake公式ドキュメント: Gitを使用するためのSnowflakeの設定](https://docs.snowflake.com/ja/developer-guide/git/git-setting-up)
- [GitHub公式ドキュメント: About authentication](https://docs.github.com/en/authentication)

---

## 始めましょう！

これで準備は完了です。Snowsight Workspacesを使って、GitHubリポジトリで快適に開発してください！

質問や問題がある場合は、管理者またはチームリーダーに連絡してください。
