// entry/src/main/ets/pages/AboutApp.ets
import { router } from '@kit.ArkUI';

class FeatureItem {
  text: string = '';
}

@Entry
@Component
struct AboutApp {
  private features: Array<FeatureItem> = [
    { text: 'AI 语音训练指导' },
    { text: '个性化训练计划' },
    { text: '运动数据可视化' },
    { text: 'DeepSeek 智能建议' }
  ];

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('<')
          .fontSize(24)
          .fontColor('#333333')
          .onClick(() => {
            router.back();
          })

        Text('关于应用')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ left: 8 })
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      // 内容卡片
      Column() {
        // 应用 Logo
        Image($r('app.media.app_logo'))
          .width(64)
          .height(64)

        // 应用名称
        Text('智练鸿蒙')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ top: 12 })

        // 版本号
        Text('v1.0.0')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 4 })

        // 分隔线
        Divider()
          .color('#F0F0F0')
          .margin({ top: 16, bottom: 16 })

        // 应用简介
        Text('一款基于 HarmonyOS 的智能健身训练应用，提供个性化训练计划、语音播报指导、运动数据统计及 AI 智能建议。')
          .fontSize(14)
          .fontColor('#666666')
          .lineHeight(22)

        // 功能特色标题
        Text('功能特色')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ top: 20 })
          .alignSelf(ItemAlign.Start)

        // 功能特色列表
        ForEach(this.features, (item: FeatureItem) => {
          Row() {
            Text('·')
              .fontSize(14)
              .fontColor('#007DFF')
              .width(20)

            Text(item.text)
              .fontSize(14)
              .fontColor('#666666')
          }
          .width('100%')
          .margin({ top: 8 })
          .alignItems(VerticalAlign.Center)
        })

        // 关于作者按钮
        Button('关于作者')
          .width('100%')
          .height(44)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .margin({ top: 30 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/AuthorInfo' });
          })
      }
      .width('90%')
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .padding(20)
      .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
