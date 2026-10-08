import type { CodexTask } from '../types.js';

export interface CodexDispatchResult {
  accepted: boolean;
  mode: 'manual';
  message: string;
}

export interface CodexAdapter {
  dispatch(task: CodexTask): Promise<CodexDispatchResult>;
}

// There is intentionally no undocumented Codex automation here. The bridge
// stores a real task and tells the user that dispatch remains manual.
export class ManualCodexAdapter implements CodexAdapter {
  async dispatch(_task: CodexTask): Promise<CodexDispatchResult> {
    return {
      accepted: true,
      mode: 'manual',
      message: 'Task stored locally. Open Codex and dispatch it manually.'
    };
  }
}
