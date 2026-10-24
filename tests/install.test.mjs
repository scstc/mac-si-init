import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, readdirSync, existsSync, symlinkSync, lstatSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const installer = join(root, 'scripts/install.sh');
const cli = join(root, 'cli.mjs');

function fixture(t) {
  const dir = mkdtempSync(join(tmpdir(), 'mac-si-test-'));
  t.after(() => rmSync(dir, { recursive: true, force: true }));
  const home = join(dir, 'user home');
  const bin = join(dir, 'bin');
  const systemBin = join(dir, 'system-bin');
  const state = join(dir, 'state');
  for (const path of [home, bin, systemBin, state]) mkdirSync(path);
  // 白名单不包含机器上已有的 node / fnm，才能覆盖真正的全新环境分支。
  for (const name of ['dirname', 'mkdir', 'mktemp', 'cat', 'cp', 'mv', 'rm', 'grep', 'cmp', 'date', 'touch', 'chmod', 'zsh']) {
    const found = spawnSync('/bin/sh', ['-c', 'command -v "$1"', 'lookup', name], { encoding: 'utf8' });
    assert.equal(found.status, 0, `缺少测试依赖 ${name}`);
    symlinkSync(found.stdout.trim(), join(systemBin, name));
  }
  function command(name, body) {
    writeFileSync(join(bin, name), `#!/bin/bash\nset -eu\n${body}\n`, { mode: 0o755 });
  }
  command('uname', 'if [ "$1" = -s ]; then echo "${TEST_OS:-Darwin}"; else echo arm64; fi');
  command('id', 'echo "${TEST_UID:-501}"');
  command('sysctl', 'echo "${TEST_ROSETTA:-0}"');
  command('xcode-select', `
if [ "$1" = --install ]; then echo clt-window >> "$TEST_STATE/events"; exit 0; fi
[ "\${TEST_NO_CLT:-0}" != 1 ]`);
  command('xcrun', 'exit 0');
  command('brew', `
printf 'brew %s\\n' "$*" >> "$TEST_STATE/events"
case "$1" in
  --prefix) printf '%s\\n' "$TEST_PREFIX" ;;
  shellenv) printf 'export HOMEBREW_PREFIX=%q\\n' "$TEST_PREFIX" ;;
  list) [ -f "$TEST_STATE/$2-$3" ] ;;
  install) touch "$TEST_STATE/$2-$3" ;;
  *) exit 1 ;;
esac`);
  command('fnm', `
printf 'fnm %s\\n' "$*" >> "$TEST_STATE/events"
case "$1" in
  env) printf 'export PATH=%q:$PATH\\n' "$TEST_STATE/node-bin" ;;
  install)
    mkdir -p "$TEST_STATE/node-bin"
    printf '#!/bin/sh\\necho v24.mock\\n' > "$TEST_STATE/node-bin/node"
    chmod +x "$TEST_STATE/node-bin/node"
    ;;
  *) echo fnm-mock ;;
esac`);
  command('git', `
if [ "$1" = clone ]; then
  for dest in "$@"; do :; done
  mkdir -p "$dest"
  echo 'function omz() { :; }' > "$dest/oh-my-zsh.sh"
  echo git-clone >> "$TEST_STATE/events"
else echo git-mock; fi`);
  // 模拟 macOS plutil 的 key path 读取，测试不需要真实 plist 或安装 GUI 应用。
  writeFileSync(join(bin, 'plutil'), `#!${process.execPath}
const { readFileSync } = require('node:fs');
try {
  const args = process.argv.slice(2);
  const key = args[args.indexOf('-extract') + 1];
  const value = key.split('.').reduce((value, part) => value[part], JSON.parse(readFileSync(args.at(-1), 'utf8')));
  if (value === undefined) process.exit(1);
  console.log(value);
} catch { process.exit(1); }
`, { mode: 0o755 });
  command('ditto', `
if [ "$1" = -x ]; then
  [ "\${TEST_CC_BAD_ARCHIVE:-0}" != 1 ] || exit 8
  mkdir -p "$4/CC Switch.app/Contents/MacOS"
  echo '{"CFBundleExecutable":"cc-switch"}' > "$4/CC Switch.app/Contents/Info.plist"
  printf '#!/bin/sh\\nexit 0\\n' > "$4/CC Switch.app/Contents/MacOS/cc-switch"
  chmod +x "$4/CC Switch.app/Contents/MacOS/cc-switch"
else
  mkdir -p "$2"
  [ "\${TEST_CC_COPY_FAIL:-0}" != 1 ] || exit 7
  cp -R "$1/." "$2"
fi`);
  command('curl', `
printf 'curl %s\\n' "$*" >> "$TEST_STATE/events"
url=''; output=''
while [ "$#" -gt 0 ]; do
  case "$1" in
    https:*) url="$1"; shift ;;
    -o) output="$2"; shift 2 ;;
    *) shift ;;
  esac
done
case "$url" in
  https://api.github.com/repos/farion1231/cc-switch/releases/latest)
    [ "\${TEST_CC_FAIL:-}" != metadata ] || exit 22
    if [ "\${TEST_CC_NO_ASSET:-0}" = 1 ]; then echo '{"assets":[]}' > "$output"; exit 0; fi
    echo '{"assets":[{"name":"Linux.zip"},{"name":"CC-Switch-vtest-macOS.zip","browser_download_url":"https://github.com/farion1231/cc-switch/releases/download/vtest/CC-Switch-vtest-macOS.zip"}]}' > "$output"
    exit 0 ;;
  https://github.com/farion1231/cc-switch/releases/download/*)
    [ "\${TEST_CC_FAIL:-}" != download ] || exit 22
    echo mock-archive > "$output"
    exit 0 ;;
esac
case "$url" in *claude.ai*) tool=claude ;; *chatgpt.com*) tool=codex ;; *) exit 2 ;; esac
if [ "\${TEST_CURL_FAIL:-}" = "$tool" ]; then
  echo 'touch "$TEST_STATE/should-never-run"' > "$output"
  exit 22
fi
if [ "\${TEST_INSTALL_FAIL:-}" = "$tool" ]; then echo 'exit 9' > "$output"; exit 0; fi
cat > "$output" <<EOF
echo installed-$tool-\\$* >> "\\$TEST_STATE/events"
mkdir -p "\\$HOME/.local/bin"
printf '#!/bin/sh\\necho $tool-mock\\n' > "\\$HOME/.local/bin/$tool"
chmod +x "\\$HOME/.local/bin/$tool"
EOF`);
  // 仅子进程使用临时用户目录和白名单 PATH，真实机器配置不参与测试。
  const env = {
    HOME: home, PATH: `${bin}:${systemBin}`, TMPDIR: dir,
    TEST_STATE: state, TEST_PREFIX: join(dir, 'brew prefix'),
    SHELL: '/bin/zsh', LANG: 'en_US.UTF-8',
  };
  function run(args = [], overrides = {}) {
    return spawnSync('/bin/bash', [installer, ...args], {
      env: { ...env, ...overrides }, encoding: 'utf8', cwd: dir,
    });
  }
  const events = () => existsSync(join(state, 'events')) ? readFileSync(join(state, 'events'), 'utf8') : '';
  return { dir, home, bin, state, env, run, command, events };
}

