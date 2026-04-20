# Polypad — Fix de versioning mode (shared vs local)

Contexto: review do Codex apontou que `.agents/napkin.md` fica untracked ao rodar o plugin, poluindo o git status. Diagnóstico correto, mas a solução não é gitignorar tudo — o polypad suporta dois modos legítimos de uso e o usuário precisa escolher conscientemente.

## Dois modos

**Shared (recomendado pra times):** napkin é commitado no git. Agentes em máquinas diferentes (ex: dev1 em Claude, dev2 em Codex no dia seguinte) compartilham contexto via git. É o caso de uso multi-agente assíncrono que o polypad promete.

**Local (pra dev solo):** napkin é ignorado pelo git. Cada dev tem o próprio, nada é commitado. Mais simples, mas quebra o compartilhamento entre máquinas.

Default: **shared** (alinha com a proposta central do polypad).

## Como usar

1. Abra Claude Code na raiz do repo polypad
2. Cole o prompt abaixo seguido do restante deste documento
3. Claude Code atualiza os arquivos
4. `bash scripts/sync.sh` propaga ao Codex
5. Commit, push, reinstala pra testar

---

## Prompt para o Claude Code

> Vou adicionar suporte a modos de versionamento (shared vs local) no polypad. Siga exatamente as instruções:
>
> 1. Verifique que estamos na raiz do repo polypad
> 2. Substitua `plugins/polypad/commands/init.md` pelo conteúdo da seção "commands/init.md"
> 3. Atualize `plugins/polypad/skills/polypad/SKILL.md` adicionando a nova seção "Versioning modes" logo após a seção "Napkin anatomy" (ou equivalente). Use o conteúdo da seção "SKILL.md — nova seção"
> 4. Atualize o `README.md` adicionando o conteúdo da seção "README.md — patch" na seção "Use in a project"
> 5. Rode `bash scripts/sync.sh` para propagar ao Codex
> 6. Mostre o diff com `git diff --stat`
> 7. Não faça git commit — eu farei manualmente

---

## Arquivo atualizado: `plugins/polypad/commands/init.md`

Substitua todo o conteúdo por:

````markdown
---
description: Initialize polypad in the current repository (creates .agents/napkin.md and configures .gitignore based on versioning mode)
---

Initialize the polypad shared napkin in the current repository.

Steps:

1. Check if `.agents/napkin.md` already exists. If it does, report that and stop.

2. Ask the user which versioning mode they want:

   ```
   Polypad supports two versioning modes:

     1) Shared via git (recommended for teams)
        - .agents/napkin.md is committed to the repo
        - Teammates see each other's context across machines
        - Only .agents/.identity.* stays local

     2) Local only (for solo developers)
        - .agents/ is entirely gitignored
        - Each developer has their own napkin
        - Nothing is committed

   Which mode? [1/2, default: 1]
   ```

3. Wait for the user's response. If they press enter with no value, assume `1`.

4. Create `.agents/` directory if missing.

5. Create `.agents/archive/` directory.

6. Copy the skill's `templates/napkin.md` to `.agents/napkin.md`.

7. Update `.gitignore` based on mode:

   - **Mode 1 (shared):** ensure `.agents/.identity.*` is present in `.gitignore`. Do NOT add `.agents/` itself.
   - **Mode 2 (local):** ensure `.agents/` is present in `.gitignore`. This also covers `.identity.*` and napkin.md.

   If `.gitignore` doesn't exist, create it with the appropriate line.

8. Report to the user:

   - For mode 1: "Polypad initialized in shared mode. Commit `.agents/napkin.md` so your teammates can see the context. `.agents/.identity.*` stays local."
   - For mode 2: "Polypad initialized in local mode. `.agents/` is gitignored — nothing is committed."

9. Suggest adding the polypad engagement snippet to `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md` as appropriate.
````

---

## SKILL.md — nova seção

No arquivo `plugins/polypad/skills/polypad/SKILL.md`, adicione esta seção nova logo após a seção que fala sobre o formato/anatomia do napkin (geralmente chamada "Napkin anatomy" ou "Step 3: Napkin anatomy"):

