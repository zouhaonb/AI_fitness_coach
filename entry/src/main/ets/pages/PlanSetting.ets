// entry/src/main/ets/pages/PlanSetting.ets
import { router } from '@kit.ArkUI';
import { ConfigService } from '../service/ConfigService';
import { PlanService } from '../service/PlanService';
import { WeeklyPlan, DayPlan, PlanExercise } from '../model/PlanModel';

class GoalOption {
  key: string = '';
  title: string = '';
  icon: string = '';
  description: string = '';
}

class ExercisePoolItem {
  exerciseId: number = 0;
  name: string = '';
  category: string = '';
  categoryName: string = '';
  type: string = '';
  defaultSets: number = 0;
  defaultReps: number = 0;
  defaultDuration: number = 0;
}

@Entry
@Component
struct PlanSetting {
  @State selectedGoal: string = 'lose_fat';
  @State selectedFrequency: number = 5;
  @State weeklyPlan: WeeklyPlan = new WeeklyPlan();
  @State editingDayIndex: number = -1;
  @State showAddExercise: boolean = false;

  private goalOptions: Array<GoalOption> = [
    { key: 'lose_fat', title: '减脂', icon: '🔥', description: '侧重有氧，短间歇' },
    { key: 'gain_muscle', title: '增肌', icon: '💪', description: '侧重力量，高组数' },
    { key: 'keep_fit', title: '保持健康', icon: '❤️', description: '均衡搭配' }
  ];

  private frequencyOptions: Array<number> = [3, 4, 5, 6, 7];

  private allExercises: Array<ExercisePoolItem> = [
    { exerciseId: 1, name: '俯卧撑', category: 'chest', categoryName: '胸部', type: 'count', defaultSets: 3, defaultReps: 15, defaultDuration: 0 },
    { exerciseId: 2, name: '哑铃飞鸟', category: 'chest', categoryName: '胸部', type: 'count', defaultSets: 3, defaultReps: 12, defaultDuration: 0 },
    { exerciseId: 3, name: '深蹲', category: 'leg', categoryName: '腿部', type: 'count', defaultSets: 4, defaultReps: 20, defaultDuration: 0 },
    { exerciseId: 4, name: '弓步蹲', category: 'leg', categoryName: '腿部', type: 'count', defaultSets: 3, defaultReps: 12, defaultDuration: 0 },
    { exerciseId: 5, name: '靠墙静蹲', category: 'leg', categoryName: '腿部', type: 'timer', defaultSets: 3, defaultReps: 0, defaultDuration: 30 },
    { exerciseId: 6, name: '仰卧起坐', category: 'abs', categoryName: '腹部', type: 'count', defaultSets: 3, defaultReps: 20, defaultDuration: 0 },
    { exerciseId: 7, name: '平板支撑', category: 'abs', categoryName: '腹部', type: 'timer', defaultSets: 3, defaultReps: 0, defaultDuration: 45 },
    { exerciseId: 8, name: '卷腹', category: 'abs', categoryName: '腹部', type: 'count', defaultSets: 3, defaultReps: 15, defaultDuration: 0 },
    { exerciseId: 9, name: '引体向上', category: 'back', categoryName: '背部', type: 'count', defaultSets: 3, defaultReps: 10, defaultDuration: 0 },
    { exerciseId: 10, name: '俯身划船', category: 'back', categoryName: '背部', type: 'count', defaultSets: 3, defaultReps: 12, defaultDuration: 0 },
    { exerciseId: 11, name: '开合跳', category: 'cardio', categoryName: '有氧', type: 'timer', defaultSets: 3, defaultReps: 0, defaultDuration: 30 },
    { exerciseId: 12, name: '高抬腿', category: 'cardio', categoryName: '有氧', type: 'timer', defaultSets: 3, defaultReps: 0, defaultDuration: 30 },
    { exerciseId: 13, name: '波比跳', category: 'cardio', categoryName: '有氧', type: 'count', defaultSets: 3, defaultReps: 10, defaultDuration: 0 },
    { exerciseId: 14, name: '跳绳', category: 'cardio', categoryName: '有氧', type: 'timer', defaultSets: 3, defaultReps: 0, defaultDuration: 60 },
    { exerciseId: 15, name: '颈部拉伸', category: 'stretch', categoryName: '拉伸', type: 'timer', defaultSets: 2, defaultReps: 0, defaultDuration: 20 },
    { exerciseId: 16, name: '体前屈', category: 'stretch', categoryName: '拉伸', type: 'timer', defaultSets: 2, defaultReps: 0, defaultDuration: 30 },
    { exerciseId: 17, name: '肩部拉伸', category: 'stretch', categoryName: '拉伸', type: 'timer', defaultSets: 2, defaultReps: 0, defaultDuration: 20 },
    { exerciseId: 18, name: '全身拉伸', category: 'stretch', categoryName: '拉伸', type: 'timer', defaultSets: 2, defaultReps: 0, defaultDuration: 30 }
  ];

