#!/usr/bin/env node
// =============================================================================
// banana-push 🍌
// Automatiza o fluxo de envio para GitHub seguindo o modelo:
//   main (produção) ← develop (integração) ← feature/* (trabalho)
//
// Zero dependências externas — usa apenas Node stdlib.
// =============================================================================

const { spawn, spawnSync } = require('node:child_process');
const readline = require('node:readline');
const path = require('node:path');
const fs = require('node:fs');

// -----------------------------------------------------------------------------
// Cores ANSI
// -----------------------------------------------------------------------------
const c = {
  reset:  '\x1b[0m',  bold:   '\x1b[1m',  dim:    '\x1b[2m',
  red:    '\x1b[31m', green:  '\x1b[32m', yellow: '\x1b[33m',
  blue:   '\x1b[34m', cyan:   '\x1b[36m', gray:   '\x1b[90m',
};

// -----------------------------------------------------------------------------
// Config (customizável via package.json → "bananaPush": { ... })
// -----------------------------------------------------------------------------
const DEFAULT_CONFIG = {
  baseBranch: 'develop',
  productionBranch: 'main',
  allowedTypes: [
    { key: 'feat',     desc: 'nova funcionalidade' },
    { key: 'fix',      desc: 'correção de erro' },
    { key: 'refactor', desc: 'melhoria no código sem alterar comportamento' },
    { key: 'style',    desc: 'alteração visual ou de formatação' },
    { key: 'docs',     desc: 'alteração em documentação' },
    { key: 'chore',    desc: 'ajustes internos, configurações ou tarefas gerais' },
    { key: 'test',     desc: 'criação ou ajuste de testes' },
    { key: 'perf',     desc: 'melhoria de performance' },
    { key: 'build',    desc: 'ajustes em build, dependências ou ambiente' },
    { key: 'ci',       desc: 'ajustes em pipeline ou integração contínua' },
  ],
};

function loadConfig() {
  const pkgPath = path.join(process.cwd(), 'package.json');
  if (!fs.existsSync(pkgPath)) return DEFAULT_CONFIG;
  try {
    const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
    return { ...DEFAULT_CONFIG, ...(pkg.bananaPush || {}) };
  } catch {
    return DEFAULT_CONFIG;
  }
}

// -----------------------------------------------------------------------------
// Helpers de git
// -----------------------------------------------------------------------------
function git(args) {
  return spawnSync('git', args, { encoding: 'utf8' });
}

function gitInherit(args) {
  return new Promise((resolve, reject) => {
    const p = spawn('git', args, { stdio: 'inherit' });
    p.on('close', code => code === 0 ? resolve() : reject(new Error(`git ${args.join(' ')} → exit ${code}`)));
    p.on('error', reject);
  });
}

const isGitRepo       = ()       => git(['rev-parse', '--is-inside-work-tree']).status === 0;
const isClean         = ()       => git(['status', '--porcelain']).stdout.trim() === '';
const currentBranch   = ()       => git(['rev-parse', '--abbrev-ref', 'HEAD']).stdout.trim();
const hasRemote       = (n='origin') => git(['remote', 'get-url', n]).status === 0;
const remoteUrl       = ()       => git(['remote', 'get-url', 'origin']).stdout.trim();
const branchLocal     = name     => git(['rev-parse', '--verify', '--quiet', `refs/heads/${name}`]).status === 0;
const branchRemote    = name     => {
  const r = git(['ls-remote', '--heads', 'origin', name]);
  return r.status === 0 && r.stdout.trim() !== '';
};

// Lista os arquivos *modificados/deletados* do stash mais recente (não inclui untracked).
// Usado pra detectar conflito "deleted by us" antes de fazer pop.
function stashTrackedFiles(ref = 'stash@{0}') {
  const r = git(['stash', 'show', '--name-only', ref]);
  if (r.status !== 0) return [];
  return r.stdout.trim().split('\n').filter(Boolean);
}

// Filtra a lista, retornando só arquivos que NÃO existem em HEAD.
// Quando algum desses arquivos está como modificado no stash, o pop dará
// conflito "deleted by us" (o stash quer modificar, mas não há arquivo aqui).
function filesMissingInHead(files) {
  return files.filter(f => git(['cat-file', '-e', `HEAD:${f}`]).status !== 0);
}

