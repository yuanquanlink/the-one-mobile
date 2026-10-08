import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppServiceContainer } from '../services/AppServiceContainer';

const DOMAIN: number = 0x0000;
const TAG: string = 'TheOneMobile';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    AppServiceContainer.initialize(this.context);
    hilog.info(DOMAIN, TAG, 'The One Mobile ability created');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (error: BusinessError): void => {
      if (error.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load Index: %{public}s', JSON.stringify(error));
        return;
      }
      hilog.info(DOMAIN, TAG, 'Index loaded');
    });
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'The One Mobile entered foreground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'The One Mobile entered background');
  }
}