  async aboutToAppear(): Promise<void> {
    try {
      let config = await ConfigService.getConfig();
      this.selectedGoal = config.goal;
      this.selectedFrequency = config.frequency;
    } catch (err) {
      console.error('PlanSetting loadConfig failed');
    }

    try {
      let saved: WeeklyPlan | null = await PlanService.getWeeklyPlan();
      if (saved !== null) {
        this.weeklyPlan = saved;
      } else {
        this.weeklyPlan = PlanService.generateDefaultPlan(this.selectedGoal, this.selectedFrequency);
      }
    } catch (err) {
      this.weeklyPlan = PlanService.generateDefaultPlan(this.selectedGoal, this.selectedFrequency);
    }
  }

  @Watch('onGoalOrFreqChanged')
  @State watchGoal: number = 0;

  private onGoalOrFreqChanged(): void {
    this.weeklyPlan = PlanService.generateDefaultPlan(this.selectedGoal, this.selectedFrequency);
    this.editingDayIndex = -1;
  }

  private getExerciseDetail(ex: PlanExercise): string {
    if (ex.type === 'timer') {
      return ex.sets.toString() + '组 × ' + ex.duration.toString() + '秒';
    }
    return ex.sets.toString() + '组 × ' + ex.reps.toString() + '次';
  }

  private getDaySummary(day: DayPlan): string {
    if (day.isRestDay || day.exercises.length === 0) {
      return '休息日';
    }
    let names: Array<string> = [];
    for (let i: number = 0; i < day.exercises.length; i++) {
      names.push(day.exercises[i].name);
    }
    return names.join('、');
  }

  private removeExerciseById(dayIdx: number, exerciseId: number): void {
    let updated: Array<PlanExercise> = [];
    let exercises: Array<PlanExercise> = this.weeklyPlan.days[dayIdx].exercises;
    let removed: boolean = false;
    for (let i: number = 0; i < exercises.length; i++) {
      if (exercises[i].exerciseId === exerciseId && !removed) {
        removed = true;
        continue;
      }
      updated.push(exercises[i]);
    }
    this.weeklyPlan.days[dayIdx].exercises = updated;
    this.forceUpdate();
  }

  private toggleRestDay(dayIdx: number): void {
    let currentRest: boolean = this.weeklyPlan.days[dayIdx].isRestDay;
    this.weeklyPlan.days[dayIdx].isRestDay = !currentRest;
    if (!currentRest) {
      this.weeklyPlan.days[dayIdx].exercises = [];
    } else {
      let defaultPlan: WeeklyPlan = PlanService.generateDefaultPlan(this.selectedGoal, this.selectedFrequency);
      this.weeklyPlan.days[dayIdx].exercises = defaultPlan.days[dayIdx].exercises;
    }
    this.forceUpdate();
  }

  private forceUpdate(): void {
    let temp: WeeklyPlan = this.weeklyPlan;
    this.weeklyPlan = new WeeklyPlan();
    this.weeklyPlan = temp;
  }

  private isExerciseAdded(dayIdx: number, exerciseId: number): boolean {
    let exercises: Array<PlanExercise> = this.weeklyPlan.days[dayIdx].exercises;
    for (let i: number = 0; i < exercises.length; i++) {
      if (exercises[i].exerciseId === exerciseId) {
        return true;
      }
    }
    return false;
  }

