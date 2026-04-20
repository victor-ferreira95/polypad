# Polypad — Adicionar suporte dual a Codex CLI

O Codex CLI usa estrutura de plugin **diferente** do Claude Code. Este documento adiciona a estrutura paralela do Codex ao mesmo repo, permitindo que ambos os CLIs instalem via marketplace.

## Diferenças principais

| Item | Claude Code | Codex |
|---|---|---|
| Pasta do manifesto | `.claude-plugin/` | `.codex-plugin/` |
| Marketplace path | `.claude-plugin/marketplace.json` | `.agents/plugins/marketplace.json` |
| Formato `source` | string ou objeto github | sempre objeto `{source: "local", path: ...}` |
| Campo `skills` no plugin.json | auto-detectado | obrigatório |
| Localização do SKILL.md | raiz do plugin | `skills/<nome>/SKILL.md` |

Por isso vamos manter **duas cópias paralelas** do mesmo conteúdo — uma pra cada CLI.

## Como usar

1. Abra o Claude Code na raiz do repo polypad
2. Cole o prompt abaixo seguido do restante deste documento
3. Claude Code fará a migração
4. Revise, commite e pushe

---

## Prompt para o Claude Code

> Vou adicionar suporte ao Codex CLI no repo polypad. O Codex usa estrutura diferente do Claude Code, então vou duplicar o conteúdo do plugin numa estrutura paralela. Siga exatamente as instruções:
>
> 1. Verifique que estamos na raiz do repo polypad (deve existir `plugins/polypad/` e `.claude-plugin/`)
> 2. Execute as operações da seção "Operações" na ordem
> 3. Crie cada arquivo novo com o conteúdo literal da seção "Conteúdo dos novos arquivos"
> 4. Atualize os arquivos conforme seção "Arquivos atualizados"
> 5. Rode `chmod +x scripts/install.sh` e `chmod +x .codex/plugins/polypad/hooks/auto_archive.sh`
> 6. Mostre a árvore final com `find . -type f -not -path './.git/*' | sort`
> 7. Não faça git commit — eu farei manualmente

---

## Operações

Execute nesta ordem:

```bash
# 1. Criar estrutura do Codex
mkdir -p .agents/plugins
mkdir -p .codex/plugins/polypad/.codex-plugin
mkdir -p .codex/plugins/polypad/skills/polypad

# 2. Copiar SKILL.md pra estrutura do Codex (formato skills/<nome>/SKILL.md)
cp plugins/polypad/SKILL.md .codex/plugins/polypad/skills/polypad/SKILL.md

# 3. Copiar commands, hooks, templates — replicando
cp -r plugins/polypad/commands .codex/plugins/polypad/commands
cp -r plugins/polypad/hooks .codex/plugins/polypad/hooks
cp -r plugins/polypad/templates .codex/plugins/polypad/templates
```

---

## Conteúdo dos novos arquivos

### Arquivo: `.agents/plugins/marketplace.json`

Este é o manifesto de marketplace do Codex. Note o formato diferente do Claude Code: `source` é sempre objeto, com campos `policy` e `category` obrigatórios.

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

Manifesto do plugin no formato Codex. Atenção ao campo `"skills": "./skills/"` — diferente do Claude Code, aqui é obrigatório apontar explicitamente a pasta de skills.

```json
{
  "name": "polypad",
  "version": "0.1.0",
  "description": "Shared append-only napkin for coordinating AI coding agents",
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
    "shortDescription": "Shared napkin for coordinating AI coding agents",
    "longDescription": "Universal shared napkin that lets Claude Code, Codex CLI, Gemini CLI, Cursor and other agents coordinate via one markdown file with strict write-isolation.",
    "developerName": "Victor Ferreira",
    "category": "Productivity",
    "capabilities": ["Read", "Write"],
    "websiteURL": "https://github.com/victor-ferreira95/polypad"
  }
}
```

---

## Arquivos atualizados

### Arquivo: `README.md`

Substitua todo o conteúdo por (note as duas seções de instalação separadas, uma pra Claude Code e outra pra Codex):

````markdown
# polypad

Universal shared napkin for AI coding agents. Claude Code, Codex CLI, Gemini CLI, Cursor, and any other tool following the open SKILL.md spec can read and write the same file — with strict write-isolation so no agent ever overwrites another.

**The user orchestrates. Polypad remembers.**

## What it does

You ask Claude to plan a feature. Claude writes its plan into the napkin, under its tag.

You ask Codex to implement it. Codex reads the napkin, implements, writes its own block.

You ask Gemini to translate the UI copy. Gemini reads what both did, translates, logs its work.

Every agent starts each session fully aware of what the others thought, decided, and built — without you having to re-explain anything.

## What it isn't

Not a task manager. Not a delegation protocol. No specs, no tickets, no phases.

It's one markdown file with blocks. That's it.

## Installation

### Claude Code

```
/plugin marketplace add victor-ferreira95/polypad
/plugin menu
```

Select `polypad` from the menu, then choose the scope:

- **Install for you (user scope)** — available in all your projects
- **Install for all collaborators on this repository (project scope)** — committed to the repo, shared with team
- **Install for you, in this repo only (local scope)** — this repo only, not committed

Restart Claude Code after install.

### Codex CLI

```
codex marketplace add victor-ferreira95/polypad
```

Then open the plugin directory and install Polypad:

```
/plugins
```

Select `polypad` and install. Restart Codex after install.

### Manual install (all CLIs, without marketplace)

If you prefer to install as a raw skill across multiple AI CLIs:

```bash
git clone https://github.com/victor-ferreira95/polypad.git
cd polypad
bash scripts/install.sh
```

The script detects which AI CLIs you have (Claude Code, Codex, Gemini, Cursor) and installs the skill into each.

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

Typical cost: ~2-3k tokens per engaged turn. Trivial turns: zero.

Use `/polypad:status` to check size and get archival recommendations.

## Commands

- `/polypad:init` — initialize in current repo
- `/polypad:status` — show size, age, block counts per agent
- `/polypad:archive` — archive current napkin, carry headers forward

## Uninstall

### Claude Code

```
/plugin menu
```

Navigate to `polypad`, select Uninstall. To remove the marketplace entirely:

```
/plugin marketplace remove polypad
```

### Codex CLI

```
/plugins
```

Find polypad, uninstall. Or:

```
codex marketplace remove polypad
```

### Manual (if installed via scripts/install.sh)

```bash
rm -rf ~/.claude/skills/polypad
rm -rf ~/.codex/skills/polypad
rm -rf ~/.gemini/skills/polypad
rm -rf ~/.cursor/skills/polypad
```

## Design principles

1. **Full read, isolated write.** Everyone sees everything. No one touches anyone else's blocks.
2. **Lazy load.** Headers first. Narrative on demand.
3. **User orchestrates.** Polypad has no opinion on who should do what.
4. **No ceremony.** No tickets, specs, phases, or delegation protocols.
5. **Cheap by default.** Trivial turns skip the napkin entirely.

## License

MIT
````

### Arquivo: `scripts/install.sh`

Substitua por (agora detecta qual CLI e usa a estrutura correta):

```bash
#!/usr/bin/env bash
# polypad universal installer
# Detects installed AI CLIs and installs the skill into each one's skills directory.

set -euo pipefail

SKILL_NAME="polypad"
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
CLAUDE_SKILL_SOURCE="$REPO_ROOT/plugins/polypad"
CODEX_SKILL_SOURCE="$REPO_ROOT/.codex/plugins/polypad/skills/polypad"

echo "polypad installer"
echo ""

installed_into=()

install_claude() {
    local target="$HOME/.claude/skills/$SKILL_NAME"
    mkdir -p "$(dirname "$target")"
    if [ -d "$target" ]; then
        echo "  ↻ updating Claude Code skill at $target"
        rm -rf "$target"
    else
        echo "  + installing Claude Code skill at $target"
    fi
    cp -r "$CLAUDE_SKILL_SOURCE" "$target"
    chmod +x "$target/hooks/auto_archive.sh" 2>/dev/null || true
    installed_into+=("Claude Code")
}

install_codex() {
    # Codex expects skills at ~/.codex/skills/<name>/SKILL.md
    local target="$HOME/.codex/skills/$SKILL_NAME"
    mkdir -p "$(dirname "$target")"
    if [ -d "$target" ]; then
        echo "  ↻ updating Codex skill at $target"
        rm -rf "$target"
    else
        echo "  + installing Codex skill at $target"
    fi
    cp -r "$CODEX_SKILL_SOURCE" "$target"
    chmod +x "$target/hooks/auto_archive.sh" 2>/dev/null || true
    installed_into+=("Codex CLI")
}

install_gemini() {
    local target="$HOME/.gemini/skills/$SKILL_NAME"
    mkdir -p "$(dirname "$target")"
    if [ -d "$target" ]; then
        echo "  ↻ updating Gemini CLI skill at $target"
        rm -rf "$target"
    else
        echo "  + installing Gemini CLI skill at $target"
    fi
    cp -r "$CLAUDE_SKILL_SOURCE" "$target"
    chmod +x "$target/hooks/auto_archive.sh" 2>/dev/null || true
    installed_into+=("Gemini CLI")
}

install_cursor() {
    local target="$HOME/.cursor/skills/$SKILL_NAME"
    mkdir -p "$(dirname "$target")"
    if [ -d "$target" ]; then
        echo "  ↻ updating Cursor skill at $target"
        rm -rf "$target"
    else
        echo "  + installing Cursor skill at $target"
    fi
    cp -r "$CLAUDE_SKILL_SOURCE" "$target"
    chmod +x "$target/hooks/auto_archive.sh" 2>/dev/null || true
    installed_into+=("Cursor")
}

if command -v claude >/dev/null 2>&1 || [ -d "$HOME/.claude" ]; then
    install_claude
fi

if command -v codex >/dev/null 2>&1 || [ -d "$HOME/.codex" ]; then
    install_codex
fi

if command -v gemini >/dev/null 2>&1 || [ -d "$HOME/.gemini" ]; then
    install_gemini
fi

if [ -d "$HOME/.cursor" ]; then
    install_cursor
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
echo "  3. Add this snippet to your project's CLAUDE.md / AGENTS.md / GEMINI.md:"
echo ""
echo "     ## Multi-agent coordination"
echo "     This project uses the polypad protocol. For substantive work, read"
echo "     .agents/napkin.md (headers first), then append your block under your"
echo "     tag. Never edit blocks you didn't author."
```

