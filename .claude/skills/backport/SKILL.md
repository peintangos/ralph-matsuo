---
name: backport
description: "ralph-matsuoテンプレートリポジトリに変更を反映してcommit & pushするスキル。別リポジトリで作業中に「テンプレートに反映して」「upstreamに戻して」「ralph-matsuoを更新して」「テンプレート側も直して」と言ったときに使う。スキル・設定・ドキュメントなどの改善をテンプレートに逆流させたい場面で積極的に使用する。"
user-invocable: true
argument-hint: "[反映したい変更の説明]"
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---

# テンプレートへのバックポート

別リポジトリで発見・改善した内容をralph-matsuoテンプレートリポジトリに反映する。
テンプレートを常に最新のベストプラクティスに保つことがこのスキルの存在意義。

Arguments: `$ARGUMENTS`

## テンプレートリポジトリ

```
/Users/matsuojumpei/Projects/ralph-matsuo
```

すべてのファイル操作・gitコマンドはこのパスを起点とする。
現在の作業ディレクトリ（CWD）のファイルには変更を加えない。

## Steps

### 1. 変更内容の把握

- `$ARGUMENTS` または会話コンテキストから、何をどう変更するか理解する
- 必要なら現在のリポジトリ（CWD）の該当ファイルを Read で参照し、改善点を特定する
- 変更対象が曖昧な場合はユーザーに確認する

### 2. テンプレート側の現状確認

ralph-matsuoの状態を把握する。以下を並列実行する:

```bash
git -C /Users/matsuojumpei/Projects/ralph-matsuo status --short
```

```bash
git -C /Users/matsuojumpei/Projects/ralph-matsuo log --oneline -3
```

- 該当ファイルを Read で確認する（パスは `/Users/matsuojumpei/Projects/ralph-matsuo/` 起点）
- 未コミットの変更がある場合はユーザーに報告し、続行するか確認する

### 3. 変更の適用

ralph-matsuoのファイルを Edit / Write で変更する。

テンプレートとしての汎用性を意識することが重要:
- 現在のリポジトリ固有のハードコード値（プロジェクト名、API キー等）はテンプレート向けに一般化する
- ralph-matsuoの既存の規約（命名、ディレクトリ構成、コメントスタイル）に合わせる
- 単純にファイルをコピーするのではなく、テンプレートのコンテキストで意味のある形に調整する

### 4. 確認

変更をユーザーに提示する:

```
ralph-matsuoへの変更:

Files:
- [file1]: [変更概要]
- [file2]: [変更概要]

Commit message:
[message]

Proceed?
```

差分が大きい場合は以下で詳細を表示する:
```bash
git -C /Users/matsuojumpei/Projects/ralph-matsuo diff
```

### 5. Commit & Push

ユーザー承認後に実行する:

```bash
git -C /Users/matsuojumpei/Projects/ralph-matsuo add [files...]
git -C /Users/matsuojumpei/Projects/ralph-matsuo commit -m "<message>"
git -C /Users/matsuojumpei/Projects/ralph-matsuo push
```

完了後にコミットハッシュとpush先を報告する。

## コミットメッセージ

- Conventional Commits 形式（prefix は英語、本文は日本語）
- `$ARGUMENTS` やユーザー指示があればそれを尊重する
- 以下を末尾に付与する:
  ```
  Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
  ```

## Rules

- ralph-matsuo 以外のリポジトリのファイルは絶対に変更しない（Read のみ許可）
- `git add .` / `git add -A` は使わない。ファイルを明示的に指定する
- `.env`、credentials 等の機密ファイルはコミットしない
- force push しない
- テンプレートの汎用性を損なう変更（特定プロジェクト名のハードコード等）を検出したら警告する
