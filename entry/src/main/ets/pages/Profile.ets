// entry/src/main/ets/pages/Profile.ets
import { router, promptAction } from '@kit.ArkUI';
import { ConfigService } from '../service/ConfigService';
import { DatabaseService } from '../service/DatabaseService';
import { UserConfig } from '../model/ExerciseModel';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { AuthService } from '../service/AuthService';

class MenuItem {
  title: string = '';
  route: string = '';
  icon: string = '';
}

@CustomDialog
struct EditProfileDialog {
  controller: CustomDialogController;
  @State editNickname: string = '';
  @State editBio: string = '';
  @State editCity: string = '';
  onSave: () => void = () => {};

  build() {
    Column() {
      Text('编辑个人信息')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A202C')
        .margin({ bottom: 24 })

      // 昵称输入
      Column() {
        Text('昵称')
          .fontSize(14)
          .fontColor('#718096')
          .width('100%')
          .margin({ bottom: 8 })
        TextInput({ placeholder: '请输入昵称', text: this.editNickname })
          .width('100%')
          .height(48)
          .backgroundColor('#F7FAFC')
          .borderRadius(12)
          .placeholderColor('#A0AEC0')
          .fontColor('#2D3748')
          .fontSize(15)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.editNickname = value;
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 简介输入
      Column() {
        Text('简介')
          .fontSize(14)
          .fontColor('#718096')
          .width('100%')
          .margin({ top: 16, bottom: 8 })
        TextInput({ placeholder: '请输入简介', text: this.editBio })
          .width('100%')
          .height(48)
          .backgroundColor('#F7FAFC')
          .borderRadius(12)
          .placeholderColor('#A0AEC0')
          .fontColor('#2D3748')
          .fontSize(15)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.editBio = value;
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 城市输入
      Column() {
        Text('所在城市')
          .fontSize(14)
          .fontColor('#718096')
          .width('100%')
          .margin({ top: 16, bottom: 8 })
        TextInput({ placeholder: '请输入城市', text: this.editCity })
          .width('100%')
          .height(48)
          .backgroundColor('#F7FAFC')
          .borderRadius(12)
          .placeholderColor('#A0AEC0')
          .fontColor('#2D3748')
          .fontSize(15)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.editCity = value;
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 按钮组
      Row() {
        Button('取消')
          .width('48%')
          .height(48)
          .fontSize(16)
          .fontColor('#718096')
          .backgroundColor('#EDF2F7')
          .borderRadius(12)
          .onClick(() => {
            this.controller.close();
          })

        Button('保存')
          .width('48%')
          .height(48)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#007DFF')
          .borderRadius(12)
          .onClick(async () => {
            try {
              let config = await ConfigService.getConfig();
              config.nickname = this.editNickname;
              config.bio = this.editBio;
              config.city = this.editCity;
              await ConfigService.saveConfig(config);
              this.onSave();
              this.controller.close();
            } catch (err) {
              console.error('Save profile failed');
            }
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 32 })
    }
    .width('100%')
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
  }
}

@Entry
@Component
export struct Profile {
  @Prop @Watch('onTabSwitch') activeTabIndex: number = 0;
  myTabIndex: number = 0;
  @State nickname: string = '健身达人';
  @State goalText: string = '保持健康';
  @State frequency: number = 5;
  @State streakDays: number = 0;
  @State weekCount: number = 0;
  @State totalMinutes: number = 0;
  @State bio: string = '坚持锻炼，遇见更好的自己';
  @State city: string = '';
  @State avatarUri: string = '';
  @State ttsEnabled: boolean = true;
  @State avatarScale: number = 1.0;
  @StorageLink('dataVersion') @Watch('onDataChanged') dataVersion: number = 0;

  private menuList: Array<MenuItem> = [
    { title: '训练计划设置', route: 'pages/PlanSetting', icon: 'sys.symbol.calendar' },
    { title: '关于应用', route: 'pages/AboutApp', icon: 'sys.symbol.info_circle' },
    { title: '退出登录', route: 'logout', icon: 'sys.symbol.arrow_right_square' }
  ];

  private editDialogController: CustomDialogController = new CustomDialogController({
    builder: EditProfileDialog({
      editNickname: this.nickname,
      editBio: this.bio,
      editCity: this.city,
      onSave: () => {
        this.loadData();
      }
    }),
    autoCancel: true
  });

  private getGoalText(goal: string): string {
    if (goal === 'lose_fat') {
      return '减脂';
    } else if (goal === 'gain_muscle') {
      return '增肌';
    }
    return '保持健康';
  }

  async aboutToAppear(): Promise<void> {
    this.loadData();
  }

  onTabSwitch(): void {
    if (this.activeTabIndex === this.myTabIndex) {
      this.loadData();
    }
  }

  // 监听训练数据变化
  onDataChanged(): void {
    console.info(`[Profile] Data changed, version: ${this.dataVersion}`);
    this.loadData();
  }

  onPageShow(): void {
    this.loadData();
  }

  async loadData(): Promise<void> {
    console.info('[Profile] loadData started');
    try {
      let config = await ConfigService.getConfig();
      this.nickname = config.nickname;
      this.frequency = config.frequency;
      this.goalText = this.getGoalText(config.goal);
      this.bio = config.bio;
      this.city = config.city;
      this.avatarUri = config.avatarUri;
      this.ttsEnabled = config.ttsEnabled;
    } catch (err) {
      console.error('Profile loadConfig failed: ' + JSON.stringify(err));
    }

    try {
      this.streakDays = await DatabaseService.getStreakDays();
      this.weekCount = await DatabaseService.getWeekCount();
      this.totalMinutes = await DatabaseService.getTotalMinutes();
      console.info(`[Profile] Stats loaded - streakDays: ${this.streakDays}, weekCount: ${this.weekCount}, totalMinutes: ${this.totalMinutes}`);
    } catch (err) {
      console.error('Profile loadStats failed: ' + JSON.stringify(err));
    }
  }

  private openAvatarPicker(): void {
    // 头像点击动画
    animateTo({
      duration: 150,
      curve: Curve.EaseOut
    }, () => {
      this.avatarScale = 0.9;
    });

    setTimeout(() => {
      animateTo({
        duration: 150,
        curve: Curve.EaseIn
      }, () => {
        this.avatarScale = 1.0;
      });
    }, 150);

    try {
      let photoPicker = new photoAccessHelper.PhotoViewPicker();
      let selectOptions = new photoAccessHelper.PhotoSelectOptions();
      selectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      selectOptions.maxSelectNumber = 1;
      photoPicker.select(selectOptions).then((result: photoAccessHelper.PhotoSelectResult) => {
        if (result.photoUris.length > 0) {
          let uri: string = result.photoUris[0];
          this.avatarUri = uri;
          this.saveAvatar(uri);
        }
      });
    } catch (err) {
      console.error('Avatar picker failed: ' + JSON.stringify(err));
    }
  }

  private async saveAvatar(uri: string): Promise<void> {
    try {
      let config = await ConfigService.getConfig();
      config.avatarUri = uri;
      await ConfigService.saveConfig(config);
    } catch (err) {
      console.error('Save avatar failed');
    }
  }

  private onLogoutClick(): void {
    promptAction.showDialog({
      title: '退出登录',
      message: '确定要退出当前账号吗？',
      buttons: [
        { text: '取消', color: '#999999' },
        { text: '确定退出', color: '#CF0A2C' }
      ]
    }).then((result: promptAction.ShowDialogSuccessResponse) => {
      if (result.index === 1) {
        AuthService.logout().then(() => {
          router.replaceUrl({ url: 'pages/Login' });
        });
      }
    });
  }

  build() {
    Column() {
      // 顶部标题栏
      this.TitleBar();

      // 内容区域
      Scroll() {
        Column() {
          // 用户信息卡片
          this.ProfileCard();

          // 数据统计卡片
          this.StatsCard();

          // 语音播报开关
          this.TTSSwitch();

          // 功能菜单列表
          this.MenuList();
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring);
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180,
      colors: [['#F8FAFC', 0.0], ['#EEF2F7', 0.5], ['#E8EDF3', 1.0]]
    });
  }

  // 顶部标题栏
  @Builder
  TitleBar(): void {
    Row() {
      Text('个人中心')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A202C')
        .letterSpacing(1);
    }
    .width('100%')
    .height(56)
    .padding({ left: 20, right: 20 })
    .alignItems(VerticalAlign.Center);
  }

  // 用户信息卡片
  @Builder
  ProfileCard(): void {
    Column() {
      // 头像区域
      Stack() {
        // 装饰背景
        Column()
          .width(120)
          .height(120)
          .linearGradient({
            angle: 135,
            colors: [['#667EEA', 0.0], ['#764BA2', 1.0]]
          })
          .borderRadius(60)
          .opacity(0.15);

        // 头像
        if (this.avatarUri !== '') {
          Image(this.avatarUri)
            .width(100)
            .height(100)
            .clip(new Circle({ width: 100, height: 100 }))
            .objectFit(ImageFit.Cover)
            .border({ width: 3, color: '#FFFFFF' })
            .shadow({
              radius: 16,
              color: '#33000000',
              offsetX: 0,
              offsetY: 8
            })
            .scale({ x: this.avatarScale, y: this.avatarScale })
            .onClick(() => {
              this.openAvatarPicker();
            });
        } else {
          Image($r('app.media.avatar_placeholder'))
            .width(100)
            .height(100)
            .clip(new Circle({ width: 100, height: 100 }))
            .objectFit(ImageFit.Cover)
            .border({ width: 3, color: '#FFFFFF' })
            .shadow({
              radius: 16,
              color: '#33000000',
              offsetX: 0,
              offsetY: 8
            })
            .scale({ x: this.avatarScale, y: this.avatarScale })
            .onClick(() => {
              this.openAvatarPicker();
            });
        }
      }
      .width(120)
      .height(120);

      // 昵称和编辑按钮
      Row() {
        Text(this.nickname)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A202C');

        Button() {
          SymbolGlyph($r('sys.symbol.square_and_pencil'))
            .fontSize(16)
            .fontColor(['#007DFF']);
        }
        .type(ButtonType.Circle)
        .width(32)
        .height(32)
        .backgroundColor('#EBF4FF')
        .margin({ left: 8 })
        .onClick(() => {
          this.editDialogController.open();
        });
      }
      .margin({ top: 16 });

      // 简介
      if (this.bio !== '') {
        Text(this.bio)
          .fontSize(14)
          .fontColor('#718096')
          .margin({ top: 8 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center);
      }

      // 城市
      if (this.city !== '') {
        Row() {
          Text('📍')
            .fontSize(14);
          Text(this.city)
            .fontSize(14)
            .fontColor('#A0AEC0')
            .margin({ left: 4 });
        }
        .margin({ top: 6 });
      }
    }
    .width('92%')
    .padding({ top: 32, bottom: 32, left: 20, right: 20 })
    .margin({ top: 8 })
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .shadow({
      radius: 20,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 8
    });
  }

  // 数据统计卡片
  @Builder
  StatsCard(): void {
    Row() {
      // 连续打卡
      Column() {
        SymbolGlyph($r('sys.symbol.flame'))
          .fontSize(24)
          .fontColor(['#FF6B6B']);
        Text(`${this.streakDays}`)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A202C')
          .margin({ top: 8 });
        Text('连续打卡')
          .fontSize(12)
          .fontColor('#718096')
          .margin({ top: 4 });
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center);

      Divider()
        .vertical(true)
        .height(50)
        .color('#EDF2F7');

      // 本周运动
      Column() {
        SymbolGlyph($r('sys.symbol.calendar'))
          .fontSize(24)
          .fontColor(['#4FC3F7']);
        Text(`${this.weekCount}`)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A202C')
          .margin({ top: 8 });
        Text('本周运动')
          .fontSize(12)
          .fontColor('#718096')
          .margin({ top: 4 });
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center);

      Divider()
        .vertical(true)
        .height(50)
        .color('#EDF2F7');

      // 累计时长
      Column() {
        SymbolGlyph($r('sys.symbol.clock'))
          .fontSize(24)
          .fontColor(['#69DB7C']);
        Text(`${this.totalMinutes}`)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A202C')
          .margin({ top: 8 });
        Text('累计(分)')
          .fontSize(12)
          .fontColor('#718096')
          .margin({ top: 4 });
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center);
    }
    .width('92%')
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .padding({ top: 24, bottom: 24, left: 16, right: 16 })
    .margin({ top: 16 })
    .shadow({
      radius: 16,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 6
    });
  }

  // 统计项组件
  @Builder
  StatItem(icon: Resource, value: string, label: string, color: string): void {
    Column() {
      SymbolGlyph(icon)
        .fontSize(24)
        .fontColor([color]);

      Text(value)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A202C')
        .margin({ top: 8 });

      Text(label)
        .fontSize(12)
        .fontColor('#718096')
        .margin({ top: 4 });
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center);
  }

  // 语音播报开关
  @Builder
  TTSSwitch(): void {
    Row() {
      Row() {
        SymbolGlyph($r('sys.symbol.speaker_wave_2'))
          .fontSize(20)
          .fontColor(['#007DFF']);

        Text('语音播报')
          .fontSize(16)
          .fontColor('#2D3748')
          .margin({ left: 12 });
      }

      Toggle({ type: ToggleType.Switch, isOn: this.ttsEnabled })
        .selectedColor('#007DFF')
        .onChange(async (isOn: boolean) => {
          this.ttsEnabled = isOn;
          await ConfigService.setTtsEnabled(isOn);
        });
    }
    .width('92%')
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .padding({ left: 20, right: 20, top: 18, bottom: 18 })
    .margin({ top: 16 })
    .shadow({
      radius: 12,
      color: '#0A000000',
      offsetX: 0,
      offsetY: 4
    })
    .justifyContent(FlexAlign.SpaceBetween);
  }

  // 功能菜单列表
  @Builder
  MenuList(): void {
    Column() {
      ForEach(this.menuList, (item: MenuItem, index: number) => {
        Column() {
          Row() {
            Row() {
              SymbolGlyph($r(item.icon))
                .fontSize(20)
                .fontColor(['#007DFF']);

              Text(item.title)
                .fontSize(16)
                .fontColor('#2D3748')
                .margin({ left: 12 });
            }

            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(18)
              .fontColor(['#A0AEC0']);
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 18, bottom: 18 })
          .justifyContent(FlexAlign.SpaceBetween)
          .onClick(() => {
            if (item.route === 'logout') {
              this.onLogoutClick();
            } else {
              router.pushUrl({ url: item.route });
            }
          });

          // 分隔线（最后一项不显示）
          if (index < this.menuList.length - 1) {
            Divider()
              .width('85%')
              .color('#EDF2F7');
          }
        }
      });
    }
    .width('92%')
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .margin({ top: 16, bottom: 24 })
    .shadow({
      radius: 12,
      color: '#0A000000',
      offsetX: 0,
      offsetY: 4
    });
  }
}
