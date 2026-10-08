import { scriptManager } from '@kit.AbilityKit';
import { AppServiceContainer } from '../../../src/main/ets/services/AppServiceContainer';
import { InboxItem, InboxType } from '../../../src/main/ets/model/InboxItem';
import { CodexTask } from '../../../src/main/ets/model/CodexTask';

export default class TheOneSkill {
  public async save_to_brain(info: scriptManager.ArkTSScriptInfo, ...argv: string[]): Promise<void> {
    const content: string = argv.length > 0 ? argv[0].trim() : '';
    const typeName: string = argv.length > 1 ? argv[1].trim() : 'note';
    if (content.length === 0) {
      await this.reportFailure(info, 'ERR_INVALID_PARAMS', 'content is empty',
        '请告诉我要保存的具体内容。');
      return;
    }
    let type: InboxType = InboxType.NOTE;
    if (typeName === InboxType.IDEA) type = InboxType.IDEA;
    else if (typeName === InboxType.MATERIAL) type = InboxType.MATERIAL;
    else if (typeName === InboxType.TASK) type = InboxType.TASK;
    try {
      AppServiceContainer.initialize(info.context);
      const item: InboxItem = await AppServiceContainer.get().captureService
        .capture(content, type, ['brain', 'skill']);
      const data: Record<string, Object> = {
        'id': item.id,
        'destination': 'local_inbox',
        'syncStatus': item.syncStatus
      };
      await this.reportSuccess(info, data);
    } catch (error) {
      console.error(`save_to_brain failed: ${error}`);
      await this.reportFailure(info, 'ERR_INTERNAL', 'local save failed',
        '保存失败了，请打开 The One 重试。');
    }
  }

  public async create_codex_task(info: scriptManager.ArkTSScriptInfo, ...argv: string[]): Promise<void> {
    const title: string = argv.length > 0 ? argv[0].trim() : '';
    const description: string = argv.length > 1 ? argv[1].trim() : '';
    if (title.length === 0) {
      await this.reportFailure(info, 'ERR_INVALID_PARAMS', 'title is empty',
        '请告诉我要创建什么任务。');
      return;
    }
    try {
      AppServiceContainer.initialize(info.context);
      const task: CodexTask = await AppServiceContainer.get().taskService.create(title, description);
      const data: Record<string, Object> = {
        'id': task.id,
        'queue': 'manual_codex_adapter',
        'status': task.status
      };
      await this.reportSuccess(info, data);
    } catch (error) {
      console.error(`create_codex_task failed: ${error}`);
      await this.reportFailure(info, 'ERR_INTERNAL', 'local task creation failed',
        '任务创建失败了，请打开 The One 重试。');
    }
  }

  private async reportSuccess(info: scriptManager.ArkTSScriptInfo,
    data: Record<string, Object>): Promise<void> {
    const payload: Record<string, Object> = {
      'type': 'result',
      'status': 'success',
      'data': data
    };
    await this.report(info, { code: 0, result: payload });
  }

  private async reportFailure(info: scriptManager.ArkTSScriptInfo, errCode: string,
    errMsg: string, suggestion: string): Promise<void> {
    const payload: Record<string, Object> = {
      'type': 'result',
      'status': 'failed',
      'errCode': errCode,
      'errMsg': errMsg,
      'suggestion': suggestion
    };
    await this.report(info, { code: -1, result: payload });
  }

  private async report(info: scriptManager.ArkTSScriptInfo,
    result: scriptManager.ExecuteResult): Promise<void> {
    try {
      await scriptManager.completeArkTSScriptInApp(info.context, info.requestCode, result);
    } catch (error) {
      console.error(`completeArkTSScriptInApp failed: ${error}`);
    }
  }
}
