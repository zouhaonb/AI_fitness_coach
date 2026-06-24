// entry/src/main/ets/pages/TodayPlan.ets
import { router } from '@kit.ArkUI';
import { DatabaseService } from '../service/DatabaseService';
import { PlanService } from '../service/PlanService';
import { ConfigService } from '../service/ConfigService';
import { AIService } from '../service/AIService';
import { RecordModel, TodayTask } from '../model/ExerciseModel';
import { DayPlan, PlanExercise } from '../model/PlanModel';

@Entry
@Component
export struct TodayPlan {
  @Prop @Watch('onTabSwitch') activeTabIndex: number = 0;
  myTabIndex: number = 0;
  @State todayTasks: Array<TodayTask> = [];
  @State todayDate: string = '';
  @State isRestDay: boolean = false;
  @State completedCount: number = 0;
  @State isAllCompleted: boolean = false;
  @State encouragement: string = '正在为你生成今日寄语...';
  @StorageLink('dataVersion') @Watch('onDataChanged') dataVersion: number = 0;

  private updateCompletedCount(): void {
    if (!this.todayTasks || this.todayTasks.length === 0) {
      this.completedCount = 0;
      this.isAllCompleted = false;
      return;
    }
    let count: number = 0;
    for (let i: number = 0; i < this.todayTasks.length; i++) {
      let task: TodayTask = this.todayTasks[i];
      if (task && task.completed) {
        count++;
      }
    }
    this.completedCount = count;
    this.isAllCompleted = (count === this.todayTasks.length);
  }

  private getTaskDetail(task: TodayTask): string {
    if (!task) {
      return '';
    }
    if (task.type === 'timer') {
      return (task.sets ?? 0).toString() + '组 x ' + (task.duration ?? 0).toString() + '秒';
    }
    return (task.sets ?? 0).toString() + '组 x ' + (task.reps ?? 0).toString() + '次';
  }

  private getTodayDateStr(): string {
    let now: Date = new Date();
    let year: number = now.getFullYear();
    let month: number = now.getMonth() + 1;
    let day: number = now.getDate();
    let monthStr: string = month < 10 ? '0' + month.toString() : month.toString();
    let dayStr: string = day < 10 ? '0' + day.toString() : day.toString();
    return year.toString() + '-' + monthStr + '-' + dayStr;
  }

  private getWeekdayName(): string {
    let now: Date = new Date();
    let day: number = now.getDay();
    let names: Array<string> = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
    return names[day];
  }

  private getDisplayDate(): string {
    let now: Date = new Date();
    let year: number = now.getFullYear();
    let month: number = now.getMonth() + 1;
    let day: number = now.getDate();
    return year.toString() + '年' + month.toString() + '月' + day.toString() + '日 ' + this.getWeekdayName();
  }

  // 获取分类颜色
  private getCategoryColor(category: string): string {
    const colorMap: Map<string, string> = new Map([
      ['胸部', '#4FC3F7'],
      ['腿部', '#FF8A65'],
      ['腹部', '#AED581'],
      ['背部', '#FFD54F'],
      ['有氧', '#F06292'],
      ['拉伸', '#BA68C8']
    ]);
    let color: string | undefined = colorMap.get(category);
    return color !== undefined ? color : '#007DFF';
  }

  // 获取分类背景色（浅色）
  private getCategoryBgColor(category: string): string {
    const colorMap: Map<string, string> = new Map([
      ['胸部', '#EBF9FF'],
      ['腿部', '#FFF3EE'],
      ['腹部', '#F0F9E8'],
      ['背部', '#FFF8E1'],
      ['有氧', '#FDECF2'],
      ['拉伸', '#F3E8F9']
    ]);
    let color: string | undefined = colorMap.get(category);
    return color !== undefined ? color : '#EBF4FF';
  }

  private convertToTodayTask(exercise: PlanExercise, index: number): TodayTask {
    let task: TodayTask = new TodayTask();
    task.id = index + 1;
    task.exerciseId = exercise.exerciseId;
    task.name = exercise.name;
    task.category = exercise.categoryName;
    task.type = exercise.type;
    task.sets = exercise.sets;
    task.reps = exercise.reps;
    task.duration = exercise.duration;
    task.completed = false;
    return task;
  }

  aboutToAppear(): void {
    this.todayDate = this.getTodayDateStr();
    this.loadData();
  }

  onTabSwitch(): void {
    if (this.activeTabIndex === this.myTabIndex) {
      this.loadData();
    }
  }

  // 监听训练数据变化（ExerciseExecution 保存记录后会触发）
  onDataChanged(): void {
    this.loadData();
  }

  onPageShow(): void {
    this.loadData();
  }

