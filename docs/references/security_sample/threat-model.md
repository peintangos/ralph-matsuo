# AI UNIVERSE 脅威モデル

作成日: 2026-04-02
最終監査日: 2026-04-02

## 概要

AI UNIVERSE（chaos-map）の脅威モデリング結果。
セキュリティ診断の優先順位付けと、継続的な監査の基盤として使用する。

## 技術スタック

| レイヤー | 技術 |
|----------|------|
| フロント | Next.js 16 + React 19 + Tailwind CSS 4 |
| 3D UI | three.js + react-force-graph-3d |
| 認証 | Supabase Auth (OAuth + anonymous sign-in) |
| DB | Supabase PostgreSQL + pgvector |
| 決済 | Stripe |
| AI | Anthropic Claude API |
| 監視 | Sentry |
| デプロイ | Vercel (hnd1) + Supabase |
| IaC | AWS CDK (EC2 runner, optional) |

## 守るべき資産 (Assets)

| 資産 | 重要度 | 理由 |
|------|--------|------|
| Stripe 決済情報・サブスクリプション | **最高** | 金銭被害に直結 |
| Supabase SERVICE_ROLE_KEY | **最高** | RLS バイパスで全データアクセス可能 |
| ANTHROPIC_API_KEY | **高** | 漏洩すると第三者に課金される |
| STRIPE_SECRET_KEY / WEBHOOK_SECRET | **高** | 不正決済・webhook 偽装 |
| ユーザー認証情報（セッション） | **高** | アカウント乗っ取り |
| ユーザー学習進捗データ | **中** | プライバシー（ただし PII 度は低い） |
| グラフデータ（ノード・エッジ） | **低** | 公開コンテンツが大半 |

## 想定攻撃者 (Threat Actors)

| 攻撃者 | 動機 | 能力 |
|--------|------|------|
| 無料ユーザー | Premium コンテンツ（Level 4）を無課金で閲覧 | ブラウザ DevTools 程度 |
| API 悪用者 | Claude API を大量に叩いて無料で AI 利用 | スクリプト・自動化 |
| 外部攻撃者 | API キー窃取、Stripe 不正利用 | 一般的な Web 攻撃手法 |
| 悪意ある OAuth ユーザー | アカウント乗っ取り、権限昇格 | 認証フローの操作 |

## 攻撃面と監査結果 (Attack Surface)

### #1: API Routes 認証チェック — 修正済み

**監査日**: 2026-04-02
**判定**: 修正済み（chat, edge-explanation, quiz に認証チェック追加）

| Route | Method | 認証 | Premium | Rate Limit | 判定 |
|-------|--------|------|---------|------------|------|
| `/api/chat` | POST | **なし** | 個別化のみ | 10/日 | **要注意** |
| `/api/edge-explanation` | POST | **なし** | なし | 10/日 | **要注意** |
| `/api/quiz` | POST | **なし** | 適応型のみ | 10/日 | **要注意** |
| `/api/graph` | GET | なし | RLS | なし | OK（公開データ） |
| `/api/graph/count` | GET | なし | なし | なし | OK（公開データ） |
| `/api/graph/related` | GET | なし | なし | なし | OK（公開データ） |
| `/api/usage` | GET | なし | なし | なし | OK（自身の使用量のみ） |
| `/api/study-coach` | POST | 401 | 403 | なし | OK |
| `/api/tour-narration` | POST | 401 | 403 | なし | OK |
| `/api/premium-report` | POST | 401 | 403 | なし | OK |
| `/api/frontier-readiness` | POST | 401 | 403 | なし | OK |
| `/api/stripe/checkout` | POST | 401 | - | なし | OK |
| `/api/stripe/customer-portal` | POST | 401 | 403 | なし | OK |
| `/api/stripe/webhook` | POST | Stripe署名 | - | なし | OK |
| `/auth/callback` | GET | OAuth code | - | なし | OK |

**検出された問題**:
- `/api/chat`, `/api/edge-explanation`, `/api/quiz` は認証なしで Claude API (ANTHROPIC_API_KEY) を呼び出せる
- rate limit (10/日) はあるが、VPN + cookie 削除でバイパス可能（#6 参照）
- ANTHROPIC_API_KEY の間接的な悪用リスク: スクリプトで大量リクエストを送信可能

**推奨対策**:
- 最低限 anonymous auth を必須にするか、レートリミットをよりバイパスしにくい仕組みにする
- 現状のビジネス要件（無料ユーザーにもAI機能を提供）との兼ね合いで判断が必要

### #2: Premium ゲート — 問題なし

**監査日**: 2026-04-02
**判定**: OK

