export class Routes {
  static readonly CAPTURE: string = 'capture';
  static readonly INBOX: string = 'inbox';
  static readonly INBOX_DETAIL: string = 'inbox_detail';
  static readonly CODEX_TASKS: string = 'codex_tasks';
  static readonly CODEX_TASK_CREATE: string = 'codex_task_create';
  static readonly CODEX_TASK_DETAIL: string = 'codex_task_detail';
  static readonly SETTINGS: string = 'settings';
  static readonly BRAIN: string = 'brain';
}

export class NavigationState {
  static selectedInboxId: string = '';
  static selectedTaskId: string = '';
}