// Lista branches (locais e remotas) que contêm TODOS os arquivos passados.
// Usado pra sugerir alternativas ao usuário quando a base não tem os arquivos.
function branchesContainingAll(files) {
  if (files.length === 0) return [];
  const refs = git(['for-each-ref', '--format=%(refname:short)', 'refs/heads/', 'refs/remotes/']);
  if (refs.status !== 0) return [];
  return refs.stdout.trim().split('\n')
    .filter(Boolean)
    .filter(ref => !ref.endsWith('/HEAD')) // ignora origin/HEAD
    .filter(ref => files.every(f => {
      const r = git(['ls-tree', ref, '--', f]);
      return r.status === 0 && r.stdout.trim() !== '';
    }));
}

function parseGitHubRepo(url) {
  // ssh: git@github.com:user/repo.git  |  https: https://github.com/user/repo(.git)?
  const m = url.match(/github\.com[:/]([^/]+)\/([^/.]+?)(?:\.git)?$/);
  return m ? `${m[1]}/${m[2]}` : null;
}

// -----------------------------------------------------------------------------
// Prompts (readline nativo)
// -----------------------------------------------------------------------------
const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

function ask(question) {
  return new Promise(resolve => rl.question(question, ans => resolve(ans.trim())));
}

async function askYesNo(question, defaultYes = true) {
  const hint = defaultYes ? 'S/n' : 's/N';
  const ans = (await ask(`${question} (${hint}) `)).toLowerCase();
  if (!ans) return defaultYes;
  return ans.startsWith('s') || ans.startsWith('y');
}

async function askChoice(question, options) {
  console.log(`\n${c.cyan}${question}${c.reset}`);
  // descrição pode ter múltiplas linhas (separadas por \n); demais linhas
  // ficam alinhadas embaixo da primeira pra ficar bonitinho.
  const indent = '      ' + ' '.repeat(10) + ' '; // "  NN) " (6) + key padded (10) + " "
  options.forEach((opt, i) => {
    const num = String(i + 1).padStart(2);
    const lines = opt.desc.split('\n');
    console.log(`  ${c.bold}${num}${c.reset}) ${c.green}${opt.key.padEnd(10)}${c.reset} ${c.dim}${lines[0]}${c.reset}`);
    for (let j = 1; j < lines.length; j++) {
      console.log(`${indent}${c.dim}${lines[j]}${c.reset}`);
    }
  });
  while (true) {
    const ans = await ask(`\n  → escolha (1-${options.length}): `);
    const n = parseInt(ans, 10);
    if (n >= 1 && n <= options.length) return options[n - 1];
    console.log(`  ${c.red}✗ Opção inválida.${c.reset}`);
  }
}

// -----------------------------------------------------------------------------
// Mensagens
// -----------------------------------------------------------------------------
const step    = msg => console.log(`\n${c.blue}→${c.reset} ${c.bold}${msg}${c.reset}`);
const ok      = msg => console.log(`  ${c.green}✓${c.reset} ${msg}`);
const warn    = msg => console.log(`  ${c.yellow}⚠${c.reset} ${msg}`);
const failMsg = msg => console.log(`  ${c.red}✗${c.reset} ${msg}`);

// Rede de segurança: se o script criou um stash automático e algo der errado
// depois disso, tentamos restaurar antes de sair pra você não perder mudanças.
let pendingStashRestore = false;

function attemptStashRestore() {
  if (!pendingStashRestore) return;
  pendingStashRestore = false; // evita loop se a restauração também falhar

  // Confere se ainda existe o nosso stash no topo da pilha
  const list = git(['stash', 'list']);
  if (list.status !== 0 || !list.stdout.includes('banana-push:auto')) return;

  console.log(`\n${c.yellow}⚠ Restaurando stash automático pra preservar suas mudanças...${c.reset}`);
  const pop = git(['stash', 'pop']);
  if (pop.status === 0) {
    console.log(`  ${c.green}✓${c.reset} Stash restaurado. Suas mudanças estão de volta no working tree.`);
  } else {
    console.log(`  ${c.red}✗${c.reset} Não foi possível restaurar automaticamente. Suas mudanças estão seguras em:`);
    console.log(`     ${c.cyan}git stash list${c.reset}  → procure por "banana-push:auto"`);
    console.log(`     Restaure manualmente com: ${c.cyan}git stash pop${c.reset}`);
  }
}

function exitWithError(msg, code = 1) {
  console.log(`\n${c.red}✗ ${msg}${c.reset}\n`);
  attemptStashRestore();
  rl.close();
  process.exit(code);
}

