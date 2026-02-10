-- ============================================================================
-- Snowflake GitHub OAuth Integration Setup Script
-- 管理者向け: GitHub リポジトリへのOAuth接続を設定するSQLスクリプト
-- ============================================================================
-- 
-- このスクリプトは、複数のユーザーがGitHub上のリポジトリにOAuthで接続し、
-- クローン・プッシュできるようにするためのAPI INTEGRATIONを作成します。
--
-- 【現在許可されているPrefix一覧】※追加時はこのリストも更新してください
--   1. https://github.com/powertrain-dx       (組織)
--   2. https://github.com/KazunoriMatsuzawa   (個人)
--   -- 今後追加する場合はここに記録してください
--   -- 3. https://github.com/<new-org-or-user>
--
-- 前提条件:
--   - ACCOUNTADMINまたはCREATE API INTEGRATION権限を持つロールで実行
--   - github.comでホストされているリポジトリ（OAuthはgithub.comのみサポート）
--
-- ============================================================================

-- ============================================================================
-- ステップ1: 管理者ロールに切り替え
-- ============================================================================
USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- ステップ2: API INTEGRATION の作成
-- ============================================================================
-- 
-- API_ALLOWED_PREFIXES:
--   - アクセスを許可するGitHubのURL接頭辞を指定
--   - 組織と複数の個人アカウントを含めることができます
--   - 必要に応じて追加のユーザー/組織を追加してください
--
-- API_USER_AUTHENTICATION:
--   - TYPE = SNOWFLAKE_GITHUB_APP を指定することでOAuth認証を有効化
--   - github.comでホストされているリポジトリでのみ利用可能
--
-- ============================================================================

CREATE OR REPLACE API INTEGRATION GITHUB_OAUTH_INTEGRATION
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = (
    'https://github.com/powertrain-dx',        -- 組織のリポジトリ
    'https://github.com/KazunoriMatsuzawa'     -- 個人アカウント
    -- 必要に応じて追加:
    -- ,'https://github.com/<another-user>'
    -- ,'https://github.com/<another-org>'
  )
  API_USER_AUTHENTICATION = (TYPE = SNOWFLAKE_GITHUB_APP)
  ENABLED = TRUE
  COMMENT = 'GitHub OAuth integration for multiple users and organizations (powertrain-dx, KazunoriMatsuzawa)';

-- 作成確認
SHOW INTEGRATIONS LIKE 'GITHUB_OAUTH_INTEGRATION';

-- ============================================================================
-- ステップ3: ユーザーロールへの権限付与
-- ============================================================================
--
-- API INTEGRATIONを使用するユーザーのロールに対して、USAGE権限を付与します。
-- 以下は例です。実際の環境に合わせてロール名を変更してください。
--
-- ============================================================================

-- 例1: 開発者ロールに権限を付与
-- GRANT USAGE ON INTEGRATION GITHUB_OAUTH_INTEGRATION TO ROLE DEV_ROLE;

-- 例2: データエンジニアロールに権限を付与
-- GRANT USAGE ON INTEGRATION GITHUB_OAUTH_INTEGRATION TO ROLE DATA_ENGINEER;

-- 例3: アナリストロールに権限を付与
-- GRANT USAGE ON INTEGRATION GITHUB_OAUTH_INTEGRATION TO ROLE ANALYST;

-- 例4: 複数のロールに一括で付与する場合
-- GRANT USAGE ON INTEGRATION GITHUB_OAUTH_INTEGRATION TO ROLE DEV_ROLE;
-- GRANT USAGE ON INTEGRATION GITHUB_OAUTH_INTEGRATION TO ROLE DATA_ENGINEER;
-- GRANT USAGE ON INTEGRATION GITHUB_OAUTH_INTEGRATION TO ROLE ANALYST;

-- ============================================================================
-- ステップ4: 設定の確認
-- ============================================================================

-- API INTEGRATIONの詳細を表示
DESC INTEGRATION GITHUB_OAUTH_INTEGRATION;

-- 特定のロールに付与された権限を確認する場合（例: DEV_ROLE）
-- SHOW GRANTS TO ROLE DEV_ROLE;

-- ============================================================================
-- 補足: Prefix（組織・ユーザー）を後から追加する場合
-- ============================================================================
--
-- 重要: SET API_ALLOWED_PREFIXES は既存の値を上書きします。
-- Snowflakeには追加だけを行う構文（ADDなど）は存在しないため、
-- 新しいprefixを追加する際は、既存のprefixもすべて含めて指定してください。
--
-- 推奨手順:
--   1. 現在の設定を確認
--   2. 既存のprefixと新しいprefixをすべて含めてALTER文を実行
--   3. 追加されたことを確認
--
-- ============================================================================

/*
-- ステップ1: 現在のAPI_ALLOWED_PREFIXESを確認
DESC INTEGRATION GITHUB_OAUTH_INTEGRATION;
-- または
SHOW INTEGRATIONS LIKE 'GITHUB_OAUTH_INTEGRATION';
-- 出力結果の「API_ALLOWED_PREFIXES」列から現在の値を確認

-- ステップ2: 新しいユーザー/組織を追加（既存のものもすべて記載）
ALTER API INTEGRATION GITHUB_OAUTH_INTEGRATION
  SET API_ALLOWED_PREFIXES = (
    'https://github.com/powertrain-dx',      -- 既存のprefixを記載
    'https://github.com/KazunoriMatsuzawa',  -- 既存のprefixを記載
    'https://github.com/<new-user-or-org>'   -- 新しいユーザー/組織を追加
  );

-- ステップ3: 追加されたことを確認
DESC INTEGRATION GITHUB_OAUTH_INTEGRATION;
*/

-- ============================================================================
-- 補足: API INTEGRATIONを無効化する場合
-- ============================================================================

/*
-- 一時的に無効化する場合
ALTER API INTEGRATION GITHUB_OAUTH_INTEGRATION SET ENABLED = FALSE;

-- 再度有効化する場合
ALTER API INTEGRATION GITHUB_OAUTH_INTEGRATION SET ENABLED = TRUE;
*/

-- ============================================================================
-- 補足: API INTEGRATIONを削除する場合
-- ============================================================================

/*
-- 完全に削除する場合（注意: 復元できません）
DROP API INTEGRATION IF EXISTS GITHUB_OAUTH_INTEGRATION;
*/

-- ============================================================================
-- セットアップ完了
-- ============================================================================
-- 
-- 次のステップ:
--   1. 上記の権限付与（ステップ3）を実環境のロールに合わせて実行してください
--   2. ユーザーに user_guide.md を共有してください
--   3. ユーザーはSnowsight Workspacesから、GitHubリポジトリを
--      OAuthで接続できるようになります
--
-- ============================================================================
