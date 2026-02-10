# 管理者向け：Snowflake GitHub OAuth 統合セットアップ手順

## 概要

このドキュメントは、Snowflake環境で複数のユーザーがGitHub上のリポジトリをOAuthで接続し、クローン・プッシュできるようにするための**管理者向け**手順書です。

### 対象リポジトリ（現在の設定）

> 💡 **管理者向けTips**: 新しいprefix追加時は、このリストも更新してください

| # | タイプ | Prefix URL | 追加日 |
|---|--------|-----------|--------|
| 1 | 組織 | `https://github.com/powertrain-dx` | 初期設定 |
| 2 | 個人 | `https://github.com/KazunoriMatsuzawa` | 初期設定 |
| - | - | `https://github.com/<new-org-or-user>` | (今後追加) |

### 前提条件
- ACCOUNTADMIN または CREATE API INTEGRATION 権限を持つロール
- github.com でホストされているリポジトリ（OAuth認証はgithub.comのみサポート）
- Snowsight が利用可能であること

---

## 1. API INTEGRATION の作成

### 1.1 API INTEGRATION とは

API INTEGRATION は、Snowflakeが外部のHTTPS API（ここではGitHub）にアクセスするための設定オブジェクトです。以下の役割があります：

- **アクセス先の制限**: `API_ALLOWED_PREFIXES` で許可するGitHubのURL接頭辞を指定
- **認証方式の指定**: OAuth、トークン、認証なし などから選択
- **全ユーザーでの共有**: 一度作成すれば、権限を付与することで複数ユーザーが利用可能

### 1.2 複数のPrefix（組織と個人）を許可する方法

`API_ALLOWED_PREFIXES` パラメーターには、カンマ区切りで複数のURLプレフィックスを指定できます。

```sql
API_ALLOWED_PREFIXES = (
  'https://github.com/powertrain-dx',
  'https://github.com/KazunoriMatsuzawa',
  'https://github.com/<other-user>'
)
```

これにより：
- `https://github.com/powertrain-dx/*` 配下のすべてのリポジトリ
- `https://github.com/KazunoriMatsuzawa/*` 配下のすべてのリポジトリ
- 追加した個人アカウント配下のリポジトリ

へのアクセスが許可されます。

### 1.3 OAuth認証の設定

GitHub.comでホストされているリポジトリに対してOAuth認証を使用する場合、以下を指定します：

- `API_PROVIDER = git_https_api`
- `API_USER_AUTHENTICATION = (TYPE = SNOWFLAKE_GITHUB_APP)`
- `API_ALLOWED_PREFIXES` には `https://github.com` で始まるURL

#### ⭐ 重要：OAuth認証情報（Client ID/Secret）は不要です

`TYPE = SNOWFLAKE_GITHUB_APP` を指定すると、**Snowflakeが管理するGitHub App**（`Snowflake Computing`/`snowflakedb app`）を使用します。

- **Client IDやClient Secretの設定は不要**
- Snowflakeが内部でOAuth認証情報を管理
- 管理者は上記のAPI INTEGRATIONを作成するだけ
- ユーザーはブラウザでGitHubにログインして承認するだけで利用可能

---

## 2. 実行手順

### ステップ1: API INTEGRATION の作成

SQLスクリプト [`admin_setup.sql`](admin_setup.sql) を実行してください。

主な設定内容：
```sql
CREATE OR REPLACE API INTEGRATION GITHUB_OAUTH_INTEGRATION
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = (
    'https://github.com/powertrain-dx',
    'https://github.com/KazunoriMatsuzawa'
  )
  API_USER_AUTHENTICATION = (TYPE = SNOWFLAKE_GITHUB_APP)
  ENABLED = TRUE
  COMMENT = 'GitHub OAuth integration for multiple users and organizations';
```

### ステップ2: ユーザーロールへの権限付与

開発者や利用者が使用するロールに対して、作成したAPI INTEGRATIONの`USAGE`権限を付与します。

```sql
-- 例: DEV_ROLE というロールに権限を付与
GRANT USAGE ON INTEGRATION GITHUB_OAUTH_INTEGRATION TO ROLE DEV_ROLE;

```

### ステップ3: 設定の確認

作成したAPI INTEGRATIONの設定を確認します。

```sql
SHOW INTEGRATIONS LIKE 'GITHUB_OAUTH_INTEGRATION';

-- 詳細を確認
DESC INTEGRATION GITHUB_OAUTH_INTEGRATION;
```

---

## 3. セキュリティに関する考慮事項

### 3.1 API_ALLOWED_PREFIXES の適切な設定

- `API_ALLOWED_PREFIXES` は、Snowflakeがアクセスできる外部URLを制限する重要な境界です
- 必要最小限の組織・ユーザーに限定してください
- `https://github.com` のように広範囲に設定するのは避けましょう

