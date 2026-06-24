// entry/src/main/ets/pages/Statistics.ets
import { DatabaseService } from '../service/DatabaseService';
import { ConfigService } from '../service/ConfigService';
import { AIService } from '../service/AIService';
import { PieData, HistoryRecord } from '../model/ExerciseModel';

class CalendarDay {
  day: number = 0;
  isChecked: boolean = false;
  isToday: boolean = false;
  isEmpty: boolean = false;
}

@Entry
@Component
export struct Statistics {
  @Prop @Watch('onTabSwitch') activeTabIndex: number = 0;
  myTabIndex: number = 0;
  @State checkedDays: Array<number> = [];
  @State pieDataList: Array<PieData> = [];
  @State historyList: Array<HistoryRecord> = [];
  @State streakDays: number = 0;
  @State weekCount: number = 0;
  @State monthMinutes: number = 0;
  @State totalCheckedDays: number = 0;
  @StorageLink('dataVersion') @Watch('onDataChanged') dataVersion: number = 0;
  @State aiAdvice: string = '';
  @State aiLoading: boolean = false;
  @State cardScale: number = 1.0;

  private weekLabels: Array<string> = ['一', '二', '三', '四', '五', '六', '日'];
  private scroller: Scroller = new Scroller();

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private pieContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  private getCurrentYearMonth(): string {
    let now: Date = new Date();
    let year: number = now.getFullYear();
    let month: number = now.getMonth() + 1;
    let monthStr: string = month < 10 ? '0' + month.toString() : month.toString();
    return year.toString() + '-' + monthStr;
  }

  private getMonthTitle(): string {
    let now: Date = new Date();
    let year: number = now.getFullYear();
    let month: number = now.getMonth() + 1;
    return year.toString() + '年' + month.toString() + '月';
  }

  private getFirstDayOffset(): number {
    let now: Date = new Date();
    let firstDay: Date = new Date(now.getFullYear(), now.getMonth(), 1);
    let day: number = firstDay.getDay();
    if (day === 0) {
      day = 7;
    }
    return day - 1;
  }

  private getTotalDays(): number {
    let now: Date = new Date();
    return new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
  }

  private getToday(): number {
    return new Date().getDate();
  }

  private getCalendarDays(): Array<CalendarDay> {
    let days: Array<CalendarDay> = [];
    let firstDayOffset: number = this.getFirstDayOffset();
    let totalDays: number = this.getTotalDays();
    let today: number = this.getToday();
    for (let i: number = 0; i < firstDayOffset; i++) {
      let emptyDay: CalendarDay = new CalendarDay();
      emptyDay.isEmpty = true;
      days.push(emptyDay);
    }
    for (let d: number = 1; d <= totalDays; d++) {
      let calendarDay: CalendarDay = new CalendarDay();
      calendarDay.day = d;
      calendarDay.isChecked = this.checkedDays.includes(d);
      calendarDay.isToday = d === today;
      days.push(calendarDay);
    }
    return days;
  }

