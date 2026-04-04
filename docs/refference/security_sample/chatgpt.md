Webアプリケーションを作ったんだけど脆弱性がないかとかをチェックできるskillとかmcpとかツールってない？

今ある選択肢を、LLM向けの「skill / MCP」と、普通のセキュリティ診断ツールに分けて整理してみます。実運用で使えそうなものを優先して確認します。

思考時間: 18s

ある。
ただ、「これ1個で脆弱性チェック完了」みたいな万能 skill / MCP はなくて、実際は SAST + SCA + DAST + secrets を組み合わせるのが基本です。GitHub CodeQL はコード中の脆弱性やバグ系の検出、Semgrep は SAST / SCA / secrets、OWASP ZAP は実際に動くWebアプリに対する DAST、自動依存関係チェックなら OWASP Dependency-Check や Snyk が定番です。

MCP として使いやすい候補でいうと、いまはかなり揃ってきています。
Semgrep 公式は Semgrep MCP Server を出していて、AI コーディングアシスタントから Semgrep スキャンを直接呼べます。Snyk も Snyk CLI の snyk mcp で MCP 対応しています。ZAP も公式そのものではないですが、OSS の mcp-zap-server みたいな MCP サーバーがあり、spider / active scan / report 生成まで AI から叩ける構成が出ています。

なので、あなたみたいに「Webアプリを作って、LLM や Claude Code からチェックしたい」なら、まずはこの3層が現実的です。
1. Semgrep MCP でコード静的解析、2. Snyk MCP で依存関係・コンテナ・IaC も見る、3. ZAP で起動済みアプリに対して動的診断、という形です。Semgrep は CI/CD への組み込みも案内があり、Snyk CLI は test / code test / container test / iac test に分かれていて、対象を広く見られます。ZAP は自動化用ドキュメントがかなり整っています。

「skill」はあるか？ という意味だと、Claude 用の“公式の定番 skill”として脆弱性診断専用のものが広く標準化されている感じはまだ弱いです。現状は MCP でスキャナを繋ぐか、CLAUDE.md / custom instructions で「PRごとに Semgrep → Snyk → ZAP の順で確認して報告」という運用 skill を自作するのが一番ハマります。MCP の方が、LLM が“推測”ではなく実際のスキャナ結果に基づいて返せるので信頼しやすいです。これは Semgrep / Snyk / ZAP 側がそれぞれスキャン実体を持っているからです。

個人的なおすすめ順はこうです。
最小構成なら GitHub CodeQL + Semgrep。GitHub 上で回しやすく、PR に乗せやすいです。もう一歩ちゃんとやるなら + Snyk。Webアプリとしての挙動まで見たいなら + ZAP。GitHub Code Scanning は CodeQL を使ってアラートを GitHub に出せますし、CodeQL は GitHub の公式なコード解析エンジンです。

逆に注意点として、LLM 単体に「このコード危ない？」と聞くだけでは不十分です。依存ライブラリの既知 CVE、実際に起動したときの認証まわり、HTTP ヘッダ、SSRF / XSS / CSRF 的な挙動は、専用スキャナや実行環境を通した方が確実です。OWASP の Dependency-Check は公開済み脆弱性を依存関係から拾う SCA ツールですし、ZAP は自動化前提の DAST を提供しています。

あなた向けに一番実用的な答えだけまとめると、
「まず入れるなら Semgrep MCP」、
「依存関係も見るなら Snyk MCP か OWASP Dependency-Check」、
「実際のWeb挙動まで診断したいなら ZAP MCP / ZAP自動化」
です。GitHub を使っているなら CodeQL を CI で常時回すのもかなり相性がいいです。

必要なら次に、**Claude Code / Codex CLI / GitHub Actions 前提で、あなたの構成に合う“脆弱性チェック用の最小セット”**をそのままコピペできる形で組みます。