  private addExercise(dayIdx: number, poolItem: ExercisePoolItem): void {
    let ex: PlanExercise = new PlanExercise();
    ex.exerciseId = poolItem.exerciseId;
    ex.name = poolItem.name;
    ex.category = poolItem.category;
    ex.categoryName = poolItem.categoryName;
    ex.type = poolItem.type;
    ex.sets = poolItem.defaultSets;
    ex.reps = poolItem.defaultReps;
    ex.duration = poolItem.defaultDuration;
    let updated: Array<PlanExercise> = [];
    let exercises: Array<PlanExercise> = this.weeklyPlan.days[dayIdx].exercises;
    for (let i: number = 0; i < exercises.length; i++) {
      updated.push(exercises[i]);
    }
    updated.push(ex);
    this.weeklyPlan.days[dayIdx].exercises = updated;
    this.forceUpdate();
  }

  @Builder
  buildDayEditor(dayIdx: number) {
    Column() {
      // 休息日开关
      Row() {
        Text('设为休息日')
          .fontSize(14)
          .fontColor('#333333')

        Toggle({ type: ToggleType.Switch, isOn: this.weeklyPlan.days[dayIdx].isRestDay })
          .margin({ left: 'auto' })
          .onChange((isOn: boolean) => {
            this.toggleRestDay(dayIdx);
          })
      }
      .width('100%')
      .padding({ bottom: 12 })

      if (!this.weeklyPlan.days[dayIdx].isRestDay) {
        // 运动列表
        ForEach(this.weeklyPlan.days[dayIdx].exercises, (ex: PlanExercise) => {
          Row() {
            Column() {
              Text(ex.name)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
              Text(this.getExerciseDetail(ex))
                .fontSize(12)
                .fontColor('#999999')
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text('×')
              .fontSize(20)
              .fontColor('#FF4444')
              .padding(8)
              .onClick(() => {
                this.removeExerciseById(dayIdx, ex.exerciseId);
              })
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 })
          .border({ width: { bottom: 1 }, color: '#F0F0F0' })
        })

        // 添加运动按钮
        Button('＋ 添加运动')
          .width('100%')
          .height(36)
          .fontSize(14)
          .fontColor('#007DFF')
          .backgroundColor('#E6F0FF')
          .borderRadius(8)
          .margin({ top: 12 })
          .onClick(() => {
            this.showAddExercise = true;
          })
      }

      // 完成编辑按钮
      Button('完成编辑')
        .width('100%')
        .height(40)
        .fontSize(14)
        .fontColor('#FFFFFF')
        .backgroundColor('#007DFF')
        .borderRadius(8)
        .margin({ top: 12 })
        .onClick(() => {
          this.editingDayIndex = -1;
          this.showAddExercise = false;
        })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#F8F9FA')
    .borderRadius(8)
    .margin({ top: 8 })
  }

  @Builder
  buildAddExerciseDialog(dayIdx: number) {
    Column() {
      Row() {
        Text('添加运动')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Text('关闭')
          .fontSize(14)
          .fontColor('#007DFF')
          .margin({ left: 'auto' })
          .onClick(() => {
            this.showAddExercise = false;
          })
      }
      .width('100%')
      .padding({ bottom: 12 })

      ForEach(this.allExercises, (item: ExercisePoolItem) => {
        Row() {
          Column() {
            Text(item.name)
              .fontSize(14)
              .fontColor(this.isExerciseAdded(dayIdx, item.exerciseId) ? '#CCCCCC' : '#333333')
            Text(item.categoryName + ' · ' + item.type)
              .fontSize(12)
              .fontColor(this.isExerciseAdded(dayIdx, item.exerciseId) ? '#CCCCCC' : '#999999')
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ top: 10, bottom: 10 })
        .border({ width: { bottom: 1 }, color: '#F0F0F0' })
        .opacity(this.isExerciseAdded(dayIdx, item.exerciseId) ? 0.5 : 1.0)
        .onClick(() => {
          if (!this.isExerciseAdded(dayIdx, item.exerciseId)) {
            this.addExercise(dayIdx, item);
            this.showAddExercise = false;
          }
        })
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ top: 8 })
  }

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
        Text('训练计划设置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ left: 8 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#FFFFFF')

      // 可滚动内容区域
      Scroll() {
        Column() {
          // 训练目标选择
          Column() {
            Text('选择训练目标')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .margin({ bottom: 12 })

            Row() {
              ForEach(this.goalOptions, (option: GoalOption) => {
                Column() {
                  Text(option.icon)
                    .fontSize(32)
                    .margin({ bottom: 6 })

                  Text(option.title)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.selectedGoal === option.key ? '#007DFF' : '#333333')

                  Text(option.description)
                    .fontSize(12)
                    .fontColor('#999999')
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Center)
                .padding({ top: 16, bottom: 16 })
                .borderRadius(12)
                .backgroundColor(this.selectedGoal === option.key ? '#E6F0FF' : '#FFFFFF')
                .border({
                  width: this.selectedGoal === option.key ? 2 : 1,
                  color: this.selectedGoal === option.key ? '#007DFF' : '#EEEEEE',
                  style: BorderStyle.Solid
                })
                .margin({ left: 4, right: 4 })
                .onClick(() => {
                  this.selectedGoal = option.key;
                  this.watchGoal++;
                })
              })
            }
            .width('100%')
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .padding(16)
          .margin({ top: 12, left: 12, right: 12 })

          // 训练频率选择
          Column() {
            Text('每周训练天数')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .margin({ bottom: 12 })

            Row() {
              ForEach(this.frequencyOptions, (day: number) => {
                Text(day.toString() + '天')
                  .fontSize(14)
                  .fontColor(this.selectedFrequency === day ? '#FFFFFF' : '#333333')
                  .backgroundColor(this.selectedFrequency === day ? '#007DFF' : '#F5F5F5')
                  .borderRadius(8)
                  .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                  .margin({ left: 4, right: 4 })
                  .onClick(() => {
                    this.selectedFrequency = day;
                    this.watchGoal++;
                  })
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceAround)
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .padding(16)
          .margin({ top: 12, left: 12, right: 12 })

          // 周计划预览
          Column() {
            Text('本周训练计划')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .margin({ bottom: 12 })

            ForEach(this.weeklyPlan.days, (day: DayPlan, dayIdx: number) => {
              Column() {
                // 日期行
                Row() {
                  Text(day.dayName)
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(day.isRestDay ? '#CCCCCC' : '#333333')
                    .width(50)

                  Text(this.getDaySummary(day))
                    .fontSize(13)
                    .fontColor(day.isRestDay ? '#CCCCCC' : '#666666')
                    .layoutWeight(1)
                    .maxLines(2)

                  Text('编辑')
                    .fontSize(13)
                    .fontColor('#007DFF')
                    .margin({ left: 8 })
                    .onClick(() => {
                      if (this.editingDayIndex === dayIdx) {
                        this.editingDayIndex = -1;
                        this.showAddExercise = false;
                      } else {
                        this.editingDayIndex = dayIdx;
                        this.showAddExercise = false;
                      }
                    })
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)

                // 编辑区域（内联）
                if (this.editingDayIndex === dayIdx) {
                  this.buildDayEditor(dayIdx)
                }
              }
              .width('100%')
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .border(day.isRestDay ? { width: { left: 3 }, color: '#EEEEEE' } : { width: { left: 3 }, color: '#007DFF' })
              .margin({ bottom: 4 })
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .padding(16)
          .margin({ top: 12, left: 12, right: 12 })

          // 添加运动弹窗（条件渲染）
          if (this.showAddExercise && this.editingDayIndex >= 0) {
            this.buildAddExerciseDialog(this.editingDayIndex)
          }

          // 底部留白
          Column()
            .height(80)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      // 底部保存按钮
      Button('保存计划')
        .width('90%')
        .height(48)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor('#007DFF')
        .borderRadius(24)
        .margin({ bottom: 20 })
        .onClick(async () => {
          try {
            await PlanService.saveWeeklyPlan(this.weeklyPlan);
            await ConfigService.saveGoal(this.selectedGoal);
            await ConfigService.saveFrequency(this.selectedFrequency);
            AlertDialog.show({
              title: '提示',
              message: '计划已保存',
              confirm: {
                value: '确定',
                action: () => {
                  console.info('Plan saved');
                }
              }
            });
          } catch (err) {
            console.error('Save plan failed: ' + JSON.stringify(err));
          }
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
