// entry/src/main/ets/pages/ExerciseLibrary.ets
import { router } from '@kit.ArkUI';
import { DatabaseService } from '../service/DatabaseService';
import { ExerciseModel } from '../model/ExerciseModel';

// 难度等级枚举
class DifficultyLevel {
  static readonly Beginner: string = '初级';
  static readonly Intermediate: string = '中级';
  static readonly Advanced: string = '高级';
}

@Entry
@Component
export struct ExerciseLibrary {
  // 状态管理
  @State searchKeyword: string = '';
  @State selectedCategory: string = 'all';
  @State exerciseList: Array<ExerciseModel> = [];
  @State isSearching: boolean = false;
  @State cardScale: Map<number, number> = new Map();
  @State cardOpacity: Map<number, number> = new Map();

  // 分类标签数据
  private categoryTags: Array<string[]> = [
    ['all', '全部'],
    ['chest', '胸部'],
    ['leg', '腿部'],
    ['abs', '腹部'],
    ['back', '背部'],
    ['cardio', '有氧'],
    ['stretch', '拉伸']
  ];

  // Scroller控制器
  private categoryScroller: Scroller = new Scroller();
  private listScroller: Scroller = new Scroller();

  // 生命周期函数
  async aboutToAppear(): Promise<void> {
    try {
      this.exerciseList = await DatabaseService.getAllExercises();
      // 初始化卡片动画状态
      this.exerciseList.forEach((item: ExerciseModel) => {
        this.cardScale.set(item.id, 1.0);
        this.cardOpacity.set(item.id, 1.0);
      });
    } catch (err) {
      console.error('ExerciseLibrary loadExercises failed: ' + JSON.stringify(err));
    }
  }

  // 过滤运动列表
  private getFilteredExercises(): Array<ExerciseModel> {
    let result: Array<ExerciseModel> = this.exerciseList;
    if (this.selectedCategory !== 'all') {
      result = result.filter((item: ExerciseModel) => item.category === this.selectedCategory);
    }
    if (this.searchKeyword !== '') {
      result = result.filter((item: ExerciseModel) => item.name.includes(this.searchKeyword));
    }
    return result;
  }

  // 获取难度等级（模拟数据）
  private getDifficulty(exercise: ExerciseModel): string {
    if (exercise.defaultSets >= 5 && exercise.defaultReps >= 20) {
      return DifficultyLevel.Advanced;
    } else if (exercise.defaultSets >= 3 && exercise.defaultReps >= 15) {
      return DifficultyLevel.Intermediate;
    }
    return DifficultyLevel.Beginner;
  }

  // 获取难度颜色
  private getDifficultyColor(difficulty: string): string {
    if (difficulty === DifficultyLevel.Advanced) {
      return '#FF6B6B';
    } else if (difficulty === DifficultyLevel.Intermediate) {
      return '#FFA94D';
    }
    return '#69DB7C';
  }

  // 获取运动图片路径
  private getExerciseImagePath(exercise: ExerciseModel): string | Resource {
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
    let fileName: string | undefined = nameMap.get(exercise.name);
    if (fileName !== undefined) {
      return 'resource://RAWFILE/exercises/' + exercise.category + '/' + fileName + '.png';
    }
    // 占位图在 media 目录，使用 $r 引用
    return $r('app.media.exercise_placeholder');
  }

  // 获取分类颜色
  private getCategoryColor(categoryName: string): string {
    const colorMap: Map<string, string> = new Map([
      ['胸部', '#4FC3F7'],
      ['腿部', '#FF8A65'],
      ['腹部', '#AED581'],
      ['背部', '#FFD54F'],
      ['有氧', '#F06292'],
      ['拉伸', '#BA68C8']
    ]);
    let color: string | undefined = colorMap.get(categoryName);
    return color !== undefined ? color : '#007DFF';
  }

