// entry/src/main/ets/pages/ExerciseExecution.ets
import { router } from '@kit.ArkUI';
import { DatabaseService } from '../service/DatabaseService';
import { ConfigService } from '../service/ConfigService';
import { ttsService } from '../service/TTSService';
import { RecordModel } from '../model/ExerciseModel';

@Entry
@Component
struct ExerciseExecution {
  @State exerciseName: string = '';
  @State sets: number = 0;
  @State reps: number = 0;
  @State duration: number = 0;
  @State exerciseType: string = 'count';
  @State currentSet: number = 1;
  @State isResting: boolean = false;
  @State restTime: number = 30;
  @State timerValue: number = 0;
  @State isRunning: boolean = false;
  @State completedSets: number = 0;
  @State completedReps: number = 0;
  @State setCompleted: boolean = false;

  private exerciseId: number = 0;
  private ttsEnabled: boolean = true;

  private getHint(): string {
    if (this.exerciseType === 'timer') {
      return '坚持' + this.duration.toString() + '秒';
    }
    return '完成' + this.reps.toString() + '次';
  }
  private hasTimer: boolean = false;
  private timerId: number = -1;
  private hasRestTimer: boolean = false;
  private restTimerId: number = -1;

  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private countdownContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings);
  private restCanvasSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private restCanvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.restCanvasSettings);

  private drawCountdownCircle(ctx: CanvasRenderingContext2D, total: number, current: number): void {
    let cx: number = 100;
    let cy: number = 100;
    let radius: number = 80;
    let lineWidth: number = 12;
    let progress: number = total > 0 ? (total - current) / total : 0;

    ctx.clearRect(0, 0, 200, 200);

    // 灰色底圈
    ctx.beginPath();
    ctx.arc(cx, cy, radius, 0, 2 * Math.PI);
    ctx.strokeStyle = '#E0E0E0';
    ctx.lineWidth = lineWidth;
    ctx.stroke();

    // 蓝色进度弧
    if (progress > 0) {
      ctx.beginPath();
      ctx.arc(cx, cy, radius, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * progress);
      ctx.strokeStyle = '#007DFF';
      ctx.lineWidth = lineWidth;
      ctx.lineCap = 'round';
      ctx.stroke();
    }
  }

  aboutToAppear(): void {
    const params: Record<string, string> = router.getParams() as Record<string, string>;
    if (params !== null && params !== undefined) {
      this.exerciseId = Number(params['id']);
      this.exerciseName = params['name'] !== undefined ? params['name'] : '';
      this.sets = Number(params['sets']);
      this.reps = Number(params['reps']);
      this.duration = Number(params['duration']);
      this.exerciseType = params['type'] !== undefined ? params['type'] : 'count';
      if (this.exerciseType === 'timer') {
        this.timerValue = this.duration;
      }
    }
    ttsService.init();
    ConfigService.getTtsEnabled().then((enabled: boolean) => {
      this.ttsEnabled = enabled;
      if (this.ttsEnabled) {
        ttsService.speak('开始' + this.exerciseName + '，第1组，' + this.getHint());
      }
    });
  }

  aboutToDisappear(): void {
    this.stopTimer();
    this.stopRestTimer();
    ttsService.shutdown();
  }

  private stopTimer(): void {
    if (this.hasTimer) {
      clearInterval(this.timerId);
      this.hasTimer = false;
      this.timerId = -1;
    }
  }

  private stopRestTimer(): void {
    if (this.hasRestTimer) {
      clearInterval(this.restTimerId);
      this.hasRestTimer = false;
      this.restTimerId = -1;
    }
  }

  private startTimer(): void {
    this.isRunning = true;
    this.hasTimer = true;
    if (this.ttsEnabled) {
      ttsService.speak('开始' + this.exerciseName + '，第' + this.currentSet.toString() + '组，' + this.getHint());
    }
    this.timerId = setInterval(() => {
      if (this.timerValue > 0) {
        this.timerValue--;
        this.drawCountdownCircle(this.countdownContext, this.duration, this.timerValue);
      } else {
        this.stopTimer();
        this.isRunning = false;
        this.completeSet();
      }
    }, 1000);
  }

  private pauseTimer(): void {
    this.isRunning = false;
    this.stopTimer();
  }

  private completeSetOnce(): void {
    this.completedReps = this.reps;
    this.setCompleted = true;
    setTimeout(() => {
      this.setCompleted = false;
      this.completeSet();
    }, 500);
  }

  private completeSet(): void {
    this.stopTimer();
    this.isRunning = false;
    if (this.currentSet < this.sets) {
      this.currentSet++;
      this.isResting = true;
      this.restTime = 30;
      if (this.ttsEnabled) {
        ttsService.speak('本组完成，休息' + this.restTime.toString() + '秒');
      }
      this.hasRestTimer = true;
      this.restTimerId = setInterval(() => {
        if (this.restTime > 0) {
          this.restTime--;
          this.drawCountdownCircle(this.restCanvasContext, 30, this.restTime);
        } else {
          this.stopRestTimer();
          this.isResting = false;
          this.completedSets++;
          if (this.ttsEnabled) {
            ttsService.speak('休息结束，准备下一组');
          }
          if (this.exerciseType === 'timer') {
            this.timerValue = this.duration;
          }
          this.completedReps = 0;
        }
      }, 1000);
    } else {
      this.completedSets = this.sets;
      this.saveRecord();
      if (this.ttsEnabled) {
        ttsService.speak('恭喜完成' + this.exerciseName + '全部训练');
      }
      AlertDialog.show({
        title: '训练完成',
        message: '恭喜完成训练！',
        confirm: {
          value: '确定',
          action: () => {
            router.back();
          }
        }
      });
    }
  }

  private skipRest(): void {
    this.stopRestTimer();
    this.isResting = false;
    this.completedSets++;
    if (this.exerciseType === 'timer') {
      this.timerValue = this.duration;
    }
    this.completedReps = 0;
  }

  private saveRecord(): void {
    let now: Date = new Date();
    let year: number = now.getFullYear();
    let month: number = now.getMonth() + 1;
    let day: number = now.getDate();
    let monthStr: string = month < 10 ? '0' + month.toString() : month.toString();
    let dayStr: string = day < 10 ? '0' + day.toString() : day.toString();
    let dateStr: string = year.toString() + '-' + monthStr + '-' + dayStr;

    let record: RecordModel = new RecordModel();
    record.exerciseId = this.exerciseId;
    record.exerciseName = this.exerciseName;
    record.date = dateStr;
    record.setsCompleted = this.sets;
    record.repsCompleted = this.exerciseType === 'count' ? this.reps * this.sets : 0;
    record.durationCompleted = this.exerciseType === 'timer' ? this.duration * this.sets : 0;
    record.completed = true;

    DatabaseService.addRecord(record).then(() => {
      console.info('Record saved: ' + this.exerciseName);
      // 通过 AppStorage 通知全局数据更新
      let version: number = AppStorage.get<number>('dataVersion') ?? 0;
      AppStorage.setOrCreate<number>('dataVersion', version + 1);
    }).catch((err: Error) => {
      console.error('Record save failed: ' + err.message);
    });
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Text('<')
          .fontSize(24)
          .fontColor('#333333')
          .onClick(() => {
            this.aboutToDisappear();
            router.back();
          })

        Text(this.exerciseName)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('')
          .width(24)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      // 进度指示
      Column() {
        Text('第 ' + this.currentSet.toString() + ' 组 / 共 ' + this.sets.toString() + ' 组')
          .fontSize(16)
          .fontColor('#666666')

        Progress({ value: this.completedSets, total: this.sets, type: ProgressType.Linear })
          .width('80%')
          .color('#007DFF')
          .margin({ top: 12 })
      }
      .width('100%')
      .padding(20)
      .margin({ top: 12 })

      if (this.isResting) {
        // 休息界面
        Column() {
          Text('休息中')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .margin({ bottom: 12 })

          Stack() {
            Canvas(this.restCanvasContext)
              .width(200)
              .height(200)
              .onReady(() => {
                this.drawCountdownCircle(this.restCanvasContext, 30, this.restTime);
              })

            Column() {
              Text(this.restTime.toString())
                .fontSize(56)
                .fontWeight(FontWeight.Bold)
                .fontColor('#007DFF')

              Text('秒')
                .fontSize(16)
                .fontColor('#999999')
            }
            .width(200)
            .height(200)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          }

          Button('跳过休息')
            .width('60%')
            .height(48)
            .backgroundColor('#007DFF')
            .fontColor('#FFFFFF')
            .borderRadius(24)
            .margin({ top: 20 })
            .onClick(() => {
              this.skipRest();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 运动界面
        Column() {
          if (this.exerciseType === 'timer') {
            // 计时型运动 — Canvas 圆环
            Stack() {
              Canvas(this.countdownContext)
                .width(200)
                .height(200)
                .onReady(() => {
                  this.drawCountdownCircle(this.countdownContext, this.duration, this.timerValue);
                })

              Column() {
                Text(this.timerValue.toString())
                  .fontSize(56)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#007DFF')

                Text('秒')
                  .fontSize(16)
                  .fontColor('#999999')
              }
              .width(200)
              .height(200)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
            }

            Row() {
              if (!this.isRunning) {
                Button('开始')
                  .width(120)
                  .height(48)
                  .backgroundColor('#007DFF')
                  .fontColor('#FFFFFF')
                  .borderRadius(24)
                  .onClick(() => {
                    this.startTimer();
                  })
              } else {
                Button('暂停')
                  .width(120)
                  .height(48)
                  .backgroundColor('#FF6B6B')
                  .fontColor('#FFFFFF')
                  .borderRadius(24)
                  .onClick(() => {
                    this.pauseTimer();
                  })
              }

              Button('完成')
                .width(120)
                .height(48)
                .backgroundColor('#4CAF50')
                .fontColor('#FFFFFF')
                .borderRadius(24)
                .margin({ left: 20 })
                .onClick(() => {
                  this.completeSet();
                })
            }
            .margin({ top: 40 })
          } else {
            // 计数型运动
            Text('目标 ' + this.reps.toString() + ' 次')
              .fontSize(64)
              .fontWeight(FontWeight.Bold)
              .fontColor('#007DFF')

            Text('完成本组后进入下一组')
              .fontSize(16)
              .fontColor('#666666')
              .margin({ top: 16 })

            Button(this.setCompleted ? '✓ 已完成' : '完成本组')
              .width('60%')
              .height(64)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .backgroundColor(this.setCompleted ? '#4CAF50' : '#007DFF')
              .fontColor('#FFFFFF')
              .borderRadius(32)
              .margin({ top: 40 })
              .onClick(() => {
                if (!this.setCompleted) {
                  this.completeSetOnce();
                }
              })
          }
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
