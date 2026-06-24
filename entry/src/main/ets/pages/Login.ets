// entry/src/main/ets/pages/Login.ets
import { router, promptAction } from '@kit.ArkUI';
import { AuthService } from '../service/AuthService';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;

@Entry
@Component
struct Login {
  @State username: string = '8008123049';
  @State password: string = '';
  @State isLoading: boolean = false;

  private showToast(message: string): void {
    promptAction.showToast({ message: message, duration: 2000 });
  }

  async onLoginClick(): Promise<void> {
    if (this.username.trim().length === 0) {
      this.showToast('请输入用户名');
      return;
    }
    if (this.password.length === 0) {
      this.showToast('请输入密码');
      return;
    }
    if (this.username.trim().length < 2) {
      this.showToast('用户名至少2个字符');
      return;
    }
    if (this.password.length < 4) {
      this.showToast('密码至少4位');
      return;
    }

    this.isLoading = true;
    try {
      let success: boolean = await AuthService.login(this.username.trim(), this.password);
      if (success) {
        router.replaceUrl({ url: 'pages/Index' });
      } else {
        this.showToast('用户名或密码错误');
      }
    } catch (err) {
      hilog.error(DOMAIN, 'Login', 'login failed: %{public}s', JSON.stringify(err));
      this.showToast('登录失败，请重试');
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 顶部留白
      Blank()
        .height('10%')

      // Logo
      Image($r('app.media.app_logo'))
        .width(72)
        .height(72)
        .borderRadius(18)
        .shadow({
          radius: 12,
          color: '#33007DFF',
          offsetX: 0,
          offsetY: 6
        })

      // 应用名称
      Text('智练鸿蒙')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A202C')
        .margin({ top: 16 })

      // 副标题
      Text('AI 私人健身教练')
        .fontSize(14)
        .fontColor('#718096')
        .margin({ top: 6 })

      // 功能标签
      Row({ space: 8 }) {
        this.FeatureTag('语音指导');
        this.FeatureTag('智能计划');
        this.FeatureTag('数据分析');
      }
        .margin({ top: 16 })

      // 登录表单卡片
      Column() {
        // 用户名
        Text('用户名')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A202C')
          .margin({ bottom: 8 })
          .alignSelf(ItemAlign.Start)

        Row() {
          SymbolGlyph($r('sys.symbol.person'))
            .fontSize(20)
            .fontColor([$r('sys.color.ohos_id_color_secondary')])
            .margin({ left: 16 })

          TextInput({ placeholder: '请输入用户名', text: this.username })
            .layoutWeight(1)
            .height(48)
            .backgroundColor(Color.Transparent)
            .placeholderColor('#A0AEC0')
            .placeholderFont({ size: 15 })
            .fontColor('#2D3748')
            .fontSize(15)
            .caretColor('#007DFF')
            .padding({ left: 12, right: 16 })
            .onChange((value: string) => {
              this.username = value;
            })
        }
        .width('100%')
        .height(52)
        .backgroundColor('#F7FAFC')
        .borderRadius(14)

        // 密码
        Text('密码')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A202C')
          .margin({ top: 20, bottom: 8 })
          .alignSelf(ItemAlign.Start)

        Row() {
          SymbolGlyph($r('sys.symbol.lock'))
            .fontSize(20)
            .fontColor([$r('sys.color.ohos_id_color_secondary')])
            .margin({ left: 16 })

          TextInput({ placeholder: '请输入密码', text: this.password })
            .type(InputType.Password)
            .layoutWeight(1)
            .height(48)
            .backgroundColor(Color.Transparent)
            .placeholderColor('#A0AEC0')
            .placeholderFont({ size: 15 })
            .fontColor('#2D3748')
            .fontSize(15)
            .caretColor('#007DFF')
            .padding({ left: 12, right: 16 })
            .onChange((value: string) => {
              this.password = value;
            })
        }
        .width('100%')
        .height(52)
        .backgroundColor('#F7FAFC')
        .borderRadius(14)

        // 登录按钮
        Button(this.isLoading ? '登录中...' : '登录')
          .width('100%')
          .height(50)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#007DFF')
          .borderRadius(14)
          .margin({ top: 28 })
          .shadow({
            radius: 16,
            color: '#33007DFF',
            offsetX: 0,
            offsetY: 8
          })
          .enabled(!this.isLoading)
          .onClick(() => {
            this.onLoginClick();
          })

        // 提示
        Row() {
          SymbolGlyph($r('sys.symbol.info_circle'))
            .fontSize(14)
            .fontColor([$r('sys.color.ohos_id_color_secondary')])
            .margin({ right: 4 })
          Text('预设账号：8008123049 / 123456')
            .fontSize(12)
            .fontColor('#A0AEC0')
        }
        .margin({ top: 16 })
      }
      .width('85%')
      .backgroundColor('#FFFFFF')
      .borderRadius(20)
      .padding({ left: 24, right: 24, top: 28, bottom: 28 })
      .margin({ top: 32 })
      .shadow({
        radius: 16,
        color: '#1A000000',
        offsetX: 0,
        offsetY: 8
      })

      // 底部留白
      Blank()
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180,
      colors: [['#F8FAFC', 0.0], ['#EEF2F7', 0.5], ['#E8EDF3', 1.0]]
    })
    .alignItems(HorizontalAlign.Center)
  }

  // 功能标签
  @Builder
  FeatureTag(text: string) {
    Text(text)
      .fontSize(12)
      .fontColor('#007DFF')
      .backgroundColor('#EBF5FF')
      .borderRadius(12)
      .padding({ left: 12, right: 12, top: 5, bottom: 5 })
  }
}