// -----------------------------------------------------------------------------
// Validação de nome de branch
// -----------------------------------------------------------------------------
const BRANCH_REGEX = /^[a-z0-9][a-z0-9._/-]*$/;
function validateBranchName(name) {
  if (!name)                   return 'Nome não pode ser vazio.';
  if (name.length > 80)        return 'Nome muito longo (max 80 chars).';
  if (!BRANCH_REGEX.test(name)) return 'Use apenas a-z, 0-9, "-", "_", "/", "." e começando com letra/número.';
  if (name.includes('..'))     return 'Não pode conter "..".';
  if (name.endsWith('.lock'))  return 'Não pode terminar com ".lock".';
  if (name.endsWith('/') || name.endsWith('-')) return 'Não pode terminar com "/" ou "-".';
  return null;
}

// -----------------------------------------------------------------------------
// Helpers de auto-fix (resolvem pré-requisitos faltantes interativamente)
// -----------------------------------------------------------------------------
async function ensureGitRepo() {
  if (isGitRepo()) {
    ok('Repositório git OK');
    return;
  }
  warn('Este diretório não é um repositório git.');
  if (!await askYesNo('Quer que eu inicialize agora com "git init"?')) {
    exitWithError('Repositório git é necessário para continuar.');
  }
  const init = git(['init']);
  if (init.status !== 0) exitWithError(`Falha em "git init":\n${init.stderr}`);
  ok('git init executado');
}

async function ensureRemote() {
  if (hasRemote('origin')) {
    ok(`Remote: ${remoteUrl()}`);
    return;
  }
  warn('Remote "origin" não está configurado.');
  if (!await askYesNo('Quer que eu te ajude a configurar agora?')) {
    exitWithError('Remote "origin" é necessário para continuar.');
  }
  let url;
  while (true) {
    url = await ask('  → URL do repositório (ex: https://github.com/usuario/repo.git): ');
    if (!url) { failMsg('URL não pode ser vazia.'); continue; }
    if (!url.includes('://') && !url.startsWith('git@')) {
      failMsg('URL não parece válida. Use https:// ou git@.');
      continue;
    }
    break;
  }
  const add = git(['remote', 'add', 'origin', url]);
  if (add.status !== 0) exitWithError(`Falha ao adicionar remote:\n${add.stderr}`);
  ok(`Remote "origin" adicionado: ${url}`);
}

async function ensureBaseBranch(baseBranch, productionBranch) {
  if (branchLocal(baseBranch)) {
    ok(`Branch base "${baseBranch}" encontrada (local)`);
    return;
  }

  if (branchRemote(baseBranch)) {
    warn(`Branch "${baseBranch}" existe no remoto mas não localmente.`);
    if (!await askYesNo(`Quer que eu faça checkout de "${baseBranch}" do remoto agora?`)) {
      exitWithError(`Branch base "${baseBranch}" é necessária para continuar.`);
    }
    const fetchR = git(['fetch', 'origin', baseBranch]);
    if (fetchR.status !== 0) {
      exitWithError(`Falha ao buscar "${baseBranch}" do remoto:\n${fetchR.stderr}`);
    }
    const coR = git(['checkout', '-b', baseBranch, `origin/${baseBranch}`]);
    if (coR.status !== 0) {
      exitWithError(`Falha ao criar branch local rastreando o remoto:\n${coR.stderr}`);
    }
    ok(`Branch "${baseBranch}" criada localmente rastreando origin/${baseBranch}`);
    return;
  }

  warn(`Branch base "${baseBranch}" não existe (nem local nem remoto).`);
  if (!await askYesNo(`Quer que eu te ajude a criar "${baseBranch}" agora?`)) {
    exitWithError(`Branch base "${baseBranch}" é necessária para continuar.`);
  }

  // Decide a origem da nova branch base
  let sourceRef;
  let sourceLabel;
  if (branchLocal(productionBranch)) {
    sourceRef = productionBranch;
    sourceLabel = `${productionBranch} (local)`;
  } else if (branchRemote(productionBranch)) {
    step(`Buscando "${productionBranch}" do remoto`);
    const fetchR = git(['fetch', 'origin', productionBranch]);
    if (fetchR.status !== 0) {
      exitWithError(`Falha ao buscar "${productionBranch}":\n${fetchR.stderr}`);
    }
    sourceRef = `origin/${productionBranch}`;
    sourceLabel = `origin/${productionBranch}`;
  } else {
    const head = git(['rev-parse', '--verify', '--quiet', 'HEAD']);
    if (head.status !== 0) {
      exitWithError(
        `Repositório ainda não tem nenhum commit. Faça um commit inicial e tente de novo:\n` +
        `  git add . && git commit -m "chore: initial commit"`
      );
    }
    sourceRef = 'HEAD';
    sourceLabel = `branch atual ("${currentBranch()}")`;
    warn(`Nem "${productionBranch}" existe. Vou criar "${baseBranch}" a partir da ${sourceLabel}.`);
    if (!await askYesNo('Continuar?')) exitWithError('Abortado pelo usuário.', 0);
  }

  step(`Criando "${baseBranch}" a partir de ${sourceLabel}`);
  const cb = git(['checkout', '-b', baseBranch, sourceRef]);
  if (cb.status !== 0) exitWithError(`Falha ao criar "${baseBranch}":\n${cb.stderr}`);
  ok(`Branch "${baseBranch}" criada`);

  if (await askYesNo(`Publicar "${baseBranch}" no remoto agora (git push -u origin ${baseBranch})?`)) {
    try {
      await gitInherit(['push', '-u', 'origin', baseBranch]);
      ok(`"${baseBranch}" publicada no remoto`);
    } catch {
      warn(`Falha ao publicar. Você pode tentar depois: git push -u origin ${baseBranch}`);
    }
  } else {
    warn(`"${baseBranch}" só existe localmente por enquanto.`);
  }
}