````markdown
## Versioning modes

Polypad can run in two modes, chosen when `/polypad:init` runs:

**Shared (default):** `.agents/napkin.md` is committed to git, `.agents/.identity.*` is gitignored. Teammates working from different machines see each other's blocks via git pulls. This is the canonical mode for multi-agent async collaboration.

**Local:** `.agents/` is entirely gitignored. Each developer has their own napkin, nothing is committed. Useful when a single developer coordinates multiple AI CLIs on the same machine but does not want the napkin in git history.

When engaging with a napkin, do NOT assume one mode over the other — just read and write normally. The mode is a user choice about git, not about protocol behavior.

If you are engaging in a turn that involves writes and the napkin is inside a git-tracked path, remind the user once per session (only if it comes up naturally in the response): "Note: your napkin is shared via git — remember to commit it periodically so your teammates see the context."
````

---

## README.md — patch

Na seção "Use in a project" do `README.md`, expanda o passo 1 e adicione uma nota sobre os dois modos. O conteúdo novo (substitui a seção "Use in a project" atual):

````markdown
## Use in a project

1. Run `/polypad:init` from any agent. You'll be asked which versioning mode to use:

   - **Shared via git (default)** — `.agents/napkin.md` is committed, teammates share context across machines.
   - **Local only** — `.agents/` is gitignored, each developer has their own napkin.

2. Paste this into your repo's `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`:

   ```
   ## Multi-agent coordination

   This project uses the polypad protocol. For substantive work, read
   .agents/napkin.md (headers first), then append your block under your
   tag. Never edit blocks you didn't author.
   ```

3. Start working. Agents read the napkin before substantive tasks and write their notes after.

### Which versioning mode should I pick?

- You work alone, across multiple CLIs on the same machine → **local**
- You work with a team, anyone might open the repo from any machine → **shared**
- You're not sure → start with **shared** (the default). You can always add `.agents/` to `.gitignore` later.

In shared mode, commit the napkin like any other file:

```bash
git add .agents/napkin.md
git commit -m "polypad: update napkin"
```

Your teammates see your context when they pull.
````

---

## Propagação ao Codex

Após os patches acima, rode:

```bash
bash scripts/sync.sh
```

Isso copia o `SKILL.md` atualizado, `commands/`, etc., pro lado Codex em `.codex/plugins/polypad/`.

---

## Commitar

```bash
git add .
git commit -m "feat: add versioning mode choice (shared/local) to /polypad:init"
git push
```

---

## Testar

Em um repo de teste (pode ser um repo git vazio):

### Teste 1 — Modo shared (default)

```bash
cd /tmp/test-shared
git init
claude
```

Dentro do Claude:

```
/polypad:init
```

Quando perguntado, pressione enter (default 1). Verifique:

```bash
cat .gitignore
# Deve conter: .agents/.identity.*
# NÃO deve conter: .agents/

git status
# Deve mostrar .agents/napkin.md como untracked (pra você commitar)
# .agents/.identity.claude deve estar ignorado
```

### Teste 2 — Modo local

```bash
cd /tmp/test-local
git init
claude
```

```
/polypad:init
```

Escolher 2. Verifique:

```bash
cat .gitignore
# Deve conter: .agents/

git status
# Não deve mostrar nada em .agents/
```

### Teste 3 — Codex reconhece ambos os modos

No mesmo repo de teste shared, abra Codex:

```bash
cd /tmp/test-shared
codex
```

Peça: "leia o napkin do polypad"

Codex deve conseguir ler `.agents/napkin.md` normalmente (ele está lá, foi criado pelo Claude). Não importa o modo — Codex só lê/escreve, não decide versionamento.

---

## O que NÃO muda

- O Stop hook (`stop_check.sh`) continua funcionando igual — ele detecta mtime do arquivo, não se importa com git.
- O `sync.sh` continua copiando Claude → Codex.
- Os comandos `/polypad:status` e `/polypad:archive` continuam funcionando identicamente.

O patch é puramente sobre a escolha de versionamento na inicialização. Resolve o review do Codex sem quebrar o cenário de uso multi-máquina.