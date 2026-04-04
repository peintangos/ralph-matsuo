# AGENTS.md — ralph-matsuo

`codex` をこのリポジトリで実行するときに読む設定ファイル。
詳細なワークフローは各スキルファイルに分離して遅延ロードされる。

## プロジェクト概要

Ralph Matsuo は新規プロダクト開発のベーステンプレート。クローン → リネームして使う。
**中心原則**: 計画はドキュメントを更新する。実行はドキュメントを読む。

## 基本ルール

- **言語**: 全出力は日本語（変数名・関数名などのコード識別子は英語）
- **Git**: Conventional Commits（`feat:` / `fix:` / `docs:` / `refactor:` / `chore:` / `test:`）
- **ドキュメントファースト**: ソース編集前に `docs/` の未コミット変更を確認する
- **テスト**: 編集後は `ralph.toml` の `test_primary` コマンドを実行する（現在: `npm test`）

## 利用可能なスキル

| スキル | 用途 |
|---|---|
| `/implement` | PRD の todo から次タスクを実装する |
| `/code-review` | 変更を 7 観点でコードレビューする |
| `/catchup` | プロジェクト状態をサマリーする |
| `/commit-push` | コミット・プッシュする |
| `/test` | テストを実行する |
| `/build-check` | ビルド・lint を確認する |

## PRD 構造（概要）

```
docs/prds/prd-{slug}/
├── prd.md / knowledge.md / progress.md / todo.md
└── specifications/spec-NNN-*.md
```

詳細は `/implement` スキルの `references/` を参照。
