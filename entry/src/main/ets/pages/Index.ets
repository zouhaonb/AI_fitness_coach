import { TodayPlan } from './TodayPlan';
import { ExerciseLibrary } from './ExerciseLibrary';
import { Statistics } from './Statistics';
import { Profile } from './Profile';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;

  @Builder
  tabBuilder(icon: Resource, title: string, index: number) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(this.currentIndex === index ? '#007DFF' : '#999999')
      Text(title)
        .fontSize(12)
        .fontColor(this.currentIndex === index ? '#007DFF' : '#999999')
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
        TabContent() {
          TodayPlan({ activeTabIndex: this.currentIndex, myTabIndex: 0 })
        }
        .tabBar(this.tabBuilder($r('app.media.ic_tab_plan'), '今日计划', 0))

        TabContent() {
          ExerciseLibrary()
        }
        .tabBar(this.tabBuilder($r('app.media.ic_tab_library'), '运动库', 1))

        TabContent() {
          Statistics({ activeTabIndex: this.currentIndex, myTabIndex: 2 })
        }
        .tabBar(this.tabBuilder($r('app.media.ic_tab_stats'), '数据统计', 2))

        TabContent() {
          Profile({ activeTabIndex: this.currentIndex, myTabIndex: 3 })
        }
        .tabBar(this.tabBuilder($r('app.media.ic_tab_profile'), '个人中心', 3))
      }
      .onChange((index: number) => {
        this.currentIndex = index;
      })
      .barMode(BarMode.Fixed)
      .scrollable(false)
      .animationDuration(0)
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}