Premium 専用エンドポイントは全て二重チェック:
1. `supabase.auth.getUser()` → 未認証なら 401
2. `isPremiumStatus(subscription.status)` → 非 Premium なら 403

対象: study-coach, tour-narration, premium-report, frontier-readiness, customer-portal

RLS も Level 4 ノードに Premium フィルタ (`has_active_premium_access()`) を適用済み。

### #3: Admin Client (SERVICE_ROLE_KEY) 利用箇所 — 問題なし

**監査日**: 2026-04-02
**判定**: OK

利用箇所（全てサーバーサイド API Route 内）:
- `rate-limit.ts` — api_usage_logs の読み書き（RLS が service-role-only のため必須）
- `stripe/webhook/route.ts` — subscriptions の upsert
- `quiz/route.ts` — quiz_questions の挿入
- `stripe-checkout.ts` — subscriptions に stripe_customer_id 保存

クライアント側のコンポーネントやフックからの利用なし。`import "server-only"` ガードも stripe-checkout.ts にあり。

### #4: Stripe Webhook 署名検証 — 問題なし

**監査日**: 2026-04-02
**判定**: OK

`web/src/app/api/stripe/webhook/route.ts`:
- `STRIPE_WEBHOOK_SECRET` の存在確認 ✅
- `stripe-signature` ヘッダの存在確認 ✅
- `stripe.webhooks.constructEvent(payload, signature, webhookSecret)` で署名検証 ✅
- `req.text()` で生ペイロード取得（JSON パース前の検証） ✅

### #5: 環境変数のクライアント漏洩 — 問題なし

**監査日**: 2026-04-02
**判定**: OK

| 変数 | 公開 | 利用箇所 |
|------|------|----------|
| `NEXT_PUBLIC_SUPABASE_URL` | 公開（設計通り） | client.ts, server.ts |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | 公開（設計通り） | client.ts, server.ts |
| `NEXT_PUBLIC_SENTRY_DSN` | 公開（設計通り） | layout.tsx |
| `SUPABASE_SERVICE_ROLE_KEY` | サーバーのみ | admin.ts |
| `ANTHROPIC_API_KEY` | サーバーのみ | API routes |
| `STRIPE_SECRET_KEY` | サーバーのみ | stripe.ts |
| `STRIPE_WEBHOOK_SECRET` | サーバーのみ | webhook/route.ts |
| `GUEST_ID_SECRET` | サーバーのみ | request-identity.ts |

`NEXT_PUBLIC_` プレフィックスなしの変数はサーバーサイドのみ。Next.js のバンドルには含まれない。

### #6: Rate Limit — 修正済み（#1 で解決）

**監査日**: 2026-04-02
**判定**: 修正済み

**#1 の認証必須化により解決**:
- 全 AI エンドポイントが認証必須になったため、rate limit は全て user_id ベースで動作
- user_id はサーバー制御のため、VPN + cookie 削除によるバイパスは不可能に

**残存する軽微な問題**:
1. **TOCTOU 競合**: `countUsageForKey` と `insert` が非アトミック。同時リクエストで 11 回目が通る可能性がある（実害は限定的）
2. **edge-explanation は Premium でも 10/日制限** — 意図的な設計か要確認

### #7: Prompt Injection — 修正済み

**監査日**: 2026-04-02
**判定**: 修正済み（chat, tour-narration に sanitize 追加）

| Route | サニタイズ | 問題 |
|-------|-----------|------|
| `/api/chat` | **なし** | `nodeName`, `description` を system prompt に直接埋め込み。制御文字除去なし |
| `/api/edge-explanation` | `sanitize()` あり | 制御文字を除去。OK |
| `/api/quiz` | `sanitize()` あり | 制御文字を除去。OK |
| `/api/tour-narration` | **なし** | `narrativePrompt` を user message に無加工で渡す |

**リスク評価**:
- LLM 出力は同一ユーザーにのみ返されるため、データ漏洩リスクは低い
- 主なリスクはジェイルブレイクによる有害コンテンツ生成、API コスト増加
- chat の system prompt にはユーザーの学習履歴が含まれるが、これは本人のデータ

**推奨対策**:
- chat の `nodeName` / `description` にも `sanitize()` を適用
- tour-narration の `narrativePrompt` にも `sanitize()` を適用

### #8: OAuth Callback — 問題なし

**監査日**: 2026-04-02
**判定**: OK

- `supabase.auth.exchangeCodeForSession(code)` — Supabase SSR が内部で PKCE 検証を処理
- `normalizeNextPath()` — `"/"` で始まらない値は全て `"/"` に正規化。オープンリダイレクト防止済み
- リダイレクト先は `${origin}${nextPath}` でサーバーサイド origin を使用（クライアント操作不可）

