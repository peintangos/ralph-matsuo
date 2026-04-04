# AGENTS.md — ralph-matsuo

`codex` をこのリポジトリで実行するときに読む設定ファイル。
`CLAUDE.md` + `.claude/rules/` の内容を Codex 向けに統合したもの。
詳細なワークフロー手順は各スキルファイルに分離して遅延ロードされる。

---

## 言語ルール

すべての出力（会話・コミットメッセージ・コードコメント・ドキュメント）は **日本語** で記述する。
- 変数名・関数名・型名・ファイル名・パッケージキーなどのコード識別子は英語
- `package.json` の description など慣例的に英語のフィールドはそのまま英語

---

## プロジェクト概要

Ralph Matsuo は Claude Code と Ralph Loop 向けの **docs-first OSS テンプレート**。
新規プロダクト開発時にこのリポジトリをクローン・リネームして使う。

構成:
- `docs/prds/` — 再利用可能な計画ドキュメント
- `ralph.toml` — テスト・ビルド・lint コマンドの正規レジストリ
- `.claude/skills/` — インタラクティブスキル（Codex でも読む）
- `scripts/ralph/` — ヘッドレス実行スクリプト
- `.github/workflows/` — issue 受付・計画・自律実行・PR 作成を繋ぐ GitHub Actions

**中心原則**: 計画はドキュメントを更新する。実行はドキュメントを読む。

アクティブな PRD ディレクトリがフィーチャーワークのコントロールプレーン。
`prd.md`・`specifications/`・`dependencies.md`・`progress.md`・`todo.md` といった明示的なアーティファクトから作業すること。

### テックスタック

- Runtime: Bash / Node.js（ツーリングのみ）
- Languages: Markdown, Bash, YAML, TOML
- Package manager: npm
- Automation: Git, GitHub Actions, Claude Code CLI / Codex CLI
- 検証エントリーポイント: `npm test`, `npm run test:doc-contracts`, `npm run test:orchestrator`, `npm run lint:repo`

### プロジェクトコマンドレジストリ（ralph.toml）

| ロール | 説明 |
|---|---|
| `test_primary` | ユニットテスト / 主要テスト |
| `test_integration` | 統合テスト / E2E（存在する場合） |
| `build_check` | ビルド検証 |
| `lint_check` | linting / 静的解析 |
| `format_fix` | フォーマッター（設定されている場合） |

ロール名はリポジトリをまたいで固定。コマンド文字列はリポジトリ固有。
このテンプレートリポジトリでは未適用のロールは `N/A` のまま。

---

## ドキュメントシステム

### PRD ディレクトリ構造

```
docs/prds/prd-{slug}/
├── prd.md              # PRD 本文（要件定義）
├── knowledge.md        # 再利用可能なパターンと実装メモ
├── progress.md         # 仕様単位の進捗追跡
├── todo.md             # 次の実行タスク
├── dependencies.md     # 仕様間の依存関係と実装順序
└── specifications/     # Gherkin 形式のフィーチャー仕様
    ├── spec-001-*.md
    └── ...
```

新規 PRD 作成時は `docs/prds/_template/` をベースラインとして使う。

### その他のドキュメント

- `ralph.toml` — 正規 Ralph コマンドレジストリ
- `docs/architecture.md` — システムアーキテクチャと制御フロー
- `docs/roadmap.md` — リポジトリレベルの方向性とアクティブ PRD
- `README.md` — 公開エントリーポイント

### ファイルの役割

- **`prd.md`**: デリバリースコープと `## Branch` でターゲットブランチを定義する
- **`knowledge.md`**: 再利用可能なパターン・統合メモ・非自明な教訓を格納する。タスク日誌として使わない。
- **`progress.md`**: 正確な値 `pending` / `in-progress` / `done` でステータスを追跡。カラムは `Specification | Title | Status | Completed On | Notes` で 1 行 1 仕様ファイル。
- **`todo.md`**: 未チェックのチェックボックス行（`- [ ]`）で優先順に実行タスクを列挙。各タスクは 1 回の実行で完了できる粒度にする。
- **`dependencies.md`**: 仕様間の依存順序を記録する
- **`specifications/`**: `## Acceptance Criteria` に Gherkin シナリオ、`## Implementation Steps` にチェックボックスタスクを持つ

