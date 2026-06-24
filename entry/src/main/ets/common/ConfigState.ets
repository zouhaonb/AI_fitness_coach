// entry/src/main/ets/common/ConfigState.ets
// 全局配置状态管理，用于跨页面状态同步

export class ConfigState {
  private static instance: ConfigState;

  private constructor() {}
  
  // 配置版本号，每次更新时递增
  private configVersion: number = 0;
  
  // 监听器列表
  private listeners: Array<() => void> = [];
  
  static getInstance(): ConfigState {
    if (!ConfigState.instance) {
      ConfigState.instance = new ConfigState();
    }
    return ConfigState.instance;
  }
  
  // 获取当前配置版本
  getVersion(): number {
    return this.configVersion;
  }
  
  // 触发配置更新
  notifyConfigChanged(): void {
    this.configVersion++;
    console.info(`[ConfigState] Config updated, version: ${this.configVersion}`);
    // 通知所有监听器
    for (let listener of this.listeners) {
      listener();
    }
  }
  
  // 添加监听器
  addListener(listener: () => void): void {
    this.listeners.push(listener);
  }
  
  // 移除监听器
  removeListener(listener: () => void): void {
    let index: number = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }
}
