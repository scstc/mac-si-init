#!/usr/bin/env node
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { createInterface } from 'node:readline/promises';
import { stdin, stdout } from 'node:process';

const installer = fileURLToPath(new URL('./scripts/install.sh', import.meta.url));
const checker = fileURLToPath(new URL('./scripts/check.sh', import.meta.url));
const launcher = fileURLToPath(new URL('./scripts/start-agent.sh', import.meta.url));
const readme = fileURLToPath(new URL('./README.md', import.meta.url));

function run(script, args = []) {
  return new Promise((resolve) => {
    const child = spawn('/bin/bash', [script, ...args], { stdio: 'inherit' });
    child.on('error', (error) => { console.error(error.message); resolve(1); });
    child.on('exit', (code, signal) => {
      if (signal) console.error(`脚本被 ${signal} 中断`);
      resolve(code ?? 1);
    });
  });
}

async function main() {
  const args = process.argv.slice(2);
  if (args[0] === '--docs' && args.length === 1) {
    console.log(`手册：${readme}`);
    return 0;
  }
  if (args[0] === '--check') return run(checker, args.slice(1));
  if (args[0] === '--agent') return run(launcher, args.slice(1));
  if (args.length) return run(installer, args);
  if (!stdin.isTTY || !stdout.isTTY) {
    console.error('非交互环境请指定参数，例如 --only bootstrap 或 --dry-run；帮助：--help');
    return 1;
  }
  console.log(`
mac-si-init · macOS → AI 开发工作站

  [1] 安装三件套：Claude Code / CC Switch / Codex CLI（推荐）
  [2] 让 Claude 引导安装其余软件与账号授权
  [3] 让 Codex 引导安装其余软件与账号授权
  [4] 高级：脚本直接安装全套软件
  [5] 检查三件套安装
  [6] 检查全套环境
  [7] 预览三件套安装步骤
  [8] 手册路径
  [q] 退出
`);
  const rl = createInterface({ input: stdin, output: stdout });
  let choice;
  try { choice = (await rl.question('请选择：')).trim().toLowerCase(); }
  finally { rl.close(); }
  if (choice === '1') return run(installer);
  if (choice === '2') return run(launcher, ['claude']);
  if (choice === '3') return run(launcher, ['codex']);
  if (choice === '4') return run(installer, ['--only', 'all']);
  if (choice === '5') return run(checker, ['--bootstrap']);
  if (choice === '6') return run(checker);
  if (choice === '7') return run(installer, ['--dry-run']);
  if (choice === '8') { console.log(`手册：${readme}`); return 0; }
  if (choice === 'q') return 0;
  console.error('无效选项');
  return 1;
}

main().then((code) => { process.exitCode = code; }).catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
