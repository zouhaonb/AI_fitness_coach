import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { DatabaseService } from '../service/DatabaseService';
import { initExerciseData } from '../service/InitData';
import { GlobalContext } from '../common/GlobalContext';
import { AuthService } from '../service/AuthService';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private dbReady: Promise<void> = Promise.resolve();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 初始化全局Context
    GlobalContext.initContext(this.context);

    // 初始化 AppStorage 数据版本
    AppStorage.setOrCreate<number>('dataVersion', 0);

    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    // 存储数据库初始化 Promise，供 onWindowStageCreate 等待
    this.dbReady = (async () => {
      try {
        let store = await DatabaseService.initDatabase();
        await initExerciseData(store);
        hilog.info(DOMAIN, 'testTag', 'Database initialized successfully');
      } catch (err) {
        hilog.error(DOMAIN, 'testTag', 'Database init failed: %{public}s', JSON.stringify(err));
      }
    })();
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    (async () => {
      // 等待数据库初始化完成，避免读写竞争
      await this.dbReady;

      let pageName: string = 'pages/Login';
      try {
        let loggedIn: boolean = await AuthService.isLoggedIn();
        if (loggedIn) {
          pageName = 'pages/Index';
        }
      } catch (err) {
        hilog.error(DOMAIN, 'testTag', 'check login state failed: %{public}s', JSON.stringify(err));
      }

      windowStage.loadContent(pageName, (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, 'testTag', 'Succeeded in loading %{public}s.', pageName);
      });
    })();
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}