  async loadData(): Promise<void> {
    try {
      let dayPlan: DayPlan = await PlanService.getTodayPlan();
      if (dayPlan.isRestDay || dayPlan.exercises.length === 0) {
        this.isRestDay = true;
        this.todayTasks = [];
        this.completedCount = 0;
        this.isAllCompleted = false;
        return;
      }

      this.isRestDay = false;
      let tasks: Array<TodayTask> = [];
      for (let i: number = 0; i < dayPlan.exercises.length; i++) {
        tasks.push(this.convertToTodayTask(dayPlan.exercises[i], i));
      }

      try {
        let records: Array<RecordModel> = await DatabaseService.getRecordsByDate(this.todayDate);
        for (let i: number = 0; i < tasks.length; i++) {
          for (let j: number = 0; j < records.length; j++) {
            if (records[j].exerciseId === tasks[i].exerciseId && records[j].completed) {
              tasks[i].completed = true;
              break;
            }
          }
        }
      } catch (dbErr) {
        console.error('getRecordsByDate failed');
      }

      this.todayTasks = tasks;
      this.updateCompletedCount();
      this.loadEncouragement();
    } catch (err) {
      console.error('loadData failed: ' + JSON.stringify(err));
      this.isRestDay = true;
      this.todayTasks = [];
      this.completedCount = 0;
      this.isAllCompleted = false;
    }
  }

  private async loadEncouragement(): Promise<void> {
    try {
      let streakDays: number = await DatabaseService.getStreakDays();
      let weekCount: number = await DatabaseService.getWeekCount();
      let totalMinutes: number = await DatabaseService.getTotalMinutes();
      let goal: string = 'keep_fit';
      try {
        let config = await ConfigService.getConfig();
        goal = config.goal;
      } catch (configErr) {
        console.error('getConfig for AI failed');
      }
      this.encouragement = await AIService.generateEncouragement(streakDays, weekCount, totalMinutes, goal);
    } catch (err) {
      console.error('loadEncouragement failed');
      this.encouragement = '坚持训练，你已经很棒了！';
    }
  }

  async markCompleted(task: TodayTask): Promise<void> {
    task.completed = !task.completed;
    if (task.completed) {
      try {
        let record: RecordModel = new RecordModel();
        record.exerciseId = task.exerciseId;
        record.exerciseName = task.name;
        record.date = this.todayDate;
        record.setsCompleted = task.sets;
        record.repsCompleted = task.type === 'count' ? task.reps * task.sets : 0;
        record.durationCompleted = task.type === 'timer' ? task.duration * task.sets : 0;
        record.completed = true;
        await DatabaseService.addRecord(record);
      } catch (err) {
        console.error('addRecord failed');
      }
    }
    // 强制触发 @State 数组刷新
    let refresh: Array<TodayTask> = [];
    for (let i: number = 0; i < this.todayTasks.length; i++) {
      refresh.push(this.todayTasks[i]);
    }
    this.todayTasks = refresh;
    this.updateCompletedCount();
  }

