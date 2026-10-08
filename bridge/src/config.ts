import { readFileSync } from 'node:fs';
import path from 'node:path';

export interface BridgeConfig {
  host: string;
  port: number;
  token?: string;
  dataFile: string;
  knowledgeRoot?: string;
}

function parseEnvFile(filePath: string): Record<string, string> {
  try {
    const result: Record<string, string> = {};
    for (const rawLine of readFileSync(filePath, 'utf8').split(/\r?\n/u)) {
      const line = rawLine.trim();
      if (!line || line.startsWith('#')) continue;
      const separator = line.indexOf('=');
      if (separator <= 0) continue;
      const key = line.slice(0, separator).trim();
      const value = line.slice(separator + 1).trim().replace(/^['"]|['"]$/gu, '');
      result[key] = value;
    }
    return result;
  } catch {
    return {};
  }
}

function isLoopback(host: string): boolean {
  return host === '127.0.0.1' || host === 'localhost' || host === '::1';
}

export function loadConfig(cwd = process.cwd()): BridgeConfig {
  const fileEnv = parseEnvFile(path.join(cwd, '.env'));
  const value = (name: string): string | undefined => process.env[name] || fileEnv[name];
  const host = value('THE_ONE_BRIDGE_HOST') || '127.0.0.1';
  const port = Number(value('THE_ONE_BRIDGE_PORT') || '4317');
  const token = value('THE_ONE_BRIDGE_TOKEN');
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error('THE_ONE_BRIDGE_PORT must be an integer between 1 and 65535.');
  }
  if (!isLoopback(host) && (!token || token.length < 24)) {
    throw new Error('A token of at least 24 characters is required for non-loopback listening.');
  }
  const dataFile = path.resolve(cwd, value('THE_ONE_BRIDGE_DATA') || path.join('data', 'state.json'));
  const knowledge = value('THE_ONE_KNOWLEDGE_ROOT');
  const config: BridgeConfig = { host, port, dataFile };
  if (token) config.token = token;
  if (knowledge) config.knowledgeRoot = path.resolve(cwd, knowledge);
  return config;
}
