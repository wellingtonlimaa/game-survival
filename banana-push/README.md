# 🍌 banana-push

Script Node.js zero-dependência que automatiza o fluxo de envio para o GitHub.

Trabalha com o modelo:

```
main (produção) ← develop (integração) ← feature/* (trabalho)
```

## Instalação num projeto Node.js

### Passo 1: copiar os arquivos

Copie `scripts/banana-push.js` para a pasta `scripts/` do seu projeto.

```
seu-projeto/
├── scripts/
│   └── banana-push.js   ← cole aqui
├── package.json
└── ...
```

### Passo 2: adicionar ao `package.json`

```jsonc
{
  "scripts": {
    "push": "node scripts/banana-push.js"
  },
  // opcional — customiza configurações
  "bananaPush": {
    "baseBranch": "develop",
    "productionBranch": "main"
  }
}
```

### Passo 3: rodar

```bash
npm run push
```

## O que o script faz

1. **Pré-flight checks** — confere se é repo git, se tem remote `origin`, se `develop` existe
2. **Detecta mudanças não commitadas** — oferece 3 opções (carregar pra nova branch, fazer stash, abortar)
3. `git checkout develop` + `git pull origin develop`
4. **Pergunta o nome da nova branch** + valida formato (a-z, 0-9, `-`, `_`, `/`, `.`)
5. **Checa se a branch já existe** localmente OU no remoto
6. `git checkout -b <nome>`
7. Se houve stash, restaura na nova branch
8. **Verifica se há mudanças** — se não, avisa e oferece remover branch vazia
9. **Mostra os arquivos** que entrarão no commit e pede confirmação
10. **Pergunta o tipo semântico** (feat, fix, refactor, style, docs, chore, test, perf, build, ci)
11. **Pergunta a mensagem** + valida tamanho (≤ 72 chars)
12. `git add .` + `git commit -m "tipo: msg"` + `git push -u origin <nome>`
13. **Mostra a URL do Pull Request** prontinha pra abrir

## Recursos de segurança

| Proteção | Como funciona |
|---|---|
| Sem `shell:true` | Usa `spawn` com array de argumentos — mensagens com aspas/`$`/`;` são seguras |
| Stash automático | Não perde trabalho ao mudar de branch |
| Validação de nome | Bloqueia nomes inválidos antes de chegar no git |
| Checagem local+remoto | Evita conflito de nomes em equipe |
| `-u` no primeiro push | Configura upstream automaticamente |
| Trata Ctrl+C | Sai limpo sem stack trace |
| Falha cedo | Para no primeiro erro, não pula passos |
| Detecta pre-commit fails | Não declara sucesso se commit falhou |

## Configuração

Adicione `bananaPush` ao seu `package.json`:

```jsonc
{
  "bananaPush": {
    "baseBranch": "develop",          // padrão: "develop"
    "productionBranch": "main",       // padrão: "main"
    "allowedTypes": [                 // padrão: 10 tipos convencionais
      { "key": "feat", "desc": "nova funcionalidade" },
      { "key": "fix",  "desc": "correção" }
    ]
  }
}
```

## Tipos semânticos padrão

- **feat** — nova funcionalidade
- **fix** — correção de erro
- **refactor** — melhoria no código sem alterar comportamento
- **style** — alteração visual ou de formatação
- **docs** — alteração em documentação
- **chore** — ajustes internos, configurações ou tarefas gerais
- **test** — criação ou ajuste de testes
- **perf** — melhoria de performance
- **build** — ajustes em build, dependências ou ambiente
- **ci** — ajustes em pipeline ou integração contínua

## Fluxo visual

```
[npm run push]
      │
      ▼
┌─────────────────────────┐
│ Pré-flight: repo? remote? develop? │
└─────────────────────────┘
      │
      ▼
┌─────────────────────────┐
│ Working tree sujo?      │
│   ├─ carregar mudanças  │
│   ├─ stash              │
│   └─ abortar            │
└─────────────────────────┘
      │
      ▼
  git checkout develop
  git pull origin develop
      │
      ▼
┌─────────────────────────┐
│ Nome da nova branch     │ ← valida + checa duplicado
└─────────────────────────┘
      │
      ▼
  git checkout -b <nome>
  (restaura stash se houver)
      │
      ▼
┌─────────────────────────┐
│ Tem mudanças?           │ → não? sai com mensagem
└─────────────────────────┘
      │
      ▼
  mostra `git status` + confirma
      │
      ▼
  escolhe tipo semântico
      │
      ▼
  digita a mensagem
      │
      ▼
  git add . + git commit + git push -u
      │
      ▼
  🎉 mostra URL do Pull Request
```

## Licença

MIT — use à vontade. 🍌
