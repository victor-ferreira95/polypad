# Polypad — Correção unificada Claude Code + Codex

Este documento foi gerado após analisar:

- Doc oficial do Claude Code: https://code.claude.com/docs/en/plugins e https://code.claude.com/docs/en/plugins-reference
- Doc oficial do Codex: https://developers.openai.com/codex/plugins/build
- Estado atual do repo: https://github.com/victor-ferreira95/polypad

O diagnóstico identificou 4 problemas que impedem o polypad de funcionar em um ou ambos os CLIs:

| # | Problema | Quem afeta | Gravidade |
|---|---|---|---|
| 1 | `SKILL.md` está na raiz, não em `skills/polypad/SKILL.md` | Claude Code | alta |
| 2 | `hooks/hooks.json` sem wrapper `{"hooks": {...}}` (erro "expected record") | Claude Code | crítica |
| 3 | Zero estrutura de plugin do Codex (`.agents/plugins/`, `.codex/`) | Codex CLI | crítica |
| 4 | `plugin.json` pode estar referenciando hooks inline em vez de arquivo | Claude Code | crítica |

A correção reorganiza o repo pra seguir as duas specs ao mesmo tempo, num formato "dual" que o próprio `ui-ux-pro-max-skill` (67k stars) usa.

## Estrutura final desejada

```
polypad/
├── .claude-plugin/
│   └── plugin.json                            ← manifesto Claude Code, referencia skills/hooks por arquivo
├── skills/
│   └── polypad/
│       └── SKILL.md                           ← skill no formato exigido pela doc
├── commands/                                  ← fica onde está
│   ├── init.md
│   ├── status.md
│   └── archive.md
├── hooks/
│   ├── hooks.json                             ← envelopado com {"hooks": {"Stop": [...]}}
│   ├── stop_check.sh                          ← novo, enforcement
│   └── auto_archive.sh                        ← fica
├── templates/                                 ← fica
│   └── napkin.md
├── .agents/
│   └── plugins/
│       └── marketplace.json                   ← marketplace pro Codex (obrigatório)
├── .codex/
│   └── plugins/
│       └── polypad/
│           ├── .codex-plugin/
│           │   └── plugin.json                ← manifesto Codex
│           ├── skills/
│           │   └── polypad/
│           │       └── SKILL.md               ← cópia sincronizada
│           ├── commands/                       ← cópia sincronizada
│           ├── hooks/                          ← cópia sincronizada
│           └── templates/                      ← cópia sincronizada
├── scripts/
│   ├── install.sh                              ← instalação raw skill (multi-CLI manual)
│   └── sync.sh                                 ← mantém Claude ↔ Codex em sincronia
├── README.md                                   ← atualizado com as duas formas de install
├── CHANGELOG.md
├── LICENSE
├── SKILL.md                                    ← REMOVIDO (estava na raiz por engano)
└── .gitignore
```

## Como usar

1. Abra o Claude Code na raiz do repo polypad (cloned localmente)
2. Cole o prompt abaixo seguido do restante deste documento
3. Claude Code aplica as mudanças
4. Rode `claude plugin validate .` pra confirmar que passa
5. Commit + push
6. Reinstale e teste

---

## Prompt para o Claude Code

> Vou reestruturar o repo polypad pra funcionar corretamente em Claude Code e Codex, seguindo a doc oficial de cada um. Siga exatamente as instruções:
>
> 1. Verifique que estamos na raiz do repo polypad (deve existir `SKILL.md` e `.claude-plugin/`)
> 2. Execute as operações da seção "Operações de reorganização" na ordem
> 3. Crie/substitua os arquivos das seções "Arquivos novos/atualizados"
> 4. Rode `chmod +x` nos scripts conforme seção "Permissões"
> 5. Se o comando estiver disponível, rode `claude plugin validate .` e mostre o resultado
> 6. Mostre a árvore final com `find . -type f -not -path './.git/*' | sort`
> 7. Não faça git commit — eu farei manualmente

