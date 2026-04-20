# Polypad — Fix race condition no `.identity`

Problema: o arquivo `.agents/.identity` era único e compartilhado entre CLIs. Se Claude Code e Codex rodassem em paralelo no mesmo repo na primeira vez, podiam sobrescrever um ao outro, fazendo um agente herdar a identidade errada em sessões futuras.

Fix: um arquivo por CLI (`.identity.claude`, `.identity.codex`, `.identity.gemini`). Impossível colidir por design.

## Como usar

1. Abra Claude Code na raiz do repo polypad
2. Cole o prompt abaixo seguido do restante deste documento
3. Claude Code atualiza os arquivos relevantes
4. Rode `bash scripts/sync.sh` pra propagar ao Codex
5. Revise, commite, pushe

---

## Prompt para o Claude Code

> Vou corrigir a race condition no `.agents/.identity` do polypad usando arquivos por CLI. Siga as instruções:
>
> 1. Verifique que estamos na raiz do repo polypad (deve existir `plugins/polypad/skills/polypad/SKILL.md`)
> 2. Atualize o arquivo `plugins/polypad/skills/polypad/SKILL.md` substituindo a seção de identificação conforme a seção "Patch no SKILL.md"
> 3. Atualize `plugins/polypad/commands/init.md` conforme seção "Patch no init command"
> 4. Atualize `.gitignore` conforme seção "Patch no .gitignore"
> 5. Rode `bash scripts/sync.sh` pra propagar ao Codex
> 6. Mostre o diff com `git diff`
> 7. Não faça git commit — eu farei manualmente

---

## Patch no SKILL.md

### Arquivo: `plugins/polypad/skills/polypad/SKILL.md`

Localize a seção **"Step 2: Identify yourself"** (ou equivalente, que fala sobre `.agents/.identity`). Substitua TODA essa seção pelo conteúdo abaixo:

```markdown
## Step 2: Identify yourself

Each CLI uses its own identity file, preventing race conditions when multiple agents run simultaneously in the same repo.

1. Detect your CLI from environment variables and pick your identity file:

   | Environment variable | Identity file | Default tag |
   |---|---|---|
   | `CLAUDE_CODE=1` | `.agents/.identity.claude` | `claude` |
   | `CODEX_CLI=1` | `.agents/.identity.codex` | `codex` |
   | `GEMINI_CLI=1` | `.agents/.identity.gemini` | `gemini` |
   | (none of the above) | `.agents/.identity.<cli>` where `<cli>` is your CLI name in lowercase | prompt the user |

2. Read your identity file:
   - If it exists, use its single-line content as your author tag for this session.
   - If it doesn't exist, create it with your default tag (e.g., `echo "claude" > .agents/.identity.claude`). If no default applies, ask the user: "Which tag should I use in the polypad? (suggested based on your CLI)"

3. Use the resulting tag for every block you write and for your header in the napkin. Tags are lowercase slugs: `claude`, `codex`, `gemini`, `cursor`, `claude-opus`, `claude-sonnet`, etc.

**Why per-CLI files:** if two CLIs initialize in parallel (first run on a shared repo), a single shared `.agents/.identity` file would race — one agent could overwrite the other's tag. Per-CLI files make concurrent access safe by construction: each agent only ever writes its own file.

The identity files are gitignored via the `.agents/.identity.*` pattern — each user's local setup decides their tags, nothing is committed.
```

---

## Patch no init command

### Arquivo: `plugins/polypad/commands/init.md`

Garanta que o step sobre `.gitignore` inclua o pattern correto. Se o arquivo tiver a linha mencionando `.agents/.identity` sem o wildcard, substitua por `.agents/.identity.*`. Se já está correto, não precisa mudar.

Exemplo de como deve ficar a linha:

```markdown
5. Add `.agents/.identity.*` to `.gitignore` if not already present (per-CLI identity files, should not be committed).
```

---

## Patch no .gitignore

### Arquivo: `.gitignore` (raiz do repo)

Adicione a linha `.agents/.identity.*` se não estiver lá. Se já tiver `.agents/.identity` sem o wildcard, substitua por `.agents/.identity.*`.

Conteúdo esperado do `.gitignore` após o patch (adicionar apenas se faltar):

```
.DS_Store
node_modules/
*.log
*.tmp
.agents/.identity.*
.claude/settings.local.json
```

---

## Propagação ao Codex

Após os patches acima, rode:

```bash
bash scripts/sync.sh
```

Esse comando copia o `SKILL.md` atualizado, `commands/`, `hooks/`, `templates/` de `plugins/polypad/` para `.codex/plugins/polypad/`, mantendo os dois em sincronia.

---

## Validar

```bash
claude plugin validate .
```

Deve passar sem erros. Se der qualquer falha, me mande a saída.

---

## Commitar

```bash
git add .
git commit -m "fix: per-CLI identity files to prevent race condition on parallel init"
git push
```

---

## Testar

Em um projeto de teste, com Claude Code já instalado:

1. Rode `/polypad:init` (cria `.agents/napkin.md` e `.agents/archive/`)
2. Verifique que Claude cria `.agents/.identity.claude` com conteúdo "claude":
   ```bash
   cat .agents/.identity.claude
   ```
3. Abra Codex no mesmo projeto em outro terminal. Peça "inicialize o polypad" (ou use `$polypad`)
4. Verifique que Codex criou seu próprio arquivo `.agents/.identity.codex` com "codex":
   ```bash
   cat .agents/.identity.codex
   ls -la .agents/
   ```
5. Os dois arquivos coexistem, ninguém sobrescreve o outro.

No napkin, cada agente usa a tag do próprio arquivo de identidade, e os blocos ficam corretamente separados sem risco de confusão entre agentes.