  // 计算运动时长（分钟）
  private getDuration(exercise: ExerciseModel): number {
    if (exercise.type === 'timer') {
      return Math.ceil((exercise.defaultSets * exercise.defaultDuration) / 60);
    }
    return Math.ceil(exercise.defaultSets * 2); // 假设每组约2分钟
  }

  // 卡片点击动画
  private onCardClick(exercise: ExerciseModel): void {
    // 缩小动画
    animateTo({
      duration: 100,
      curve: Curve.EaseOut
    }, () => {
      this.cardScale.set(exercise.id, 0.95);
      this.cardOpacity.set(exercise.id, 0.8);
    });

    // 恢复动画并跳转
    setTimeout(() => {
      animateTo({
        duration: 100,
        curve: Curve.EaseIn
      }, () => {
        this.cardScale.set(exercise.id, 1.0);
        this.cardOpacity.set(exercise.id, 1.0);
      });

      // 跳转到详情页
      router.pushUrl({
        url: 'pages/ExerciseDetail',
        params: {
          id: exercise.id.toString(),
          name: exercise.name,
          category: exercise.categoryName,
          description: exercise.description,
          type: exercise.type,
          sets: exercise.defaultSets.toString(),
          reps: exercise.defaultReps.toString(),
          duration: exercise.defaultDuration.toString()
        }
      });
    }, 100);
  }

