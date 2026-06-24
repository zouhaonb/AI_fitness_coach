// entry/src/main/ets/common/DeviceUtils.ets
// 设备适配工具类 - 简化版本

export class DeviceUtils {
  // 设备类型枚举
  static readonly DEVICE_PHONE: string = 'phone';
  static readonly DEVICE_TABLET: string = 'tablet';
  static readonly DEVICE_2IN1: string = '2in1';

  // 当前设备类型（可通过配置修改）
  private static currentDeviceType: string = DeviceUtils.DEVICE_PHONE;

  // 设置设备类型（手动配置）
  static setDeviceType(deviceType: string): void {
    DeviceUtils.currentDeviceType = deviceType;
  }

  // 获取当前设备类型
  static getDeviceType(): string {
    return DeviceUtils.currentDeviceType;
  }

  // 获取Grid列数（运动库页面）
  static getExerciseGridColumns(): string {
    switch (DeviceUtils.currentDeviceType) {
      case DeviceUtils.DEVICE_2IN1:
        return '1fr 1fr 1fr 1fr';  // 大屏4列
      case DeviceUtils.DEVICE_TABLET:
        return '1fr 1fr 1fr';      // 平板3列
      default:
        return '1fr 1fr';          // 手机2列
    }
  }

  // 获取Grid列数（日历页面）
  static getCalendarGridColumns(): string {
    // 日历固定7列（星期一到星期日）
    return '1fr 1fr 1fr 1fr 1fr 1fr 1fr';
  }

  // 获取Grid间距
  static getGridGap(): number {
    switch (DeviceUtils.currentDeviceType) {
      case DeviceUtils.DEVICE_2IN1:
        return 24;  // 大屏间距更大
      case DeviceUtils.DEVICE_TABLET:
        return 20;  // 平板间距适中
      default:
        return 16;  // 手机间距较小
    }
  }

  // 获取字体大小（根据设备类型调整）
  static getFontSize(baseSize: number): number {
    switch (DeviceUtils.currentDeviceType) {
      case DeviceUtils.DEVICE_2IN1:
        return baseSize + 4;  // 大屏字体+4
      case DeviceUtils.DEVICE_TABLET:
        return baseSize + 2;  // 平板字体+2
      default:
        return baseSize;      // 手机字体不变
    }
  }

  // 获取图片尺寸（根据设备类型调整）
  static getImageSize(baseSize: number): number {
    switch (DeviceUtils.currentDeviceType) {
      case DeviceUtils.DEVICE_2IN1:
        return Math.floor(baseSize * 1.5);  // 大屏图片×1.5
      case DeviceUtils.DEVICE_TABLET:
        return Math.floor(baseSize * 1.2);  // 平板图片×1.2
      default:
        return baseSize;                     // 手机图片不变
    }
  }

  // 获取间距（根据设备类型调整）
  static getSpacing(baseSpacing: number): number {
    switch (DeviceUtils.currentDeviceType) {
      case DeviceUtils.DEVICE_2IN1:
        return Math.floor(baseSpacing * 1.5);  // 大屏间距×1.5
      case DeviceUtils.DEVICE_TABLET:
        return Math.floor(baseSpacing * 1.2);  // 平板间距×1.2
      default:
        return baseSpacing;                     // 手机间距不变
    }
  }

  // 获取卡片宽度百分比
  static getCardWidth(): string {
    switch (DeviceUtils.currentDeviceType) {
      case DeviceUtils.DEVICE_2IN1:
        return '60%';   // 大屏卡片更窄
      case DeviceUtils.DEVICE_TABLET:
        return '80%';   // 平板卡片适中
      default:
        return '92%';   // 手机卡片更宽
    }
  }
}
