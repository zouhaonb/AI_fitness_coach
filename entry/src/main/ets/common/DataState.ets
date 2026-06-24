// entry/src/main/ets/common/DataState.ets
// 全局训练数据状态管理，用于跨页面数据同步

export class DataState {
  private static instance: DataState;
  
  // 数据版本号，每次更新时递增
  private dataVersion: number = 0;
  
  private constructor() {}
  
  static getInstance(): DataState {
    if (!DataState.instance) {
      DataState.instance = new DataState();
    }
    return DataState.instance;
  }
  
  // 获取当前数据版本
  getVersion(): number {
    return this.dataVersion;
  }
  
  // 触发数据更新
  notifyDataChanged(): void {
    this.dataVersion++;
    console.info(`[DataState] Data updated, version: ${this.dataVersion}`);
  }
}