test('预览不执行外部安装，也不创建任何用户配置', (t) => {
  const f = fixture(t);
  const result = f.run(['--dry-run', '--only', 'all', '--with-obsidian'], { TEST_OS: 'Linux', TEST_UID: '0' });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /claude.ai\/install.sh/);
  assert.match(result.stdout, /chatgpt.com\/codex\/install.sh/);
  assert.match(result.stdout, /obsidian/);
  assert.equal(f.events(), '');
  assert.deepEqual(readdirSync(f.home), []);
});

test('参数错误失败且不修改用户目录', (t) => {
  const f = fixture(t);
  for (const args of [['--only'], ['--only', 'bad'], ['--no-such-option'], ['--only', 'ai', '--with-obsidian']]) {
    assert.equal(f.run(args).status, 1);
  }
  assert.deepEqual(readdirSync(f.home), []);
  assert.equal(f.events(), '');
});

test('真实安装拒绝非 Mac、root 和 Rosetta', (t) => {
  const f = fixture(t);
  for (const env of [{ TEST_OS: 'Linux' }, { TEST_UID: '0' }, { TEST_ROSETTA: '1' }]) {
    assert.equal(f.run(['--only', 'ai'], env).status, 1);
  }
  assert.equal(f.events(), '');
  assert.deepEqual(readdirSync(f.home), []);
});