  build() {
    Column() {
      // 顶部标题栏
      this.TitleBar();

      if (this.isRestDay) {
        // 休息日页面
        this.RestDayView();
      } else {
        // 训练日页面
        Scroll() {
          Column() {
            // 日期与寄语卡片
            this.DateCard();

            // 进度卡片
            this.ProgressCard();

            // 任务卡片列表
            this.TaskList();

            // 全部完成提示
            if (this.isAllCompleted) {
              this.AllDoneCard();
            }
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180,
      colors: [['#F8FAFC', 0.0], ['#EEF2F7', 0.5], ['#E8EDF3', 1.0]]
    })
  }

  // 顶部标题栏
  @Builder
  TitleBar(): void {
    Row() {
      Text('今日计划')
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

  // 日期与寄语卡片
  @Builder
  DateCard(): void {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.calendar'))
          .fontSize(18)
          .fontColor(['#007DFF'])

        Text(this.getDisplayDate())
          .fontSize(15)
          .fontColor('#2D3748')
          .margin({ left: 8 })
      }
      .width('100%')

      Text(this.encouragement)
        .fontSize(14)
        .fontColor('#718096')
        .fontStyle(FontStyle.Italic)
        .margin({ top: 8 })
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('92%')
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .padding({ left: 20, right: 20, top: 18, bottom: 18 })
    .margin({ top: 8 })
    .shadow({
      radius: 16,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 6
    })
  }

  // 进度卡片
  @Builder
  ProgressCard(): void {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.flame'))
          .fontSize(18)
          .fontColor(['#FF6B6B'])

        Text('今日进度')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A202C')
          .margin({ left: 8 })

        Blank()

        Text(this.completedCount.toString() + '/' + (this.todayTasks ? this.todayTasks.length : 0).toString())
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#007DFF')
      }
      .width('100%')
      .margin({ bottom: 14 })

      // 进度条
      Progress({
        value: this.completedCount,
        total: this.todayTasks ? this.todayTasks.length : 0,
        type: ProgressType.Linear
      })
        .width('100%')
        .height(10)
        .color('#007DFF')
        .backgroundColor('#EDF2F7')
        .borderRadius(5)
    }
    .width('92%')
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .padding({ left: 20, right: 20, top: 20, bottom: 20 })
    .margin({ top: 16 })
    .shadow({
      radius: 16,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 6
    })
  }

  // 任务列表
  @Builder
  TaskList(): void {
    Column() {
      ForEach(this.todayTasks, (task: TodayTask) => {
        this.TaskCard(task)
      })
    }
    .width('92%')
    .margin({ top: 16 })
  }

  // 单个任务卡片
  @Builder
  TaskCard(task: TodayTask): void {
    Row() {
      // 左侧勾选圆圈
      Column() {
        if (task.completed) {
          SymbolGlyph($r('sys.symbol.checkmark'))
            .fontSize(14)
            .fontColor(['#FFFFFF'])
        }
      }
      .width(28)
      .height(28)
      .borderRadius(14)
      .backgroundColor(task.completed ? '#007DFF' : '#FFFFFF')
      .border({
        width: 2,
        color: task.completed ? '#007DFF' : '#CBD5E0',
        style: BorderStyle.Solid
      })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .margin({ right: 14 })
      .onClick(() => {
        this.markCompleted(task);
      })

      // 中间运动信息
      Column() {
        Text(task.name)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(task.completed ? '#A0AEC0' : '#1A202C')
          .decoration({
            type: task.completed ? TextDecorationType.LineThrough : TextDecorationType.None,
            color: task.completed ? '#A0AEC0' : '#000000'
          })

        Text(this.getTaskDetail(task))
          .fontSize(13)
          .fontColor('#718096')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 右侧部位标签
      Text(task.category)
        .fontSize(12)
        .fontColor(this.getCategoryColor(task.category))
        .backgroundColor(this.getCategoryBgColor(task.category))
        .borderRadius(12)
        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 18, bottom: 18 })
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ bottom: 12 })
    .shadow({
      radius: 12,
      color: task.completed ? '#0A000000' : '#1A000000',
      offsetX: 0,
      offsetY: 4
    })
    .opacity(task.completed ? 0.75 : 1.0)
    .onClick(() => {
      router.pushUrl({
        url: 'pages/ExerciseExecution',
        params: {
          id: (task.exerciseId ?? 0).toString(),
          name: task.name ?? '',
          sets: (task.sets ?? 0).toString(),
          reps: (task.reps ?? 0).toString(),
          duration: (task.duration ?? 0).toString(),
          type: task.type ?? 'count'
        }
      });
    })
  }

  // 全部完成卡片
  @Builder
  AllDoneCard(): void {
    Column() {
      Text('🎉')
        .fontSize(40)
        .margin({ bottom: 12 })

      Text('今日训练全部完成！')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A202C')

      Text('太棒了，继续保持！')
        .fontSize(14)
        .fontColor('#718096')
        .margin({ top: 8 })
    }
    .width('92%')
    .padding({ top: 32, bottom: 32 })
    .margin({ top: 8, bottom: 24 })
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .shadow({
      radius: 16,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 6
    })
  }

  // 休息日视图
  @Builder
  RestDayView(): void {
    Column() {
      Column() {
        // 日期信息
        Row() {
          SymbolGlyph($r('sys.symbol.calendar'))
            .fontSize(18)
            .fontColor(['#007DFF'])

          Text(this.getDisplayDate())
            .fontSize(15)
            .fontColor('#2D3748')
            .margin({ left: 8 })
        }
        .width('100%')
        .margin({ bottom: 24 })

        Text('😴')
          .fontSize(64)
          .margin({ bottom: 16 })

        Text('休息日')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A202C')

        Text('今天好好休息，明天继续加油！')
          .fontSize(14)
          .fontColor('#718096')
          .margin({ top: 8 })

        Button('查看训练计划')
          .width('60%')
          .height(48)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .backgroundColor('#007DFF')
          .borderRadius(24)
          .margin({ top: 32 })
          .shadow({
            radius: 12,
            color: '#33007DFF',
            offsetX: 0,
            offsetY: 4
          })
          .onClick(() => {
            router.pushUrl({ url: 'pages/PlanSetting' });
          })
      }
      .width('92%')
      .padding({ top: 40, bottom: 40, left: 24, right: 24 })
      .backgroundColor('#FFFFFF')
      .borderRadius(24)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .shadow({
        radius: 20,
        color: '#1A000000',
        offsetX: 0,
        offsetY: 8
      })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