---

## Operações de reorganização

```bash
# 1. Criar estrutura Claude Code correta (skills/<nome>/SKILL.md)
mkdir -p skills/polypad

# Se SKILL.md existe na raiz, move pra estrutura correta
if [ -f SKILL.md ]; then
    mv SKILL.md skills/polypad/SKILL.md
fi

# 2. Criar estrutura Codex (marketplace + plugin)
mkdir -p .agents/plugins
mkdir -p .codex/plugins/polypad/.codex-plugin
mkdir -p .codex/plugins/polypad/skills/polypad
mkdir -p .codex/plugins/polypad/commands
mkdir -p .codex/plugins/polypad/hooks
mkdir -p .codex/plugins/polypad/templates

# 3. Replicar conteúdo pro Codex (cópia inicial)
cp skills/polypad/SKILL.md .codex/plugins/polypad/skills/polypad/SKILL.md
cp -r commands/* .codex/plugins/polypad/commands/ 2>/dev/null || true
cp -r hooks/* .codex/plugins/polypad/hooks/ 2>/dev/null || true
cp -r templates/* .codex/plugins/polypad/templates/ 2>/dev/null || true
```

---

## Arquivos novos/atualizados

### Arquivo: `.claude-plugin/plugin.json`

Substitua o conteúdo por:

```json
{
  "name": "polypad",
  "version": "0.2.0",
  "description": "Shared append-only napkin for coordinating AI coding agents with mechanical Stop-hook enforcement",
  "author": {
    "name": "Victor Ferreira",
    "url": "https://github.com/victor-ferreira95"
  },
  "homepage": "https://github.com/victor-ferreira95/polypad",
  "repository": "https://github.com/victor-ferreira95/polypad",
  "license": "MIT",
  "keywords": ["multi-agent", "collaboration", "shared-context", "napkin"],
  "hooks": "./hooks/hooks.json"
}
```

Nota importante: não declaramos `skills` explicitamente porque o Claude Code auto-descobre a pasta `skills/` na raiz. A doc diz: "If the manifest specifies `skills`, the default `skills/` directory is not scanned" — queremos que ele use o default.

### Arquivo: `hooks/hooks.json`

Substitua o conteúdo por (o wrapper `{"hooks": {...}}` é obrigatório, foi o que causou o erro "expected record"):

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/stop_check.sh"
          }
        ]
      }
    ]
  }
}
```

### Arquivo: `hooks/stop_check.sh`

Crie se não existir, ou substitua o conteúdo por:

```bash
#!/usr/bin/env bash
# polypad Stop hook
# Runs at the end of every agent turn. Blocks the response if the agent called
# any write/edit/creation tool but did not update .agents/napkin.md.
#
# Claude Code invokes this via the "Stop" hook event with a JSON payload on stdin
# containing the turn's tool calls. Exit code 2 blocks the response and injects
# stderr into the agent's context.

set -euo pipefail

payload=$(cat)

# Prevent infinite loop: if we already asked the agent to fix this once, let it pass.
stop_hook_active=$(echo "$payload" | grep -oE '"stop_hook_active"[[:space:]]*:[[:space:]]*true' || true)
if [ -n "$stop_hook_active" ]; then
    exit 0
fi

# Did the agent call any write-class tool this turn?
write_tools_used=$(echo "$payload" | grep -oE '"name"[[:space:]]*:[[:space:]]*"(Write|Edit|MultiEdit|NotebookEdit|Create)"' || true)

if [ -z "$write_tools_used" ]; then
    # Read-only turn. No enforcement needed.
    exit 0
fi

NAPKIN=".agents/napkin.md"
if [ ! -f "$NAPKIN" ]; then
    # Only enforce if this is clearly a polypad-enabled project.
    if [ -f "CLAUDE.md" ] && grep -qi "polypad" "CLAUDE.md" 2>/dev/null; then
        cat >&2 <<EOF