// =============================================================================
// FLUXO PRINCIPAL
// =============================================================================
async function main() {
  console.log(`${c.bold}${c.yellow}🍌 banana-push${c.reset} ${c.dim}— fluxo de envio para GitHub${c.reset}`);

  const config = loadConfig();
  const baseBranch = config.baseBranch;

  // ---------------------------------------------------------------------------
  // 1. Pré-flight checks (com auto-fix interativo)
  //    Se algo estiver faltando, oferece criar/configurar e segue o fluxo.
  // ---------------------------------------------------------------------------
  step('Verificando ambiente');
  await ensureGitRepo();

  // Sempre operar a partir da raiz do repositório.
  // Sem isso, "git add ." só pega a pasta atual (ex: rodar via "npm run push"
  // de uma subpasta deixava arquivos do resto do repo de fora do commit).
  const repoRoot = git(['rev-parse', '--show-toplevel']).stdout.trim();
  if (repoRoot && path.resolve(repoRoot) !== path.resolve(process.cwd())) {
    process.chdir(repoRoot);
    ok(`Trabalhando da raiz do repositório: ${repoRoot}`);
  }

  await ensureRemote();
  await ensureBaseBranch(baseBranch, config.productionBranch);

  // ---------------------------------------------------------------------------
  // 2. Working tree sujo? → oferecer opções
  // ---------------------------------------------------------------------------
  const dirty = !isClean();
  let stashed = false;

  if (dirty) {
    warn('Você tem mudanças não commitadas:');
    console.log(c.dim + git(['status', '--short']).stdout + c.reset);

    console.log(`\n${c.dim}  Pra criar a nova feature branch sem perder essas mudanças,${c.reset}`);
    console.log(`${c.dim}  preciso decidir o que fazer com elas. Escolha uma opção:${c.reset}`);

    const choice = await askChoice('Como prosseguir?', [
      {
        key: 'carregar',
        desc: 'Trazer suas mudanças pra nova branch como elas estão agora.\n'
            + `Mais simples e rápido — recomendado pra maioria dos casos.\n`
            + `⚠ A base (${baseBranch}) NÃO será atualizada do remoto antes.`
      },
      {
        key: 'stash',
        desc: `Guardar as mudanças temporariamente, atualizar ${baseBranch} do remoto,\n`
            + 'criar a nova branch a partir dela e devolver as mudanças nessa nova branch.\n'
            + `Use quando ${baseBranch} pode ter recebido commits novos no GitHub.`
      },
      {
        key: 'abortar',
        desc: 'Sair do script sem mexer em nada.\n'
            + 'Use se quiser primeiro commitar, descartar (git restore) ou organizar\n'
            + 'essas mudanças à mão antes de rodar de novo.'
      },
    ]);

    if (choice.key === 'abortar') exitWithError('Abortado pelo usuário.', 0);

    if (choice.key === 'stash') {
      step('Fazendo stash');
      const sr = git(['stash', 'push', '-u', '-m', 'banana-push:auto']);
      if (sr.status !== 0) exitWithError(`Falha ao fazer stash:\n${sr.stderr}`);
      stashed = true;
      pendingStashRestore = true; // se algo der errado daqui pra frente, restaura
      ok('Stash criado');
    }
  } else {
    ok('Working tree limpo');
  }

  // ---------------------------------------------------------------------------
  // 3. Atualiza branch base
  // ---------------------------------------------------------------------------
  step(`Atualizando ${baseBranch}`);

  // Se ainda há mudanças não-stashed, o checkout pode falhar — só tentamos se for seguro
  const canSwitch = isClean();
  if (canSwitch && currentBranch() !== baseBranch) {
    const co = git(['checkout', baseBranch]);
    if (co.status !== 0) exitWithError(`Falha ao mudar pra ${baseBranch}:\n${co.stderr}`);
    ok(`Mudou pra ${baseBranch}`);
  } else if (!canSwitch) {
    warn(`Não posso mudar pra ${baseBranch} (mudanças locais). Pull será na branch atual.`);
  }

  if (branchRemote(baseBranch)) {
    try {
      await gitInherit(['pull', 'origin', baseBranch]);
      ok(`${baseBranch} atualizado`);
    } catch {
      exitWithError(`Falha no pull de ${baseBranch}. Resolva conflitos manualmente.`);
    }
  } else {
    warn(`"${baseBranch}" ainda não existe no remoto — pulando pull.`);
  }

  // ---------------------------------------------------------------------------
  // 4. Nome da nova branch + validação + checagem local/remoto
  // ---------------------------------------------------------------------------
  step('Criando nova branch');
  let newBranch;
  while (true) {
    newBranch = await ask(`  → nome da nova branch: `);
    const err = validateBranchName(newBranch);
    if (err)                     { failMsg(err); continue; }
    if (branchLocal(newBranch))  { failMsg(`Branch "${newBranch}" já existe localmente.`); continue; }
    if (branchRemote(newBranch)) { failMsg(`Branch "${newBranch}" já existe no remoto.`); continue; }
    break;
  }

  const cb = git(['checkout', '-b', newBranch]);
  if (cb.status !== 0) exitWithError(`Falha ao criar branch:\n${cb.stderr}`);
  ok(`Branch criada: ${c.bold}${newBranch}${c.reset}`);

  // ---------------------------------------------------------------------------
  // 5. Restaura stash se aplicável
  // ---------------------------------------------------------------------------
  if (stashed) {
    // ---------- 5a. Detecção preventiva de conflito "deleted by us" ----------
    // O stash pode modificar arquivos que existem em outras branches mas
    // NÃO existem nesta nova branch (porque a base ainda não foi mergeada
    // com essas mudanças). Sem essa checagem, o pop dá um conflito críptico.
    const stashFiles = stashTrackedFiles();
    const missing = filesMissingInHead(stashFiles);

    if (missing.length > 0) {
      console.log(`\n  ${c.yellow}⚠ Atenção:${c.reset} o stash modifica ${c.bold}${missing.length}${c.reset} arquivo(s)`);
      console.log(`    que ${c.bold}NÃO existem${c.reset} na branch nova "${c.bold}${newBranch}${c.reset}":`);
      missing.forEach(f => console.log(`     ${c.dim}•${c.reset} ${f}`));
      console.log(`\n  ${c.dim}Por que isso acontece?${c.reset}`);
      console.log(`  ${c.dim}Esses arquivos existem em outra branch que ainda não foi mergeada${c.reset}`);
      console.log(`  ${c.dim}em "${baseBranch}" — então sua nova branch (vinda de "${baseBranch}") não tem eles.${c.reset}`);
      console.log(`  ${c.dim}Se eu fizer o pop assim, o git vai gerar conflito "deleted by us".${c.reset}`);

      const candidates = branchesContainingAll(missing);
      if (candidates.length > 0) {
        console.log(`\n  ${c.dim}Branches que JÁ têm todos esses arquivos:${c.reset}`);
        candidates.forEach(b => console.log(`     ${c.cyan}${b}${c.reset}`));
      }

      const opts = [];
      if (candidates.length > 0) {
        opts.push({
          key: 'rebase',
          desc: `Recriar "${newBranch}" a partir de uma branch alternativa que tenha esses arquivos\n`
              + '(vou listar as opções pra você escolher).'
        });
      }
      opts.push({
        key: 'forçar',
        desc: 'Tentar o pop assim mesmo. Vai gerar conflito que vc resolve no editor.\n'
            + 'Útil se você sabe o que está fazendo.'
      });
      opts.push({
        key: 'sair',
        desc: 'Sair do script preservando o stash. Suas mudanças continuam em\n'
            + '"git stash list" (banana-push:auto). A branch nova permanece criada.'
      });

      const action = await askChoice('Como prosseguir?', opts);

      if (action.key === 'rebase') {
        const pick = await askChoice(
          'A partir de qual branch recriar?',
          candidates.map(b => ({ key: b, desc: 'usar esta branch como nova base' }))
        );
        step(`Recriando "${newBranch}" a partir de "${pick.key}"`);
        // Voltar pra base original pra poder deletar a branch atual
        const co = git(['checkout', baseBranch]);
        if (co.status !== 0) exitWithError(`Falha ao voltar pra "${baseBranch}":\n${co.stderr}`);
        const del = git(['branch', '-D', newBranch]);
        if (del.status !== 0) exitWithError(`Falha ao apagar branch antiga:\n${del.stderr}`);
        const recb = git(['checkout', '-b', newBranch, pick.key]);
        if (recb.status !== 0) exitWithError(`Falha ao recriar branch:\n${recb.stderr}`);
        ok(`Branch "${newBranch}" recriada a partir de "${pick.key}"`);
      } else if (action.key === 'sair') {
        warn('Saindo conforme solicitado. Stash preservado.');
        console.log(`\n  ${c.dim}Pra restaurar manualmente quando quiser:${c.reset}`);
        console.log(`     ${c.cyan}git stash pop${c.reset}`);
        pendingStashRestore = false; // não tenta de novo
        rl.close();
        process.exit(0);
      }
      // 'forçar' cai direto no pop abaixo
    }

    // ---------- 5b. Pop propriamente dito ----------
    step('Restaurando stash na nova branch');
    const pop = git(['stash', 'pop']);
    if (pop.status !== 0) {
      // Pop falhou — provavelmente conflito. Mostrar mensagem clara.
      console.log(`\n  ${c.red}✗ Conflito ao restaurar o stash.${c.reset}`);
      const status = git(['status', '--short']).stdout;
      console.log(`\n  ${c.dim}Estado atual do repositório:${c.reset}`);
      console.log(c.dim + status + c.reset);

      // Detectar tipo mais comum (deleted by us = "DU")
      if (/^DU |^UD /m.test(status) || /deleted by/.test(pop.stderr || '')) {
        console.log(`  ${c.yellow}Tipo de conflito: "deleted by us"${c.reset}`);
        console.log(`  O stash modificou um arquivo que esta branch não tem.`);
        console.log(`\n  ${c.bold}Como resolver:${c.reset}`);
        console.log(`     ${c.cyan}git rm <arquivo>${c.reset}                  → aceita a deleção (descarta a versão do stash)`);
        console.log(`     ${c.cyan}git checkout --theirs -- <arquivo>${c.reset} → mantém a versão do stash`);
        console.log(`     ${c.cyan}git stash drop${c.reset}                    → quando terminar, descarta o stash`);
      } else {
        console.log(`  ${c.bold}Como resolver:${c.reset} edite os arquivos em conflito e rode:`);
        console.log(`     ${c.cyan}git add <arquivos>${c.reset}`);
        console.log(`     ${c.cyan}git stash drop${c.reset}`);
      }
      pendingStashRestore = false; // stash continua na pilha; usuário resolve
      exitWithError('Resolva os conflitos manualmente conforme as instruções acima.');
    }
    pendingStashRestore = false;
    ok('Stash restaurado');
  }

  // ---------------------------------------------------------------------------
  // 6. Tem mudanças pra commitar?
  // ---------------------------------------------------------------------------
  if (isClean()) {
    warn('Não há mudanças para commitar.');
    console.log(`\n  Branch "${newBranch}" foi criada vazia. Pra apagar:`);
    console.log(`    ${c.dim}git checkout ${baseBranch} && git branch -D ${newBranch}${c.reset}\n`);
    rl.close();
    process.exit(0);
  }

  // ---------------------------------------------------------------------------
  // 7. Mostra status e confirma
  // ---------------------------------------------------------------------------
  step('Arquivos que entrarão no commit');
  console.log(git(['status', '--short']).stdout);
  if (!await askYesNo('Confirmar adição de todos esses arquivos?')) {
    exitWithError('Cancelado pelo usuário.', 0);
  }

  // ---------------------------------------------------------------------------
  // 8. Tipo semântico
  // ---------------------------------------------------------------------------
  const typeChoice = await askChoice('Tipo semântico do commit:', config.allowedTypes);

  // ---------------------------------------------------------------------------
  // 9. Mensagem do commit + validação
  // ---------------------------------------------------------------------------
  let msg;
  while (true) {
    msg = await ask(`\n  → mensagem do commit: `);
    if (!msg) { failMsg('Mensagem não pode ser vazia.'); continue; }
    const fullLength = typeChoice.key.length + 2 + msg.length;
    if (fullLength > 72) {
      warn(`Mensagem terá ${fullLength} chars (recomendado ≤ 72).`);
      if (!await askYesNo('Continuar mesmo assim?', false)) continue;
    }
    break;
  }

  // ---------------------------------------------------------------------------
  // 10. add + commit + push
  // ---------------------------------------------------------------------------
  step('git add -A (todo o repositório)');
  await gitInherit(['add', '-A']);

  step('git commit');
  const commitMsg = `${typeChoice.key}: ${msg}`;
  // spawnSync com array de args = sem shell, sem risco de injection
  const commit = spawnSync('git', ['commit', '-m', commitMsg], { stdio: 'inherit' });
  if (commit.status !== 0) {
    exitWithError('Commit falhou (pre-commit hook? lint?). Resolva e tente novamente.');
  }
  ok(`Commit: ${c.bold}${commitMsg}${c.reset}`);

  // Sanidade: depois do commit o working tree DEVE estar limpo.
  // Se sobrou algo, é sinal de bug ou hook que removeu coisas — avisa antes do push.
  if (!isClean()) {
    warn('Atenção: após o commit, ainda há mudanças não commitadas:');
    console.log(c.dim + git(['status', '--short']).stdout + c.reset);
    warn('Essas mudanças NÃO entrarão no push. Cancele com Ctrl+C se quiser revisar.');
    if (!await askYesNo('Continuar com o push mesmo assim?', false)) {
      exitWithError('Cancelado pelo usuário.', 0);
    }
  }

  step('git push -u origin');
  try {
    await gitInherit(['push', '-u', 'origin', newBranch]);
    ok('Push concluído');
  } catch {
    exitWithError('Push falhou. Veja a saída do git acima.');
  }

  // ---------------------------------------------------------------------------
  // 11. Resumo final + URL do Pull Request
  // ---------------------------------------------------------------------------
  const repo = parseGitHubRepo(remoteUrl());
  const prUrl = repo
    ? `https://github.com/${repo}/compare/${baseBranch}...${newBranch}?expand=1`
    : null;

  const bar = `${c.green}${'━'.repeat(60)}${c.reset}`;
  console.log(`\n${bar}`);
  console.log(`${c.bold}${c.green}🎉 Tudo certo!${c.reset}`);
  console.log(`${bar}\n`);
  console.log(`  ${c.dim}Branch:${c.reset}  ${c.bold}${newBranch}${c.reset}`);
  console.log(`  ${c.dim}Commit:${c.reset}  ${commitMsg}`);
  console.log(`  ${c.dim}Base:${c.reset}    ${baseBranch}`);
  if (prUrl) {
    console.log(`\n  ${c.yellow}📬 Abra o Pull Request:${c.reset}`);
    console.log(`     ${c.cyan}${prUrl}${c.reset}`);
  } else {
    console.log(`\n  ${c.yellow}Próximo passo:${c.reset} abra um Pull Request "${newBranch}" → "${baseBranch}"`);
  }
  console.log(`\n${bar}\n`);

  rl.close();
}

// -----------------------------------------------------------------------------
// Handlers globais
// -----------------------------------------------------------------------------
process.on('SIGINT', () => {
  console.log(`\n${c.yellow}⚠ Interrompido pelo usuário.${c.reset}\n`);
  attemptStashRestore();
  rl.close();
  process.exit(130);
});

main().catch(err => {
  console.error(`\n${c.red}✗ Erro inesperado:${c.reset}`, err.message);
  attemptStashRestore();
  rl.close();
  process.exit(1);
});
