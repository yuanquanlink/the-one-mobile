import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const root = path.resolve(import.meta.dirname, '..');
const failures = [];
const notes = [];

function requireFile(relativePath) {
  const absolutePath = path.join(root, relativePath);
  if (!fs.existsSync(absolutePath)) {
    failures.push(`Missing required file: ${relativePath}`);
  }
  return absolutePath;
}

function walk(directory) {
  const result = [];
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    if (['.git', '.tmp', 'node_modules', 'dist', 'build', 'oh_modules'].includes(entry.name)) continue;
    const fullPath = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      result.push(...walk(fullPath));
    } else {
      result.push(fullPath);
    }
  }
  return result;
}

const required = [
  'AppScope/app.json5',
  'build-profile.json5',
  'hvigor/hvigor-config.json5',
  'entry/src/main/module.json5',
  'entry/src/main/ets/pages/Index.ets',
  'entry/src/main/ets/pages/DashboardPage.ets',
  'entry/src/main/ets/pages/CapturePage.ets',
  'entry/src/main/ets/pages/InboxPage.ets',
  'entry/src/main/ets/pages/InboxDetailPage.ets',
  'entry/src/main/ets/pages/CodexTasksPage.ets',
  'entry/src/main/ets/pages/CodexTaskCreatePage.ets',
  'entry/src/main/ets/pages/CodexTaskDetailPage.ets',
  'entry/src/main/ets/pages/SettingsPage.ets',
  'entry/src/main/ets/pages/BrainPage.ets',
  'entry/src/main/ets/repository/InboxRepository.ets',
  'entry/src/main/ets/repository/TaskRepository.ets',
  'entry/src/main/ets/services/BridgeClient.ets',
  'entry/skills/the-one-local-control/SKILL.md',
  'entry/skills/the-one-local-control/scripts/TheOneSkill.ets',
  'entry/src/main/ets/storage/StorageMigration.ets',
  'tools/preflight.ps1',
  'tools/build.ps1',
  'tools/lint.ps1',
  'tools/check-bridge.ps1',
  'code-linter.json5',
  'bridge/protocol.json',
  'README.md',
  'HANDOFF.md',
  'STATUS.md',
  'CHANGELOG.md',
  'USER_ACTION_REQUIRED.md',
  'THE_ONE_FINAL_ACCEPTANCE.md'
];
required.forEach(requireFile);