test('缺少 CLT 时打开系统安装窗口并停止后续安装', (t) => {
  const f = fixture(t);
  const result = f.run(['--only', 'core'], { TEST_NO_CLT: '1' });
  assert.equal(result.status, 1);
  assert.equal(f.events(), 'clt-window\n');
  assert.deepEqual(readdirSync(f.home), []);
});

test('shell 模块保留符号链接和个人配置，备份准确，重跑不重复写入', (t) => {
  const f = fixture(t);
  const original = 'export MY_PERSONAL_SETTING=keep'; // 原文件故意没有结尾换行
  const linked = join(f.home, 'personal-zshrc');
  writeFileSync(linked, original);
  symlinkSync(linked, join(f.home, '.zshrc'));
  const first = f.run(['--only', 'shell']);
  assert.equal(first.status, 0, first.stderr);
  assert.ok(lstatSync(join(f.home, '.zshrc')).isSymbolicLink());
  const content = readFileSync(linked, 'utf8');
  assert.ok(content.startsWith(`${original}\n`));
  assert.equal(content.match(/# >>> mac-si-init: shell >>>/g).length, 1);
  const backups = readdirSync(f.home).filter((name) => name.startsWith('.zshrc.mac-si-init.'));
  assert.ok(backups.some((name) => readFileSync(join(f.home, name), 'utf8') === original));
  const files = readdirSync(f.home);
  const second = f.run(['--only', 'shell']);
  assert.equal(second.status, 0, second.stderr);
  assert.equal(readFileSync(linked, 'utf8'), content);
  assert.deepEqual(readdirSync(f.home), files);
  assert.equal(f.events().match(/git-clone/g).length, 1);
  const envSyntax = spawnSync('zsh', ['-n', join(f.home, '.mac-si-init/env.zsh')], { encoding: 'utf8' });
  assert.equal(envSyntax.status, 0, envSyntax.stderr);
});

test('支持含空格的 ZDOTDIR 和自定义 Oh My Zsh 路径', (t) => {
  const f = fixture(t);
  const zdot = join(f.home, 'zsh config');
  const customZsh = join(f.home, 'custom omz');
  const result = f.run(['--only', 'shell'], { ZDOTDIR: zdot, ZSH: customZsh });
  assert.equal(result.status, 0, result.stderr);
  assert.ok(existsSync(join(zdot, '.zshrc')));
  assert.ok(existsSync(join(zdot, '.zprofile')));
  assert.ok(existsSync(join(customZsh, 'oh-my-zsh.sh')));
  assert.equal(existsSync(join(f.home, '.zshrc')), false);
});

test('AI 模块直接运行官方安装器，Claude 指定 latest，不使用 brew cask 安装 AI', (t) => {
  const f = fixture(t);
  const result = f.run(['--only', 'ai']);
  assert.equal(result.status, 0, result.stderr);
  const events = f.events();
  assert.match(events, /installed-claude-latest/);
  assert.match(events, /installed-codex-/);
  assert.doesNotMatch(events, /brew install/);
  assert.ok(existsSync(join(f.home, '.local/bin/claude')));
  assert.ok(existsSync(join(f.home, '.local/bin/codex')));
  assert.equal(f.run(['--only', 'ai']).status, 0);
  assert.equal(f.events().match(/installed-claude-/g).length, 1);
});

test('下载失败不执行残留内容，也不继续装下一个工具', (t) => {
  const f = fixture(t);
  const result = f.run(['--only', 'ai'], { TEST_CURL_FAIL: 'claude' });
  assert.notEqual(result.status, 0);
  assert.equal(existsSync(join(f.state, 'should-never-run')), false);
  assert.doesNotMatch(f.events(), /chatgpt.com/);
  assert.equal(readdirSync(f.dir).some((name) => /^mac-si-init\./.test(name)), false);
});

test('安装器自身失败的退出码向上传递', (t) => {
  const f = fixture(t);
  const result = f.run(['--only', 'ai'], { TEST_INSTALL_FAIL: 'claude' });
  assert.equal(result.status, 9);
  assert.doesNotMatch(f.events(), /chatgpt.com/);
});

test('已有 CLI 不触发下载安装或自动迁移', (t) => {
  const f = fixture(t);
  f.command('claude', 'echo existing-claude');
  f.command('codex', 'echo existing-codex');
  const result = f.run(['--only', 'ai']);
  assert.equal(result.status, 0, result.stderr);
  assert.doesNotMatch(f.events(), /curl/);
  assert.match(result.stdout, /保留已有 claude/);
});

test('全新 core 环境使用 fnm LTS 并写入初始化，重跑不重复追加', (t) => {
  const f = fixture(t);
  const first = f.run(['--only', 'core']);
  assert.equal(first.status, 0, first.stderr);
  assert.match(f.events(), /fnm install --lts/);
  assert.ok(existsSync(join(f.state, 'node-bin/node')));
  const config = readFileSync(join(f.home, '.zshrc'), 'utf8');
  assert.match(config, /fnm env --use-on-cd --shell zsh/);
  assert.equal(f.run(['--only', 'core']).status, 0);
  assert.equal(readFileSync(join(f.home, '.zshrc'), 'utf8'), config);
});

test('已有 Node 时保留原版本管理器初始化', (t) => {
  const f = fixture(t);
  f.command('node', 'echo existing-node');
  writeFileSync(join(f.home, '.zshrc'), '# existing mise or nvm configuration\n');
  const result = f.run(['--only', 'core']);
  assert.equal(result.status, 0, result.stderr);
  assert.doesNotMatch(f.events(), /fnm (env|install)/);
  assert.doesNotMatch(readFileSync(join(f.home, '.zshrc'), 'utf8'), /mac-si-init: fnm/);
});

test('默认三件套无需 CLT、Homebrew 或 Node，并给出 agent 接续入口', (t) => {
  const f = fixture(t);
  const result = f.run([], { TEST_NO_CLT: '1' });
  assert.equal(result.status, 0, result.stderr);
  assert.doesNotMatch(f.events(), /brew |clt-window|fnm |git-clone/);
  assert.match(f.events(), /installed-claude-latest/);
  assert.match(f.events(), /CC-Switch-vtest-macOS.zip/);
  assert.ok(existsSync(join(f.home, 'Applications/CC Switch.app/Contents/MacOS/cc-switch')));
  assert.equal(existsSync(join(f.home, '.mac-si-init')), false);
  assert.match(result.stdout, /start-agent.sh claude/);
  assert.match(result.stdout, /start-agent.sh codex/);
  const config = readFileSync(join(f.home, '.zshrc'), 'utf8');
  assert.match(config, /mac-si-init: local-bin/);
  assert.doesNotMatch(config, /mac-si-init: (fnm|shell)/);
  const eventLog = f.events();
  assert.equal(f.run([]).status, 0);
  assert.equal(f.events(), eventLog);
  assert.equal(readFileSync(join(f.home, '.zshrc'), 'utf8'), config);
});

test('三件套预览无外部命令和用户文件写入，也不会预览其他软件安装', (t) => {
  const f = fixture(t);
  const result = f.run(['--dry-run']);
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /CC Switch/);
  assert.doesNotMatch(result.stdout, /brew install|git clone|fnm install/);
  assert.equal(f.events(), '');
  assert.deepEqual(readdirSync(f.home), []);
});

test('CC Switch 元数据、下载或解压失败会停止并清理临时目录', (t) => {
  const f = fixture(t);
  f.command('claude', 'echo existing-claude');
  f.command('codex', 'echo existing-codex');
  for (const overrides of [{ TEST_CC_FAIL: 'metadata' }, { TEST_CC_FAIL: 'download' }, { TEST_CC_NO_ASSET: '1' }, { TEST_CC_BAD_ARCHIVE: '1' }, { TEST_CC_COPY_FAIL: '1' }]) {
    const result = f.run([], overrides);
    assert.notEqual(result.status, 0);
    assert.equal(existsSync(join(f.home, 'Applications/CC Switch.app')), false);
    assert.equal(readdirSync(f.dir).some((name) => name.startsWith('mac-si-init-cc-switch.')), false);
    const apps = join(f.home, 'Applications');
    if (existsSync(apps)) assert.deepEqual(readdirSync(apps), []);
  }
});

test('三件套检查成功不需要其余工具、CLT 或 Homebrew', (t) => {
  const f = fixture(t);
  assert.equal(f.run([]).status, 0);
  const eventLog = f.events();
  const result = spawnSync('/bin/bash', [join(root, 'scripts/check.sh'), '--bootstrap'], {
    env: { ...f.env, TEST_NO_CLT: '1' }, encoding: 'utf8',
  });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /CC Switch: 已安装/);
  assert.equal(f.events(), eventLog);
});