### Arquivo: `.gitignore`

Adicione a linha `.claude/settings.local.json` se ainda não estiver lá:

```
.DS_Store
node_modules/
*.log
*.tmp
.claude/settings.local.json
```

---

## Estrutura final esperada

Depois das operações, `find . -type f -not -path './.git/*' | sort` deve retornar:

```
./.agents/plugins/marketplace.json
./.claude-plugin/marketplace.json
./.codex/plugins/polypad/.codex-plugin/plugin.json
./.codex/plugins/polypad/commands/archive.md
./.codex/plugins/polypad/commands/init.md
./.codex/plugins/polypad/commands/status.md
./.codex/plugins/polypad/hooks/auto_archive.sh
./.codex/plugins/polypad/skills/polypad/SKILL.md
./.codex/plugins/polypad/templates/napkin.md
./.gitignore
./CHANGELOG.md
./LICENSE
./README.md
./plugins/polypad/.claude-plugin/plugin.json
./plugins/polypad/SKILL.md
./plugins/polypad/commands/archive.md
./plugins/polypad/commands/init.md
./plugins/polypad/commands/status.md
./plugins/polypad/hooks/auto_archive.sh
./plugins/polypad/templates/napkin.md
./scripts/install.sh
```

---

## Importante: manter os dois em sincronia

Toda vez que você editar o `SKILL.md`, os `commands/`, `hooks/` ou `templates/`, precisa atualizar nos **dois lugares**:

- `plugins/polypad/` (Claude Code)
- `.codex/plugins/polypad/skills/polypad/` e `.codex/plugins/polypad/{commands,hooks,templates}/` (Codex)

Para facilitar isso no futuro, considere criar um script `scripts/sync.sh` que copia do Claude Code pro Codex automaticamente. Pode ser algo simples:

```bash
#!/usr/bin/env bash
# Sync Claude Code plugin content to Codex plugin structure
set -euo pipefail

SRC="plugins/polypad"
DST="./.codex/plugins/polypad"

cp "$SRC/SKILL.md" "$DST/skills/polypad/SKILL.md"
cp -r "$SRC/commands" "$DST/commands"
cp -r "$SRC/hooks" "$DST/hooks"
cp -r "$SRC/templates" "$DST/templates"
chmod +x "$DST/hooks/auto_archive.sh" 2>/dev/null || true

echo "Synced Claude Code plugin → Codex plugin"
```

Se quiser, pode criar esse arquivo agora em `scripts/sync.sh` pra facilitar futuras atualizações.

---

## Após o Claude Code terminar

```bash
git add .
git commit -m "feat: add Codex CLI support via dual marketplace structure"
git push

# atualizar tag v0.1.0 pra apontar pro novo commit
git tag -d v0.1.0
git push origin :refs/tags/v0.1.0
git tag v0.1.0
git push --tags
```

---

## Testando depois do push

### Claude Code

```
/plugin marketplace remove polypad
/plugin marketplace add victor-ferreira95/polypad
/plugin menu
```

Deve funcionar igual antes.

### Codex CLI

```bash
codex marketplace add victor-ferreira95/polypad
```

Depois dentro do Codex:

```
/plugins
```

Deve listar polypad. Instalar e reiniciar Codex. Depois testar `/polypad:init` (ou equivalente) em um projeto.

Se der erro de marketplace no Codex, verifique que o arquivo `.agents/plugins/marketplace.json` tem `"source": "local"` e `path` relativo começando com `./`.

---

## Troubleshooting Codex

Se `codex marketplace add victor-ferreira95/polypad` falhar:

1. **Versão do Codex:** Precisa ser >= 0.118.0 (a que implementou `marketplace add` em março/2026). Verifique com `codex --version` e atualize se necessário: `npm install -g @openai/codex@latest`.

2. **Cache corrompido:** Limpe o cache e tente de novo:
   ```bash
   rm -rf ~/.codex/plugins/cache
   codex marketplace add victor-ferreira95/polypad
   ```

3. **Schema inválido:** Verifique que `.agents/plugins/marketplace.json` tem todos os campos obrigatórios: `source` (objeto), `policy.installation`, `policy.authentication`, `category`.

4. **Usar URL direta:** Se o shorthand `owner/repo` não funcionar, tente a URL completa:
   ```bash
   codex marketplace add https://github.com/victor-ferreira95/polypad.git
   ```