### 3.2 権限管理

- API INTEGRATIONの作成には管理者権限が必要です
- 一般ユーザーには `USAGE` 権限のみを付与し、`CREATE` や `ALTER` 権限は付与しないでください
- 定期的に権限を見直し、不要なアクセスは削除してください

### 3.3 監査

- Snowflakeの監査ログ（QUERY_HISTORY、ACCESS_HISTORYなど）を定期的に確認してください
- GitHub側でも、各リポジトリのcommit履歴でどのユーザーがいつ操作したかを確認できます

---

## 4. 新しいPrefix（組織・ユーザー）を追加する場合

> **⚠️ 重要**: `SET API_ALLOWED_PREFIXES` は既存の値を**上書き**します。  
> Snowflakeには追加だけを行う構文（`ADD`など）は存在しないため、新しいprefixを追加する際は、**既存のprefixもすべて含めて**指定する必要があります。

### 推奨手順: 現在の設定を確認してから追加

```sql
-- ステップ1: ACCOUNTADMINロールに切り替え
USE ROLE ACCOUNTADMIN;

-- ステップ2: 現在のAPI_ALLOWED_PREFIXESを確認
DESC INTEGRATION GITHUB_OAUTH_INTEGRATION;
-- または
SHOW INTEGRATIONS LIKE 'GITHUB_OAUTH_INTEGRATION';

-- 出力結果の「API_ALLOWED_PREFIXES」列から現在の値を確認してください
-- 例: https://github.com/powertrain-dx,https://github.com/KazunoriMatsuzawa

-- ステップ3: 既存のprefixをすべて含めて、新しいprefixを追加
ALTER API INTEGRATION GITHUB_OAUTH_INTEGRATION
  SET API_ALLOWED_PREFIXES = (
    'https://github.com/powertrain-dx',      -- 既存のprefixを記載
    'https://github.com/KazunoriMatsuzawa',  -- 既存のprefixを記載
    'https://github.com/<new-user-or-org>'   -- 新しいユーザー/組織を追加
  );

-- ステップ4: 追加されたことを確認
DESC INTEGRATION GITHUB_OAUTH_INTEGRATION;
```

### 今後増えていく予定の場合の運用Tips

prefixが今後も増えていく予定の場合：

1. **管理リストを更新する**: 
   - このmdファイル冒頭の対象リポジトリ表を更新
   - [`admin_setup.sql`](admin_setup.sql) 冒頭のコメントリストも更新
   - 追加日や担当者を記録しておくと管理が楽になります

2. **必ず現在の設定を確認してから変更**: 
   ```sql
   DESC INTEGRATION GITHUB_OAUTH_INTEGRATION;
   ```
   - 出力の `API_ALLOWED_PREFIXES` 列で現在のprefix一覧を確認
   - それをコピーして、新しいprefixを追加

3. **変更履歴を残す**: 
   - いつ、誰が、どのprefixを追加したかをGit履歴で管理
   - または、社内Wikiなどに記録

4. **定期的な棚卸し**: 
   - 使われていないprefixがあれば削除を検討
   - セキュリティリスクを最小化

---

## 5. トラブルシューティング

### エラー: "API integration not found"

- API INTEGRATIONが正しく作成されているか確認してください
- ユーザーのロールに `USAGE` 権限が付与されているか確認してください

### エラー: "URL not allowed by API_ALLOWED_PREFIXES"

- リポジトリのURLが `API_ALLOWED_PREFIXES` に含まれているか確認してください
- 必要に応じてPrefixを追加してください

### OAuth認証が失敗する

- リポジトリが github.com でホストされているか確認してください（それ以外はOAuth不可）
- ユーザーがGitHubで適切な権限を持っているか確認してください
- Snowflakeの設定で `API_USER_AUTHENTICATION = (TYPE = SNOWFLAKE_GITHUB_APP)` が指定されているか確認してください

---

## 6. 参考資料

- [Snowflake公式ドキュメント: Gitを使用するためのSnowflakeの設定](https://docs.snowflake.com/ja/developer-guide/git/git-setting-up)
- [CREATE API INTEGRATION](https://docs.snowflake.com/ja/sql-reference/sql/create-api-integration)
- [Snowflake Workspacesの使用](https://docs.snowflake.com/ja/user-guide/ui-snowsight/workspaces-git.html)
- [GitHub OAuth App](https://docs.github.com/en/apps/oauth-apps)

---

## 次のステップ

管理者のセットアップが完了したら、利用者に [`user_guide.md`](user_guide.md) を共有してください。ユーザーはこのガイドに従って、Snowsight Workspaces上でGitHubリポジトリをクローンし、コミット・プッシュができるようになります。
