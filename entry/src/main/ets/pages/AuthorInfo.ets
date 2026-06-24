// entry/src/main/ets/pages/AuthorInfo.ets
import { router } from '@kit.ArkUI';

class InfoItem {
  label: string = '';
  value: string = '';
}

@Entry
@Component
struct AuthorInfo {
  private infoItems: Array<InfoItem> = [
    { label: '姓名', value: '邹昊' },
    { label: '学号', value: '8008123049' },
    { label: '班级', value: '软工2301班' },
    { label: '专业', value: '软件工程' },
    { label: '指导教师', value: '危建国' },
    { label: '项目名称', value: '智练鸿蒙——AI私人健身教练' }
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

        Text('关于作者')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ left: 8 })
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      // 信息卡片
      Column() {
        // 圆形头像
        Image($r('app.media.avatar'))
          .width(100)
          .height(100)
          .clip(new Circle({ width: 100, height: 100 }))
          .objectFit(ImageFit.Cover)
          .margin({ bottom: 20 })

        // 作者信息
        ForEach(this.infoItems, (item: InfoItem) => {
          Row() {
            Text(item.label)
              .fontSize(16)
              .fontColor('#999999')
              .width(90)

            Text(item.value)
              .fontSize(16)
              .fontColor('#333333')
              .layoutWeight(1)
          }
          .width('100%')
          .padding({ top: 10, bottom: 10 })
          .border({ width: { bottom: 1 }, color: '#F0F0F0' })
        })
      }
      .width('90%')
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .padding(20)
      .margin({ top: 8 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