  build() {
    Column() {
      // 顶部标题栏
      this.TitleBar();

      // 搜索栏
      this.SearchBar();

      // 分类标签栏
      this.CategoryTabs();

      // 运动卡片网格
      this.ExerciseGrid();
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180,
      colors: [['#F8FAFC', 0.0], ['#EEF2F7', 0.5], ['#E8EDF3', 1.0]]
    })
  }

  // 顶部标题栏组件
  @Builder
  TitleBar(): void {
    Row() {
      Text('运动库')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A202C')
        .letterSpacing(1)
    }
    .width('100%')
    .height(56)
    .padding({ left: 20, right: 20 })
    .alignItems(VerticalAlign.Center)
  }

  // 搜索栏组件
  @Builder
  SearchBar(): void {
    Row() {
      // 搜索图标
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(20)
        .fontColor([$r('sys.color.ohos_id_color_secondary')])
        .margin({ left: 16 })

      // 搜索输入框
      TextInput({ placeholder: '搜索运动项目...', text: this.searchKeyword })
        .layoutWeight(1)
        .height(44)
        .backgroundColor(Color.Transparent)
        .placeholderColor('#A0AEC0')
        .placeholderFont({ size: 15 })
        .fontColor('#2D3748')
        .fontSize(15)
        .caretColor('#007DFF')
        .onChange((value: string) => {
          this.searchKeyword = value;
          this.isSearching = value.length > 0;
        })

      // 清除按钮
      if (this.isSearching) {
        Button() {
          SymbolGlyph($r('sys.symbol.xmark_circle_fill'))
            .fontSize(18)
            .fontColor([$r('sys.color.ohos_id_color_secondary')])
        }
        .type(ButtonType.Circle)
        .width(32)
        .height(32)
        .backgroundColor('#EDF2F7')
        .margin({ right: 8 })
        .onClick(() => {
          this.searchKeyword = '';
          this.isSearching = false;
        })
      }
    }
    .width('92%')
    .height(52)
    .margin({ top: 8, bottom: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(26)
    .shadow({
      radius: 12,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 4
    })
  }

  // 分类标签栏组件
  @Builder
  CategoryTabs(): void {
    Scroll(this.categoryScroller) {
      Row({ space: 8 }) {
        ForEach(this.categoryTags, (tag: string[]) => {
          Column() {
            Text(tag[1])
              .fontSize(15)
              .fontWeight(this.selectedCategory === tag[0] ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.selectedCategory === tag[0] ? '#FFFFFF' : '#4A5568')
              .padding({ left: 20, right: 20, top: 10, bottom: 10 })
              .backgroundColor(this.selectedCategory === tag[0] ? '#007DFF' : '#FFFFFF')
              .borderRadius(20)
              .shadow(this.selectedCategory === tag[0] ? {
                radius: 12,
                color: '#33007DFF',
                offsetX: 0,
                offsetY: 4
              } : {
                radius: 4,
                color: '#0A000000',
                offsetX: 0,
                offsetY: 1
              })
              .onClick(() => {
                animateTo({
                  duration: 200,
                  curve: Curve.EaseInOut
                }, () => {
                  this.selectedCategory = tag[0];
                });
              })
          }
        })
      }
      .padding({ left: 16, right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .height(60)
    .edgeEffect(EdgeEffect.Spring)
  }

  // 运动卡片网格组件
  @Builder
  ExerciseGrid(): void {
    Scroll(this.listScroller) {
      Grid() {
        ForEach(this.getFilteredExercises(), (item: ExerciseModel) => {
          GridItem() {
            this.ExerciseCard(item);
          }
        })
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(16)
      .columnsGap(16)
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 24 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  // 运动卡片组件
  @Builder
  ExerciseCard(exercise: ExerciseModel): void {
    Column() {
      // 卡片顶部图片区域
      Stack({ alignContent: Alignment.TopEnd }) {
        // 渐变背景
        Column()
          .width('100%')
          .height(120)
          .linearGradient({
            angle: 135,
            colors: [[this.getCategoryColor(exercise.categoryName), 0.0],
            [this.lightenColor(this.getCategoryColor(exercise.categoryName)), 1.0]]
          })
          .borderRadius({ topLeft: 20, topRight: 20, bottomLeft: 0, bottomRight: 0 })

        // 运动图标
        Column() {
          Image(this.getExerciseImagePath(exercise))
            .width(80)
            .height(80)
            .objectFit(ImageFit.Contain)
        }
        .width('100%')
        .height(120)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        // 难度标签
        Text(this.getDifficulty(exercise))
          .fontSize(11)
          .fontColor('#FFFFFF')
          .backgroundColor(this.getDifficultyColor(this.getDifficulty(exercise)))
          .borderRadius(12)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .margin({ top: 8, right: 8 })
      }

      // 卡片内容区域
      Column() {
        // 运动名称
        Text(exercise.name)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A202C')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        // 分类标签
        Row() {
          Text(exercise.categoryName)
            .fontSize(12)
            .fontColor('#718096')
        }
        .width('100%')
        .margin({ top: 4 })

        // 底部信息栏
        Row() {
          // 时长信息
          Row() {
            SymbolGlyph($r('sys.symbol.clock'))
              .fontSize(14)
              .fontColor([$r('sys.color.ohos_id_color_secondary')])
            Text(this.getDuration(exercise).toString() + '分钟')
              .fontSize(12)
              .fontColor('#718096')
              .margin({ left: 4 })
          }

          Blank();

          // 组数信息
          Row() {
            SymbolGlyph($r('sys.symbol.repeat'))
              .fontSize(14)
              .fontColor([$r('sys.color.ohos_id_color_secondary')])
            Text(exercise.defaultSets.toString() + '组')
              .fontSize(12)
              .fontColor('#718096')
              .margin({ left: 4 })
          }
        }
        .width('100%')
        .margin({ top: 12 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 16 })
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 0, topRight: 0, bottomLeft: 20, bottomRight: 20 })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .shadow({
      radius: 16,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 8
    })
    .scale({
      x: this.cardScale.get(exercise.id) !== undefined ? this.cardScale.get(exercise.id) : 1.0,
      y: this.cardScale.get(exercise.id) !== undefined ? this.cardScale.get(exercise.id) : 1.0
    })
    .opacity(this.cardOpacity.get(exercise.id) !== undefined ? this.cardOpacity.get(exercise.id) : 1.0)
    .onClick(() => {
      this.onCardClick(exercise);
    })
  }

  // 颜色变亮辅助函数
  private lightenColor(color: string): string {
    // 简化的颜色变亮逻辑
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