### #9: Guest ID 鍵分離 — 修正済み

**監査日**: 2026-04-02
**判定**: 修正済み（SERVICE_ROLE_KEY フォールバック削除）

`web/src/lib/server/request-identity.ts`:
- `GUEST_ID_SECRET` が設定されていれば使用
- 本番環境で未設定の場合はエラーをスロー
- 開発環境のみ固定値にフォールバック
- **SERVICE_ROLE_KEY へのフォールバックを削除**

**対応が必要**: Vercel の環境変数に `GUEST_ID_SECRET` を追加すること（`web/.env.local.example` に追記済み）

### #10: HTTP セキュリティヘッダ — 修正済み

**監査日**: 2026-04-02
**判定**: 修正済み（CSP + HSTS 追加）

**設定済み** (`web/vercel.json`):
- `X-Content-Type-Options: nosniff` ✅
- `X-Frame-Options: DENY` ✅
- `Referrer-Policy: strict-origin-when-cross-origin` ✅
- `Permissions-Policy: camera=(), microphone=(), geolocation=()` ✅
- `Content-Security-Policy` ✅（追加）
- `Strict-Transport-Security` ✅（追加）

**CSP の主要ディレクティブ**:
- `script-src 'self' 'unsafe-inline' 'unsafe-eval' https://js.stripe.com https://*.googletagmanager.com` — Next.js ハイドレーション + Stripe + Google Analytics
- `img-src 'self' data: blob: https://*.google-analytics.com https://*.googletagmanager.com` — Google Analytics のピクセル送信
- `connect-src 'self' https://*.supabase.co wss://*.supabase.co https://*.sentry.io ... https://*.google-analytics.com https://*.analytics.google.com https://*.googletagmanager.com` — API 接続 + Google Analytics 計測送信
- `worker-src 'self' blob:` — three.js Web Worker
- `object-src 'none'` — Flash/Java 完全ブロック
- `base-uri 'self'` — base タグ注入防止

**将来の改善点**:
- `'unsafe-inline'` / `'unsafe-eval'` を nonce ベースの CSP に置き換え（Next.js middleware で実装）
- デプロイ後に CSP 違反レポートを監視し、不足している許可を追加

## 発見事項の優先度まとめ

| 優先度 | 項目 | 概要 | 対応方針 |
|--------|------|------|----------|
| ~~高~~ | #1 API 認証 | ~~chat/edge-explanation/quiz が認証なしで Claude API を呼べる~~ | **修正済み**: 認証必須化 |
| ~~高~~ | #6 Rate Limit バイパス | ~~VPN + cookie 削除で無制限に AI API 利用可能~~ | **修正済み**: #1 の認証必須化で user_id ベースに |
| ~~中~~ | #7 Prompt Injection | ~~chat と tour-narration にサニタイズ漏れ~~ | **修正済み**: `sanitize()` 追加 |
| ~~中~~ | #10 CSP 未設定 | ~~XSS 緩和が不十分~~ | **修正済み**: CSP + HSTS 追加 |
| ~~低~~ | #9 鍵分離 | ~~GUEST_ID_SECRET が SERVICE_ROLE_KEY にフォールバック~~ | **修正済み**: フォールバック削除 |

## 監査進捗

- [x] #1: API Routes 認証チェック — **修正済み**（chat/edge-explanation/quiz に認証チェック追加）
- [x] #2: Premium ゲート — OK
- [x] #3: Admin Client 利用箇所 — OK
- [x] #4: Stripe Webhook 署名検証 — OK
- [x] #5: 環境変数漏洩チェック — OK
- [x] #6: Rate Limit 実装 — **修正済み**（#1 の認証必須化で user_id ベースに）
- [x] #7: Prompt Injection — **修正済み**（chat, tour-narration に sanitize 追加）
- [x] #8: OAuth Callback — OK
- [x] #9: Guest ID 鍵分離 — **修正済み**（SERVICE_ROLE_KEY フォールバック削除）
- [x] #10: HTTP セキュリティヘッダ — **修正済み**（CSP + HSTS 追加）
- [ ] #11: Supabase RLS 網羅性
- [ ] #12: Python スクリプト認証情報
- [ ] #13: GitHub Actions シークレット
- [ ] #14: 依存パッケージ CVE（npm audit）
- [ ] Semgrep スキャン
- [ ] HTTP ヘッダ外部診断

## 参考

- [OWASP Threat Modeling](https://owasp.org/www-community/Threat_Modeling)
- [OWASP Top 10 (2021)](https://owasp.org/www-project-top-ten/)
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