const sourceRoot = path.join(root, 'entry', 'src', 'main', 'ets');
if (fs.existsSync(sourceRoot)) {
  const skillRoot = path.join(root, 'entry', 'skills');
  const etsFiles = walk(sourceRoot).filter((file) => file.endsWith('.ets'));
  if (fs.existsSync(skillRoot)) {
    etsFiles.push(...walk(skillRoot).filter((file) => file.endsWith('.ets')));
  }
  notes.push(`${etsFiles.length} ArkTS source files`);

  for (const file of etsFiles) {
    const source = fs.readFileSync(file, 'utf8');
    const importPattern = /from\s+['"](\.[^'"]+)['"]/g;
    let match;
    while ((match = importPattern.exec(source)) !== null) {
      const base = path.resolve(path.dirname(file), match[1]);
      const candidates = [base, `${base}.ets`, path.join(base, 'index.ets')];
      if (!candidates.some((candidate) => fs.existsSync(candidate))) {
        failures.push(`Broken relative import in ${path.relative(root, file)}: ${match[1]}`);
      }
    }
    const relative = path.relative(root, file);
    if (/(?:replace|match|search|split)\(\s*\//u.test(source) || /!\s*\/[^/\n]+\/\.test/u.test(source)) {
      failures.push(`ArkTS RegExp literal is not supported: ${relative}`);
    }
    if (/JSON\.stringify\(\s*\{/u.test(source)) {
      failures.push(`Untyped object literal passed to JSON.stringify: ${relative}`);
    }
    if (/constructor\s*\(\s*(?:public|private|protected|readonly)\b/u.test(source)) {
      failures.push(`TypeScript constructor parameter property is not ArkTS-safe: ${relative}`);
    }
    if (/:\s*(?:any|unknown)\b/u.test(source)) {
      failures.push(`ArkTS any/unknown type is not allowed: ${relative}`);
    }
  }

  const combined = etsFiles.map((file) => fs.readFileSync(file, 'utf8')).join('\n');
  for (const token of ['content', 'createdAt', 'updatedAt', 'type', 'status', 'tags', 'syncStatus']) {
    if (!combined.includes(token)) failures.push(`Inbox model field not found: ${token}`);
  }
  for (const token of ['title', 'description', 'pending', 'sent', 'done', 'failed']) {
    if (!combined.includes(token)) failures.push(`Codex task contract token not found: ${token}`);
  }
  for (const route of ['capture', 'inbox', 'inbox_detail', 'codex_tasks', 'codex_task_create', 'codex_task_detail', 'settings', 'brain']) {
    if (!combined.includes(`'${route}'`)) failures.push(`Route not declared: ${route}`);
  }
  if (!combined.includes("from '@kit.ArkData'")) failures.push('ArkData import is missing');
  if (!combined.includes('await store.flush()')) failures.push('Durable Preferences flush is missing');
  const indexSource = fs.readFileSync(path.join(root, 'entry/src/main/ets/pages/Index.ets'), 'utf8');
  const isDirectRootFallback = indexSource.includes('DIRECT_ROOT_DASHBOARD_FALLBACK');
  if (!combined.includes('Navigation(this.pathStack)') && !isDirectRootFallback) {
    failures.push('Navigation + NavPathStack root is missing');
  }
  if (!combined.includes('AlertDialog.show')) failures.push('Inbox delete confirmation is missing');
  if (!combined.includes("from '@kit.NetworkKit'")) failures.push('Network Kit Bridge transport is missing');
  if (!combined.includes('StorageMigration')) failures.push('Storage migration layer is missing');
  if (!combined.includes('removeTestData')) failures.push('Scoped test-data cleanup is missing');
}

const skillScriptPath = requireFile('entry/skills/the-one-local-control/scripts/TheOneSkill.ets');
const skillContractPath = requireFile('entry/skills/the-one-local-control/SKILL.md');
const modulePath = requireFile('entry/src/main/module.json5');
if (fs.existsSync(skillScriptPath) && fs.existsSync(skillContractPath) && fs.existsSync(modulePath)) {
  const script = fs.readFileSync(skillScriptPath, 'utf8');
  const contract = fs.readFileSync(skillContractPath, 'utf8');
  const moduleSource = fs.readFileSync(modulePath, 'utf8');
  for (const name of ['save_to_brain', 'create_codex_task']) {
    if (!script.includes(`async ${name}(`)) failures.push(`Skill script function missing: ${name}`);
    if (!contract.includes(`functionName '${name}'`)) failures.push(`Skill contract function missing: ${name}`);
  }
  if (!script.includes('completeArkTSScriptInApp')) failures.push('Skill result reporting API is missing');
  if (!moduleSource.includes('"skillProfiles"')) failures.push('module.json5 skillProfiles is missing');
  if (!moduleSource.includes('"the-one-local-control"')) failures.push('Skill profile name mismatch');
}

const allFiles = walk(root).filter((file) => !file.includes(`${path.sep}.git${path.sep}`));
const textFiles = allFiles.filter((file) => /\.(ets|ts|json5)$/i.test(file) &&
  !file.includes(`${path.sep}tools${path.sep}`));
const allText = textFiles.map((file) => fs.readFileSync(file, 'utf8')).join('\n');
for (const banned of ['android.permission', 'FlutterActivity', 'extends Activity', 'JavaAbility']) {
  if (allText.includes(banned)) failures.push(`Forbidden legacy/Android technology detected: ${banned}`);
}

const buildProfilePath = requireFile('build-profile.json5');
if (fs.existsSync(buildProfilePath)) {
  const profile = fs.readFileSync(buildProfilePath, 'utf8');
  const requiredSettings = [
    ['compileSdkVersion', '26.0.0'],
    ['targetSdkVersion', '26.0.0'],
    ['compatibleSdkVersion', '26.0.0'],
    ['runtimeOS', 'HarmonyOS']
  ];
  for (const [key, value] of requiredSettings) {
    // JSON5 permits bare or quoted keys and single- or double-quoted values.
    // DevEco CLI writes the valid bare-key/single-quote form.
    const escapedValue = value.replaceAll('.', '\\.');
    const settingPattern = new RegExp(`(?:["']?${key}["']?)\\s*:\\s*["']${escapedValue}["']`);
    if (!settingPattern.test(profile)) {
      failures.push(`Build profile setting missing: ${key}: ${value}`);
    }
  }
}

const linterConfigPath = requireFile('code-linter.json5');
if (fs.existsSync(linterConfigPath)) {
  const config = fs.readFileSync(linterConfigPath, 'utf8');
  for (const ruleSet of [
    'plugin:@typescript-eslint/recommended',
    'plugin:@performance/recommended',
    'plugin:@hw-stylistic/recommended',
    'plugin:@security/recommended'
  ]) {
    if (!config.includes(ruleSet)) failures.push(`Code Linter ruleset missing: ${ruleSet}`);
  }
}

if (failures.length > 0) {
  console.error('PROJECT_VALIDATION_FAILED');
  failures.forEach((failure) => console.error(`- ${failure}`));
  process.exitCode = 1;
} else {
  console.log('PROJECT_VALIDATION_OK');
  notes.forEach((note) => console.log(`- ${note}`));
  console.log('- Required V1.0 pages, data contracts, routes, repositories and Bridge transport found');
  console.log('- Relative ArkTS imports resolve to local files');
  console.log('- API 26 HarmonyOS build profile found');
}
