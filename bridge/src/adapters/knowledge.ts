import { mkdir, readdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import type { CodexTask, KnowledgeSearchResult, SearchHit } from '../types.js';

function assertWithin(root: string, candidate: string): void {
  const relative = path.relative(root, candidate);
  if (relative.startsWith('..') || path.isAbsolute(relative)) {
    throw new Error('Knowledge path escaped its configured root.');
  }
}

async function markdownFiles(root: string, current = root): Promise<string[]> {
  const result: string[] = [];
  let entries;
  try {
    entries = await readdir(current, { withFileTypes: true });
  } catch {
    return result;
  }
  for (const entry of entries) {
    const fullPath = path.join(current, entry.name);
    assertWithin(root, fullPath);
    if (entry.isDirectory()) result.push(...await markdownFiles(root, fullPath));
    else if (entry.isFile() && entry.name.toLowerCase().endsWith('.md')) result.push(fullPath);
    if (result.length >= 500) break;
  }
  return result;
}

export class LocalKnowledgeAdapter {
  constructor(readonly root?: string) {}

  async search(query: string): Promise<KnowledgeSearchResult> {
    const hits: SearchHit[] = [];
    if (this.root) {
      const root = path.resolve(this.root);
      const needle = query.toLocaleLowerCase();
      for (const file of await markdownFiles(root)) {
        const content = await readFile(file, 'utf8');
        const index = content.toLocaleLowerCase().indexOf(needle);
        if (index < 0) continue;
        const start = Math.max(0, index - 80);
        const excerpt = content.slice(start, index + query.length + 120).replace(/\s+/gu, ' ').trim();
        hits.push({ path: path.relative(root, file), title: path.basename(file, '.md'), excerpt });
        if (hits.length >= 20) break;
      }
    }
    return { capability: 'bridge_local_index', obsidianConnected: false, query, hits };
  }

  async archiveTaskResult(task: CodexTask): Promise<string | undefined> {
    if (!this.root || !task.result) return undefined;
    const root = path.resolve(this.root);
    const outputDir = path.join(root, 'The One Mobile');
    assertWithin(root, outputDir);
    await mkdir(outputDir, { recursive: true });
    const safeId = task.id.replace(/[^A-Za-z0-9_-]/gu, '_');
    const output = path.join(outputDir, `${safeId}.md`);
    assertWithin(root, output);
    const body = `# ${task.title}\n\n- Status: ${task.status}\n- Updated: ${task.updatedAt}\n\n${task.result}\n`;
    try {
      await writeFile(output, body, { encoding: 'utf8', flag: 'wx' });
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== 'EEXIST') throw error;
    }
    return path.relative(root, output);
  }
}
