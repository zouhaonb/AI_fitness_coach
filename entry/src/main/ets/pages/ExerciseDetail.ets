// entry/src/main/ets/pages/ExerciseDetail.ets
import { router } from '@kit.ArkUI';

// 难度等级枚举
class DifficultyLevel {
  static readonly Beginner: string = '初级';
  static readonly Intermediate: string = '中级';
  static readonly Advanced: string = '高级';
}

@Entry
@Component
struct ExerciseDetail {
  // 状态管理
  @State name: string = '';
  @State category: string = '';
  @State description: string = '';
  @State type: string = '';
  @State sets: number = 0;
  @State reps: number = 0;
  @State duration: number = 0;
  @State headerOpacity: number = 0.0;
  @State contentOffset: number = 0;

  private exerciseId: number = 0;
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    const params: Record<string, string> = router.getParams() as Record<string, string>;
    if (params !== null && params !== undefined) {
      this.exerciseId = Number(params['id']);
      this.name = params['name'];
      this.category = params['category'];
      this.description = params['description'];
      this.type = params['type'];
      this.sets = Number(params['sets']);
      this.reps = Number(params['reps']);
      this.duration = Number(params['duration']);
    }

    // 启动入场动画
    setTimeout(() => {
      animateTo({
        duration: 400,
        curve: Curve.EaseOut
      }, () => {
        this.headerOpacity = 1.0;
      });
    }, 100);
  }

  private getTypeLabel(): string {
    return this.type === 'timer' ? '计时类' : '计次类';
  }

  // 获取运动图片路径
  private getExerciseImagePath(): string | Resource {
    let nameMap: Map<string, string> = new Map([
      ['俯卧撑', 'pushup'], ['哑铃飞鸟', 'dumbbell_fly'],
      ['杠铃深蹲', 'squat'], ['弓步蹲', 'lunge'], ['靠墙静蹲', 'wall_sit'],
      ['仰卧起坐', 'situp'], ['平板支撑', 'plank'], ['卷腹', 'crunch'],
      ['引体向上', 'pullup'], ['俯身划船', 'bent_over_row'],
      ['开合跳', 'jumping_jack'], ['高抬腿', 'high_knees'],
      ['波比跳', 'burpee'], ['跳绳', 'jump_rope'],
      ['颈部拉伸', 'neck_stretch'], ['体前屈', 'forward_bend'],
      ['肩部拉伸', 'shoulder_stretch'], ['全身拉伸', 'full_body_stretch']
    ]);
    let fileName: string | undefined = nameMap.get(this.name);
    if (fileName !== undefined) {
      let categoryMap: Map<string, string> = new Map([
        ['胸部', 'chest'], ['腿部', 'leg'], ['腹部', 'abs'],
        ['背部', 'back'], ['有氧', 'cardio'], ['拉伸', 'stretch']
      ]);
      let cat: string | undefined = categoryMap.get(this.category);
      if (cat !== undefined) {
        return 'resource://RAWFILE/exercises/' + cat + '/' + fileName + '.png';
      }
    }
    // 占位图在 media 目录，使用 $r 引用
    return $r('app.media.exercise_placeholder');
  }

  // 获取难度等级
  private getDifficulty(): string {
    if (this.sets >= 5 && this.reps >= 20) {
      return DifficultyLevel.Advanced;
    } else if (this.sets >= 3 && this.reps >= 15) {
      return DifficultyLevel.Intermediate;
    }
    return DifficultyLevel.Beginner;
  }

  // 获取难度颜色
  private getDifficultyColor(): string {
    const difficulty: string = this.getDifficulty();
    if (difficulty === DifficultyLevel.Advanced) {
      return '#FF6B6B';
    } else if (difficulty === DifficultyLevel.Intermediate) {
      return '#FFA94D';
    }
    return '#69DB7C';
  }

  // 获取分类颜色
  private getCategoryColor(): string {
    const colorMap: Map<string, string> = new Map([
      ['胸部', '#4FC3F7'],
      ['腿部', '#FF8A65'],
      ['腹部', '#AED581'],
      ['背部', '#FFD54F'],
      ['有氧', '#F06292'],
      ['拉伸', '#BA68C8']
    ]);
    let color: string | undefined = colorMap.get(this.category);
    return color !== undefined ? color : '#007DFF';
  }

  // 计算运动时长（分钟）
  private getDurationMinutes(): number {
    if (this.type === 'timer') {
      return Math.ceil((this.sets * this.duration) / 60);
    }
    return Math.ceil(this.sets * 2);
  }

  // 计算卡路里消耗（估算）
  private getCalories(): number {
    const durationMinutes: number = this.getDurationMinutes();
    const difficulty: string = this.getDifficulty();
    let met: number = 5; // 代谢当量
    if (difficulty === DifficultyLevel.Advanced) {
      met = 8;
    } else if (difficulty === DifficultyLevel.Intermediate) {
      met = 6;
    }
    return Math.round(met * durationMinutes * 70 / 60); // 假设体重70kg
  }

  build() {
    Column() {
      // 顶部图片区域
      this.HeaderSection();

      // 可滚动内容区域
      Scroll(this.scroller) {
        Column() {
          // 运动信息卡片
          this.InfoCard();

          // 参数详情卡片
          this.ParamsCard();

          // 动作描述卡片
          this.DescriptionCard();
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 24 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .backgroundColor('#F7FAFC')
    }
    .width('100%')
    .height('100%')
  }

  // 顶部图片区域
  @Builder
  HeaderSection(): void {
    Stack({ alignContent: Alignment.TopStart }) {
      // 运动大图背景
      Image(this.getExerciseImagePath())
        .width('100%')
        .height(280)
        .objectFit(ImageFit.Cover)
        .opacity(this.headerOpacity)

      // 渐变遮罩层
      Column()
        .width('100%')
        .height(280)
        .linearGradient({
          angle: 180,
          colors: [['#00000000', 0.0],
          ['#33000000', 0.5],
          ['#66000000', 1.0]]
        })
        .opacity(this.headerOpacity)

      // 顶部导航栏
      Row() {
        // 返回按钮
        Button() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(22)
            .fontColor([$r('sys.color.ohos_id_color_primary')])
        }
        .type(ButtonType.Circle)
        .width(44)
        .height(44)
        .backgroundColor('#33FFFFFF')
        .onClick(() => {
          router.back();
        })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      // 运动名称
      Column() {
        Text(this.name)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .textShadow({
            radius: 8,
            color: '#66000000',
            offsetX: 0,
            offsetY: 2
          })
      }
      .width('100%')
      .height(280)
      .justifyContent(FlexAlign.End)
      .padding({ bottom: 20, left: 16, right: 16 })
      .hitTestBehavior(HitTestMode.Transparent)
    }
    .width('100%')
    .height(280)
  }

  // 运动信息卡片
  @Builder
  InfoCard(): void {
    Column() {
      // 标签行
      Row() {
        Text(this.category)
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor(this.getCategoryColor())
          .borderRadius(16)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })

        Text(this.getTypeLabel())
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor('#4A5568')
          .borderRadius(16)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .margin({ left: 8 })

        Text(this.getDifficulty())
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor(this.getDifficultyColor())
          .borderRadius(16)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .margin({ left: 8 })
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 统计信息行
      Row() {
        // 时长
        Column() {
          Text(this.getDurationMinutes().toString())
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getCategoryColor())
          Text('预计时长(分钟)')
            .fontSize(12)
            .fontColor('#718096')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Divider()
          .vertical(true)
          .height(50)
          .color('#E2E8F0')

        // 卡路里
        Column() {
          Text(this.getCalories().toString())
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6B6B')
          Text('消耗卡路里(kcal)')
            .fontSize(12)
            .fontColor('#718096')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .padding(20)
    .margin({ top: 16 })
    .shadow({
      radius: 12,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 6
    })
  }

  // 参数详情卡片
  @Builder
  ParamsCard(): void {
    Column() {
      Text('参考参数')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A202C')
        .width('100%')
        .margin({ bottom: 16 })

      Row() {
        // 组数
        Column() {
          Column() {
            Text(this.sets.toString())
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#007DFF')
          }
          .width(60)
          .height(60)
          .backgroundColor('#EBF8FF')
          .borderRadius(30)
          .justifyContent(FlexAlign.Center)

          Text('推荐组数')
            .fontSize(13)
            .fontColor('#718096')
            .margin({ top: 8 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        // 次数/时长
        Column() {
          Column() {
            Text(this.type === 'timer' ? this.duration.toString() : this.reps.toString())
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#48BB78')
          }
          .width(60)
          .height(60)
          .backgroundColor('#F0FFF4')
          .borderRadius(30)
          .justifyContent(FlexAlign.Center)

          Text(this.type === 'timer' ? '每组时长(秒)' : '每组次数')
            .fontSize(13)
            .fontColor('#718096')
            .margin({ top: 8 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        // 休息时间
        Column() {
          Column() {
            Text('30')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#ED8936')
          }
          .width(60)
          .height(60)
          .backgroundColor('#FFFAF0')
          .borderRadius(30)
          .justifyContent(FlexAlign.Center)

          Text('组间休息(秒)')
            .fontSize(13)
            .fontColor('#718096')
            .margin({ top: 8 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .padding(20)
    .margin({ top: 16 })
    .shadow({
      radius: 12,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 6
    })
  }

  // 动作描述卡片
  @Builder
  DescriptionCard(): void {
    Column() {
      Text('动作描述')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A202C')
        .width('100%')
        .margin({ bottom: 12 })

      Text(this.description)
        .fontSize(15)
        .fontColor('#4A5568')
        .lineHeight(24)
        .width('100%')
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .padding(20)
    .margin({ top: 16 })
    .shadow({
      radius: 12,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 6
    })
  }

  // 颜色变亮辅助函数
  private lightenColor(color: string): string {
    if (color.startsWith('#')) {
      let hex: string = color.substring(1);
      let r: number = parseInt(hex.substring(0, 2), 16);
      let g: number = parseInt(hex.substring(2, 4), 16);
      let b: number = parseInt(hex.substring(4, 6), 16);

      r = Math.min(255, r + 40);
      g = Math.min(255, g + 40);
      b = Math.min(255, b + 40);

      let rHex: string = r.toString(16).padStart(2, '0');
      let gHex: string = g.toString(16).padStart(2, '0');
      let bHex: string = b.toString(16).padStart(2, '0');

      return '#' + rHex + gHex + bHex;
    }
    return color;
  }
}
