Webアプリケーションを作ったんだけど脆弱性がないかとかをチェックできるskillとかmcpとかツールってない？12:43利用可能なツールを検討し、脆弱性チェック方法を提案した。利用可能なツールを検討し、脆弱性チェック方法を提案した。現時点では、セキュリティ脆弱性チェック専用のskillやMCPは用意されていないです。ただ、いくつかアプローチがあります：
今すぐできること
1. コードをここに貼って直接レビュー
Next.js/TypeScript + Supabaseスタックなら、コードを貼ってもらえれば以下を確認できます：

SQLインジェクション / XSS / CSRF
認証・認可の抜け
APIキーの露出
Supabase RLSの設定ミス
Cloudflare Workers特有のセキュリティ問題

2. Claude Codeでの静的解析
EC2でClaude Code使ってるなら、こんなプロンプトでスキャンできます：
/security-review: Check all API endpoints for authentication, 
authorization, input validation, and common OWASP vulnerabilities
外部ツール連携（MCPで使えるもの）
現在つながってるMCPはGoogle Calendar/Gmailのみなので、セキュリティ系はないですが、自分でMCPサーバーを立てることで連携できます：
ツール用途Semgrep静的解析（OWASP対応）、OSS版ありSnyk依存パッケージの脆弱性OWASP ZAP動的スキャン（APIエンドポイント）、REST API対応
一番手っ取り早い方法
コードやアーキテクチャの概要（ルーティング、認証フロー、DBアクセス部分）をここに貼ってもらえれば、今すぐレビューできます。grant-agentやChoimimiのどっちですか？
