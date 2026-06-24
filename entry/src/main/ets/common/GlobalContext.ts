// entry/src/main/ets/common/GlobalContext.ets
import { common } from '@kit.AbilityKit';

export class GlobalContext {
  private static context: common.UIAbilityContext;

  public static initContext(context: common.UIAbilityContext): void {
    GlobalContext.context = context;
  }

  public static getContext(): common.UIAbilityContext {
    if (GlobalContext.context === null || GlobalContext.context === undefined) {
      throw new Error('GlobalContext not initialized. Call initContext() first.');
    }
    return GlobalContext.context;
  }
}