test('agent 启动脚本从项目目录传递完整初始任务，保留标准交互权限', (t) => {
  const f = fixture(t);
  const launcher = join(root, 'scripts/start-agent.sh');
  for (const agent of ['claude', 'codex']) {
    f.command(agent, 'printf "cwd=%s\\nargc=%s\\n" "$PWD" "$#"; printf "%s\\n" "$1"');
    const name = agent === 'codex' ? 'codex-cli' : agent;
    const result = spawnSync('/bin/bash', [launcher, name], { env: f.env, cwd: f.dir, encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr);
    assert.ok(result.stdout.includes(`cwd=${root}\nargc=1\n`));
    assert.match(result.stdout, /GitHub gh 授权/);
    assert.match(result.stdout, /Orca/);
    assert.doesNotMatch(result.stdout, /--dangerously|--yolo|--full-auto/);
  }
});

test('显式全部安装依次完成各模块，Obsidian 由显式选项启用', (t) => {
  const f = fixture(t);
  const result = f.run(['--only', 'all', '--with-obsidian']);
  assert.equal(result.status, 0, result.stderr);
  assert.ok(existsSync(join(f.home, '.oh-my-zsh/oh-my-zsh.sh')));
  assert.ok(existsSync(join(f.home, '.local/bin/codex')));
  assert.ok(existsSync(join(f.home, 'Applications/CC Switch.app')));
  assert.match(f.events(), /brew install --cask visual-studio-code/);
  assert.match(f.events(), /brew install --cask obsidian/);
  const config = readFileSync(join(f.home, '.zshrc'), 'utf8');
  for (const block of ['env', 'fnm', 'shell']) {
    assert.equal(config.split(`# >>> mac-si-init: ${block} >>>`).length - 1, 1);
  }
});

test('本机检查缺少组件时返回非零，不调用下载器或安装软件', (t) => {
  const f = fixture(t);
  const result = spawnSync('/bin/bash', [join(root, 'scripts/check.sh')], { env: f.env, encoding: 'utf8' });
  assert.equal(result.status, 1, result.stderr);
  assert.match(result.stdout, /缺少 claude/);
  assert.doesNotMatch(f.events(), /curl|brew install|fnm install/);
  assert.deepEqual(readdirSync(f.home), []);
});

test('CLI 传递脚本退出码且可从任意工作目录执行', (t) => {
  const f = fixture(t);
  const result = spawnSync(process.execPath, [cli, '--only', 'ai'], {
    env: { ...f.env, TEST_INSTALL_FAIL: 'claude' }, cwd: f.dir, encoding: 'utf8',
  });
  assert.equal(result.status, 9, result.stderr);
  const noArgs = spawnSync(process.execPath, [cli], { env: f.env, encoding: 'utf8' });
  assert.equal(noArgs.status, 1);
  assert.match(noArgs.stderr, /非交互环境/);
});

test('模板重复加载时保留已有 OMZ 的主题和插件', (t) => {
  const f = fixture(t);
  const template = join(root, 'scripts/zshrc.template.zsh');
  const result = spawnSync('zsh', ['-fic', `
    function omz() { :; }
    ZSH_THEME=existing-theme
    plugins=(git custom-plugin)
    source "$1"
    source "$1"
    print -r -- "$ZSH_THEME|$plugins"
  `, 'test', template], { env: f.env, encoding: 'utf8' });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /existing-theme\|git custom-plugin/);
});