POLYPAD PROTOCOL VIOLATION

This project is configured to use the polypad protocol (CLAUDE.md references it),
but .agents/napkin.md does not exist. You wrote code this turn without initializing
the napkin.

Action required before you respond to the user:
1. Run /polypad:init to create .agents/napkin.md
2. Add your agent header to the headers section
3. Write a block summarizing what you just did this turn
EOF
        exit 2
    fi
    exit 0
fi

# Napkin exists. Was it modified in the last ~5 minutes (proxy for "this turn")?
if [ -z "$(find "$NAPKIN" -mmin -5 -print 2>/dev/null || true)" ]; then
    cat >&2 <<EOF
POLYPAD PROTOCOL VIOLATION

You called write/edit tools this turn but did not update .agents/napkin.md.

Per the polypad decision rule, any turn that writes code must also append a
block to the napkin under your agent tag.

Action required before you respond to the user:
1. Read the napkin (headers first, narrative if needed)
2. Compact your own blocks if you have more than 5
3. Append a single consolidated block summarizing what you did this turn
4. Then return to the user

Do this now, in the same turn, before your final response.
EOF
    exit 2
fi

exit 0
```

### Arquivo: `.agents/plugins/marketplace.json`

Este é o marketplace manifest específico do Codex. Formato diferente do Claude Code:

```json
{
  "name": "polypad",
  "interface": {
    "displayName": "Polypad"
  },
  "plugins": [
    {
      "name": "polypad",
      "source": {
        "source": "local",
        "path": "./.codex/plugins/polypad"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Productivity"
    }
  ]
}
```

### Arquivo: `.codex/plugins/polypad/.codex-plugin/plugin.json`

Manifesto do plugin no formato Codex:

```json
{
  "name": "polypad",
  "version": "0.2.0",
  "description": "Shared append-only napkin for coordinating AI coding agents with mechanical Stop-hook enforcement",
  "author": {
    "name": "Victor Ferreira",
    "url": "https://github.com/victor-ferreira95"
  },
  "homepage": "https://github.com/victor-ferreira95/polypad",
  "repository": "https://github.com/victor-ferreira95/polypad",
  "license": "MIT",
  "keywords": ["multi-agent", "collaboration", "shared-context", "napkin"],
  "skills": "./skills/",
  "interface": {
    "displayName": "Polypad",
    "shortDescription": "Shared napkin with mechanical enforcement across AI agents",
    "longDescription": "Universal shared napkin that lets Claude Code, Codex CLI, Gemini CLI, Cursor and other agents coordinate via one markdown file with strict write-isolation.",
    "developerName": "Victor Ferreira",
    "category": "Productivity",
    "capabilities": ["Read", "Write"],
    "websiteURL": "https://github.com/victor-ferreira95/polypad"
  }
}
```

### Arquivo: `scripts/sync.sh` (novo)

Mantém os dois em sincronia quando você editar o lado Claude:

```bash
#!/usr/bin/env bash
# Sync Claude Code plugin content to Codex plugin structure.
# Run this after editing SKILL.md, commands/, hooks/, or templates/.

set -euo pipefail

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
SRC_SKILL="$ROOT/skills/polypad/SKILL.md"
DST_BASE="$ROOT/.codex/plugins/polypad"

if [ ! -f "$SRC_SKILL" ]; then
    echo "ERROR: $SRC_SKILL does not exist. Are you in the repo root?"
    exit 1
fi

echo "Syncing Claude Code plugin -> Codex plugin"

# SKILL.md (Codex expects skills/<n>/SKILL.md)
mkdir -p "$DST_BASE/skills/polypad"
cp "$SRC_SKILL" "$DST_BASE/skills/polypad/SKILL.md"
echo "  + skills/polypad/SKILL.md"

# commands/
rm -rf "$DST_BASE/commands"
cp -r "$ROOT/commands" "$DST_BASE/commands"
echo "  + commands/"

# hooks/ (including scripts)
rm -rf "$DST_BASE/hooks"
cp -r "$ROOT/hooks" "$DST_BASE/hooks"
chmod +x "$DST_BASE/hooks/"*.sh 2>/dev/null || true
echo "  + hooks/"

# templates/
rm -rf "$DST_BASE/templates"
cp -r "$ROOT/templates" "$DST_BASE/templates"
echo "  + templates/"

echo "Done."
```

### Arquivo: `scripts/install.sh` (atualizado)

Instala como raw skill em múltiplos CLIs, agora apontando pras fontes corretas:

```bash
#!/usr/bin/env bash
# polypad universal installer (manual raw skill install, no marketplace)
# Detects installed AI CLIs and copies the skill into each one's skills directory.

set -euo pipefail

SKILL_NAME="polypad"
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
CLAUDE_SOURCE="$REPO_ROOT/skills/polypad"
CODEX_SOURCE="$REPO_ROOT/.codex/plugins/polypad/skills/polypad"

echo "polypad installer"
echo ""

installed_into=()

install_to() {
    local target="$1"
    local label="$2"
    local source="$3"
    mkdir -p "$(dirname "$target")"
    if [ -d "$target" ]; then
        echo "  ↻ updating $label at $target"
        rm -rf "$target"
    else
        echo "  + installing $label at $target"
    fi
    cp -r "$source" "$target"
    installed_into+=("$label")
}

if command -v claude >/dev/null 2>&1 || [ -d "$HOME/.claude" ]; then
    install_to "$HOME/.claude/skills/$SKILL_NAME" "Claude Code" "$CLAUDE_SOURCE"
fi
if command -v codex >/dev/null 2>&1 || [ -d "$HOME/.codex" ]; then
    install_to "$HOME/.codex/skills/$SKILL_NAME" "Codex CLI" "$CODEX_SOURCE"
fi
if command -v gemini >/dev/null 2>&1 || [ -d "$HOME/.gemini" ]; then
    install_to "$HOME/.gemini/skills/$SKILL_NAME" "Gemini CLI" "$CLAUDE_SOURCE"
fi
if [ -d "$HOME/.cursor" ]; then
    install_to "$HOME/.cursor/skills/$SKILL_NAME" "Cursor" "$CLAUDE_SOURCE"
fi

echo ""
if [ ${#installed_into[@]} -eq 0 ]; then
    echo "No supported AI CLIs detected."
    exit 1
fi

echo "Installed polypad into: ${installed_into[*]}"
echo ""
echo "Next steps:"
echo "  1. Restart your AI CLI(s)."
echo "  2. In a repo, run /polypad:init to create the shared napkin."
```

### Arquivo: `README.md` (atualizado)

Substitua o conteúdo por:

````markdown
# polypad

Universal shared napkin for AI coding agents. Claude Code, Codex CLI, Gemini CLI, Cursor — all read and write the same `.agents/napkin.md`, with strict write-isolation so no agent ever overwrites another.

**The user orchestrates. Polypad remembers.**

## Install

### Claude Code

```
/plugin marketplace add victor-ferreira95/polypad
/plugin menu
```

Select `polypad`, then choose the scope: user / project / local.

### Codex CLI

```
codex marketplace add victor-ferreira95/polypad
```

Then open `/plugins` inside Codex, select Polypad, and install.

### Manual raw skill install (any CLI, no marketplace)

```bash
git clone https://github.com/victor-ferreira95/polypad.git
cd polypad
bash scripts/install.sh
```

Detects installed AI CLIs and installs the skill into each.

## Use in a project

1. Run `/polypad:init` from any agent — creates `.agents/napkin.md`.
2. Paste this into your repo's `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`:

   ```
   ## Multi-agent coordination

   This project uses the polypad protocol. For substantive work, read
   .agents/napkin.md (headers first), then append your block under your
   tag. Never edit blocks you didn't author.
   ```

3. Start working. Agents read the napkin before substantive tasks and write their notes after.

## Token economy

- **Skip on trivial turns.** Factual questions don't engage the napkin.
- **Lazy load.** Agents read compressed headers first (~300 tokens); full narrative only if needed.
- **Per-author compaction.** Each agent compacts its own blocks when it has more than 5.
- **Auto-archive.** Napkins with blocks older than 3 days are auto-archived.
- **Mechanical enforcement.** A Stop hook blocks the agent's response if it wrote code without updating the napkin.

Typical cost: ~2-3k tokens per engaged turn. Trivial turns: zero.

## Commands

- `/polypad:init` — initialize in current repo
- `/polypad:status` — show size, age, block counts per agent
- `/polypad:archive` — archive current napkin, carry headers forward

## Uninstall

### Claude Code

```
/plugin menu
```

Select polypad, uninstall. Then optionally:

```
/plugin marketplace remove polypad
```

### Codex CLI

Open `/plugins`, select polypad, uninstall. Then optionally:

```
codex marketplace remove polypad
```

### Manual

```bash
rm -rf ~/.claude/skills/polypad
rm -rf ~/.codex/skills/polypad
rm -rf ~/.gemini/skills/polypad
rm -rf ~/.cursor/skills/polypad
```

## Contributing

When editing the skill, edit in `skills/polypad/SKILL.md` (Claude Code side) and run `bash scripts/sync.sh` to propagate to Codex.

## License

MIT
````

---

## Permissões

```bash
chmod +x scripts/install.sh
chmod +x scripts/sync.sh
chmod +x hooks/stop_check.sh
chmod +x hooks/auto_archive.sh 2>/dev/null || true
chmod +x .codex/plugins/polypad/hooks/stop_check.sh 2>/dev/null || true
chmod +x .codex/plugins/polypad/hooks/auto_archive.sh 2>/dev/null || true
```

---

## Validar

Se tiver `claude` CLI disponível:

```bash
claude plugin validate .
```

Deve retornar ok ou sucesso. Se der erro, a mensagem já aponta o campo específico.

---

## Commitar

```bash
git add .
git commit -m "fix: restructure for Claude Code + Codex compatibility per official docs"
git push

git tag -d v0.2.0 2>/dev/null || true
git push origin :refs/tags/v0.2.0 2>/dev/null || true
git tag v0.2.0
git push --tags
```

---

## Testar no Claude Code

```
/plugin uninstall polypad
/plugin marketplace remove polypad
/plugin marketplace add victor-ferreira95/polypad
/plugin menu
```

Selecionar polypad. Deve instalar **sem erro de Hook load failed**.

Depois:

```
/polypad:init
```

Se executa, plugin carregou corretamente.

Teste o enforcement:

1. Peça pro Claude: "crie test.txt com hello"
2. Claude usa Write
3. Stop hook dispara no final do turno
4. Como napkin.md não foi atualizado, hook bloqueia com mensagem de violation
5. Claude volta, escreve bloco no napkin, aí sim responde

## Testar no Codex

```
codex marketplace add victor-ferreira95/polypad
```

Deve reconhecer o marketplace (lendo `.agents/plugins/marketplace.json`). Depois dentro do Codex:

```
/plugins
```

Selecionar polypad, instalar. Testar o mesmo fluxo: pedir uma tarefa que escreve arquivo e verificar se o hook dispara.

---

## Se algo falhar

**Claude Code**: rode `claude --debug` e procure por "loading plugin" pra ver exatamente onde travou.

**Codex**: rode `codex --version` e garanta que é >= 0.118.0 (versão que trouxe `marketplace add`).

Se `/polypad:init` não aparecer como slash command mesmo após reinstalar, provavelmente o Claude Code está usando namespace plugin: os comandos aparecem como `/polypad:init` (com namespace do plugin). Se você instalou como skill raw via `scripts/install.sh`, o nome pode variar — depende da convenção de cada CLI.