---

## Git ワークフロー

**ブランチ:**
- PRD スコープの作業: PRD の `## Branch` で指定されたブランチを使用（ブランチ + PR 方式）
- アクティブな PRD がない場合: 現在のブランチに留まる。理由なく main に切り替えない。

**コミットメッセージ（Conventional Commits）:**
- 英語 prefix + 英語 description
- prefix: `feat:` / `fix:` / `docs:` / `refactor:` / `chore:` / `test:`
- 例: `feat: add security scan workflow`
- Ralph Loop 経由: `feat: spec-NNN - {タスク概要}`

**その他:**
- 依存ロックファイルは意図的に更新したときにコミットに含める

---

## ドキュメントファーストルール

ソースコードを編集する前に:
1. `docs/` に未コミットの変更がないか確認する。あればまずコミット。
2. 関連する PRD と仕様書を読む。
3. 実装後に docs を更新する。

**完了チェックリスト（タスク完了後に必ず実施）:**
- [ ] 仕様書の該当実装ステップをチェック済みにする
- [ ] `progress.md` のステータスを更新（完了日も記入）
- [ ] 完了タスクを `todo.md` から削除し、残りを未チェックのまま維持
- [ ] `knowledge.md` に再利用可能なパターンを追記
- [ ] 構造変更があれば `docs/architecture.md` を更新
- [ ] 優先度変更があれば `docs/roadmap.md` を更新
- [ ] 公開向けの動作変更があれば `README.md` を更新

---

## ワークフロー

### セッション開始

1. `$catchup` を実行して現在の状態をサマリーする
2. ターゲット PRD の `todo.md` を読む
3. 次のタスクが明示的で実行可能であることを確認する

### 計画フェーズ（ドキュメントのみ）

以下のスキルまたはプランモードで計画アーティファクトを更新する:
`$prd-create` / `$prd-enhance` / `$spec-create` / `$roadmap-update` / `$req-update` / `$docs-review`

計画の出力は以下を持つ PRD セット:
- `prd.md` に明確なスコープ
- `specifications/` に実行可能なステップ
- `dependencies.md` に依存順序
- `todo.md` に優先順位付きの次タスクリスト

**このフェーズではソースコード変更を行わない。**

### インタラクティブ実行サイクル

1. `$catchup` で状態確認
2. PRD の `todo.md` を読んで次タスクを特定
3. `$implement` を実行（1 タスク 1 回）
4. `$test` でテスト実行
5. `$build-check` があれば実行
6. `$code-review` でレビュー
7. `progress.md`・`specifications/`・`todo.md`・`knowledge.md` を更新
8. `$commit-push` でコミット

---

## 利用可能なスキル（.claude/skills/ を参照）

| スキル | 用途 |
|---|---|
| `$implement` | PRD の todo から次タスクを実装する |
| `$code-review` | 変更を 7 観点でコードレビューする |
| `$catchup` | プロジェクト状態をサマリーする |
| `$commit-push` | コミット・プッシュする |
| `$test` | テスト実行（ralph.toml の test_primary） |
| `$build-check` | ビルド・lint 確認（ralph.toml の build_check / lint_check） |
| `$prd-create` | 新規 PRD を対話的に作成する |
| `$spec-create` | 新規フィーチャー仕様を作成する |
| `$docs-review` | docs/ 以下の整合性をレビューする |
| `$roadmap-update` | roadmap.md と progress.md を更新する |

---

## 要件変更検知

以下のような発言があった場合、要件変更・追加の可能性があると判断して対話で確認する:
- 仕様・要件の変更について言及（「〜を変えたい」「〜の仕様を修正」など）
- 新機能・要件の追加について言及（「〜も追加したい」など）
- 既存仕様への疑問・再検討（「これでいいのか」「見直したい」など）

対応:
1. まずユーザーの意図を対話で確認する
2. 変更/追加の内容が固まったら PRD ドキュメントを更新してから実装する