  @Builder
  buildDayCell(item: CalendarDay) {
    Column() {
      if (!item.isEmpty) {
        Stack() {
          // 日期数字
          Text(item.day.toString())
            .fontSize(14)
            .fontColor(item.isToday ? '#FFFFFF' : '#2D3748')
            .fontWeight(item.isToday ? FontWeight.Bold : FontWeight.Normal)
            .zIndex(1)

          // 今日标记圆圈
          if (item.isToday) {
            Column()
              .width(30)
              .height(30)
              .borderRadius(15)
              .linearGradient({
                angle: 135,
                colors: [['#667EEA', 0.0], ['#764BA2', 1.0]]
              })
          }

          // 打卡标记
          if (item.isChecked) {
            Column()
              .width(6)
              .height(6)
              .borderRadius(3)
              .backgroundColor('#69DB7C')
              .margin({ top: 22 })
          }
        }
        .width(38)
        .height(38)
        .alignContent(Alignment.Center)
      }
    }
    .width('100%')
    .height(42)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  aboutToAppear(): void {
    this.loadData();
  }

  onTabSwitch(): void {
    if (this.activeTabIndex === this.myTabIndex) {
      this.loadData();
    }
  }

  // 监听训练数据变化
  onDataChanged(): void {
    console.info(`[Statistics] Data changed, version: ${this.dataVersion}`);
    this.loadData();
  }

  async loadData(): Promise<void> {
    let yearMonth: string = this.getCurrentYearMonth();
    try {
      this.checkedDays = await DatabaseService.getCheckedDays(yearMonth);
    } catch (err) {
      console.error('getCheckedDays failed');
    }
    try {
      this.streakDays = await DatabaseService.getStreakDays();
    } catch (err) {
      console.error('getStreakDays failed');
    }
    try {
      this.weekCount = await DatabaseService.getWeekCount();
    } catch (err) {
      console.error('getWeekCount failed');
    }
    try {
      this.monthMinutes = await DatabaseService.getMonthTotalMinutes(yearMonth);
    } catch (err) {
      console.error('getMonthTotalMinutes failed');
    }
    try {
      this.totalCheckedDays = await DatabaseService.getTotalCheckedDays();
    } catch (err) {
      console.error('getTotalCheckedDays failed');
    }
    try {
      this.pieDataList = await DatabaseService.getCategoryDistribution();
    } catch (err) {
      console.error('getCategoryDistribution failed');
    }
    try {
      this.historyList = await DatabaseService.getRecentHistory(5);
    } catch (err) {
      console.error('getRecentHistory failed');
    }
  }

  async loadAIAdvice(): Promise<void> {
    this.aiLoading = true;
    this.aiAdvice = '';
    try {
      let yearMonth: string = this.getCurrentYearMonth();
      let config = await ConfigService.getConfig();
      let pieData: Array<PieData> = await DatabaseService.getCategoryDistribution();
      let parts: Array<string> = [];
      for (let i: number = 0; i < pieData.length; i++) {
        parts.push(pieData[i].name + pieData[i].value.toString() + '%');
      }
      let categorySummary: string = parts.length > 0 ? parts.join('、') : '暂无数据';

      let advice: string = await AIService.generateTrainingAdvice(
        this.streakDays,
        this.weekCount,
        this.monthMinutes,
        config.goal,
        config.frequency,
        categorySummary
      );
      this.aiAdvice = advice;
    } catch (err) {
      console.error('loadAIAdvice failed');
      this.aiAdvice = '暂无法获取建议，请检查网络连接';
    }
    this.aiLoading = false;
  }

  build() {
    Column() {
      // 顶部标题栏
      this.TitleBar();

      // 可滚动内容区域
      Scroll() {
        Column() {
          // 打卡日历卡片
          this.CalendarCard();

          // 统计数据卡片
          this.StatsCard();

          // 饼图区域
          if (this.pieDataList.length > 0) {
            this.PieChartCard();
          }

          // 历史记录
          if (this.historyList.length > 0) {
            this.HistoryCard();
          }

          // AI训练建议
          this.AIAdviceCard();
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
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
      Text('数据统计')
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

  // 打卡日历卡片
  @Builder
  CalendarCard(): void {
    Column() {
      // 卡片标题
      Row() {
        SymbolGlyph($r('sys.symbol.calendar'))
          .fontSize(20)
          .fontColor(['#007DFF'])

        Text('本月打卡')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A202C')
          .margin({ left: 8 })

        Blank()

        Text(this.getMonthTitle())
          .fontSize(14)
          .fontColor('#A0AEC0')
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 连续打卡提示
      Row() {
        SymbolGlyph($r('sys.symbol.flame'))
          .fontSize(18)
          .fontColor(['#FF6B6B'])

        Text('连续打卡')
          .fontSize(14)
          .fontColor('#718096')
          .margin({ left: 6 })

        Text(this.streakDays.toString())
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF6B6B')
          .margin({ left: 6 })

        Text('天')
          .fontSize(14)
          .fontColor('#718096')
          .margin({ left: 2 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFF5F5')
      .borderRadius(16)
      .margin({ bottom: 16 })

      // 星期标题行
      Row() {
        ForEach(this.weekLabels, (label: string) => {
          Text(label)
            .fontSize(13)
            .fontColor('#A0AEC0')
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .height(36)
            .textAlign(TextAlign.Center)
        })
      }
      .width('100%')

      // 日期网格
      Grid() {
        ForEach(this.getCalendarDays(), (item: CalendarDay) => {
          GridItem() {
            this.buildDayCell(item)
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
      .columnsGap(4)
      .rowsGap(4)
      .width('100%')
    }
    .width('92%')
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .padding({ left: 20, right: 20, top: 20, bottom: 20 })
    .margin({ top: 8 })
    .shadow({
      radius: 20,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 8
    })
  }

  // 统计数据卡片
  @Builder
  StatsCard(): void {
    Row() {
      // 本周运动
      Column() {
        SymbolGlyph($r('sys.symbol.calendar'))
          .fontSize(24)
          .fontColor(['#4FC3F7'])
        Text(this.weekCount.toString())
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A202C')
          .margin({ top: 8 })
        Text('本周运动')
          .fontSize(12)
          .fontColor('#718096')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      Divider()
        .vertical(true)
        .height(50)
        .color('#EDF2F7')

      // 本月时长
      Column() {
        SymbolGlyph($r('sys.symbol.clock'))
          .fontSize(24)
          .fontColor(['#69DB7C'])
        Text(this.monthMinutes.toString())
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A202C')
          .margin({ top: 8 })
        Text('本月(分钟)')
          .fontSize(12)
          .fontColor('#718096')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      Divider()
        .vertical(true)
        .height(50)
        .color('#EDF2F7')

      // 累计打卡
      Column() {
        Text('✅')
          .fontSize(24)
        Text(this.totalCheckedDays.toString())
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A202C')
          .margin({ top: 8 })
        Text('累计打卡')
          .fontSize(12)
          .fontColor('#718096')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
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
    })
  }

  // 饼图卡片
  @Builder
  PieChartCard(): void {
    Column() {
      // 卡片标题
      Row() {
        Text('📊')
          .fontSize(20)

        Text('本月训练分布')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A202C')
          .margin({ left: 8 })
      }
      .width('100%')
      .margin({ bottom: 16 })

      Row() {
        Canvas(this.pieContext)
          .width(150)
          .height(150)
          .onReady(() => {
            this.drawPieChart();
          })

        Column() {
          ForEach(this.pieDataList, (item: PieData) => {
            Row() {
              Text('')
                .width(10)
                .height(10)
                .borderRadius(5)
                .backgroundColor(item.color)
                .margin({ right: 8 })

              Text(item.name)
                .fontSize(14)
                .fontColor('#2D3748')

              Blank()

              Text(item.value.toString() + '%')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A202C')
            }
            .width('100%')
            .margin({ bottom: 10 })
          })
        }
        .layoutWeight(1)
        .margin({ left: 20 })
      }
      .width('100%')
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

  // 历史记录卡片
  @Builder
  HistoryCard(): void {
    Column() {
      // 卡片标题
      Row() {
        Text('📋')
          .fontSize(20)

        Text('最近训练记录')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A202C')
          .margin({ left: 8 })
      }
      .width('100%')
      .margin({ bottom: 8 })

      ForEach(this.historyList, (record: HistoryRecord, index: number) => {
        Column() {
          Row() {
            // 日期图标
            Column() {
              Text('🗓')
                .fontSize(16)
            }
            .width(36)
            .height(36)
            .borderRadius(12)
            .backgroundColor('#EBF4FF')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .margin({ right: 12 })

            Column() {
              Text(record.date)
                .fontSize(13)
                .fontColor('#A0AEC0')

              Text(record.exercises)
                .fontSize(14)
                .fontColor('#2D3748')
                .margin({ top: 4 })
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })

          // 分隔线（最后一项不显示）
          if (index < this.historyList.length - 1) {
            Divider()
              .width('100%')
              .color('#EDF2F7')
          }
        }
      })
    }
    .width('92%')
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .padding({ left: 20, right: 20, top: 20, bottom: 12 })
    .margin({ top: 16 })
    .shadow({
      radius: 16,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 6
    })
  }

  // AI训练建议卡片
  @Builder
  AIAdviceCard(): void {
    Column() {
      // 卡片标题
      Row() {
        Text('💡')
          .fontSize(20)

        Text('AI训练建议')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A202C')
          .margin({ left: 8 })

        Blank()

        Button(this.aiLoading ? '生成中...' : '刷新建议')
          .fontSize(12)
          .fontColor('#FFFFFF')
          .backgroundColor('#007DFF')
          .height(30)
          .borderRadius(15)
          .padding({ left: 14, right: 14 })
          .onClick(() => {
            this.loadAIAdvice();
          })
      }
      .width('100%')
      .margin({ bottom: 4 })

      if (this.aiLoading) {
        Column() {
          LoadingProgress()
            .width(36)
            .height(36)
            .color('#007DFF')
        }
        .width('100%')
        .padding({ top: 20, bottom: 20 })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.aiAdvice !== '') {
        Column() {
          Text(this.aiAdvice)
            .fontSize(14)
            .fontColor('#2D3748')
            .lineHeight(24)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 14, bottom: 14 })
        .backgroundColor('#F7FAFC')
        .borderRadius(16)
        .margin({ top: 12 })
      } else {
        Column() {
          Row() {
            Text('✨')
              .fontSize(14)

            Text('点击"刷新建议"获取AI个性化训练指导')
              .fontSize(13)
              .fontColor('#A0AEC0')
              .margin({ left: 6 })
          }
        }
        .width('100%')
        .padding({ top: 16, bottom: 16 })
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('92%')
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .padding({ left: 20, right: 20, top: 20, bottom: 20 })
    .margin({ top: 16, bottom: 24 })
    .shadow({
      radius: 16,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 6
    })
  }

  private drawPieChart(): void {
    let ctx: CanvasRenderingContext2D = this.pieContext;
    let centerX: number = 75;
    let centerY: number = 75;
    let radius: number = 60;
    let startAngle: number = -Math.PI / 2;
    let total: number = 0;
    for (let i: number = 0; i < this.pieDataList.length; i++) {
      total += this.pieDataList[i].value;
    }
    if (total === 0) {
      return;
    }
    for (let i: number = 0; i < this.pieDataList.length; i++) {
      let sliceAngle: number = (this.pieDataList[i].value / total) * 2 * Math.PI;
      let endAngle: number = startAngle + sliceAngle;
      ctx.beginPath();
      ctx.moveTo(centerX, centerY);
      ctx.arc(centerX, centerY, radius, startAngle, endAngle);
      ctx.closePath();
      ctx.fillStyle = this.pieDataList[i].color;
      ctx.fill();
      ctx.strokeStyle = '#FFFFFF';
      ctx.lineWidth = 2;
      ctx.stroke();
      startAngle = endAngle;
    }
  }
}
