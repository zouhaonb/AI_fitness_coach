// entry/src/main/ets/service/PlanService.ts
import { preferences } from '@kit.ArkData';
import { WeeklyPlan, DayPlan, PlanExercise } from '../model/PlanModel';

class ExercisePoolItem {
  exerciseId: number = 0;
  name: string = '';
  category: string = '';
  categoryName: string = '';
  type: string = '';
}

export class PlanService {
  private static STORE_NAME: string = 'user_config';
  private static KEY_WEEKLY_PLAN: string = 'weekly_plan';

  private static dayNames: Array<string> = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  private static getExercisePools(): Array<Array<ExercisePoolItem>> {
    // pool 0: 有氧
    let cardio: Array<ExercisePoolItem> = [
      { exerciseId: 11, name: '开合跳', category: 'cardio', categoryName: '有氧', type: 'timer' },
      { exerciseId: 12, name: '高抬腿', category: 'cardio', categoryName: '有氧', type: 'timer' },
      { exerciseId: 13, name: '波比跳', category: 'cardio', categoryName: '有氧', type: 'count' },
      { exerciseId: 14, name: '跳绳', category: 'cardio', categoryName: '有氧', type: 'timer' }
    ];
    // pool 1: 腿部
    let leg: Array<ExercisePoolItem> = [
      { exerciseId: 3, name: '杠铃深蹲', category: 'leg', categoryName: '腿部', type: 'count' },
      { exerciseId: 4, name: '弓步蹲', category: 'leg', categoryName: '腿部', type: 'count' },
      { exerciseId: 5, name: '靠墙静蹲', category: 'leg', categoryName: '腿部', type: 'timer' }
    ];
    // pool 2: 胸部
    let chest: Array<ExercisePoolItem> = [
      { exerciseId: 1, name: '俯卧撑', category: 'chest', categoryName: '胸部', type: 'count' },
      { exerciseId: 2, name: '哑铃飞鸟', category: 'chest', categoryName: '胸部', type: 'count' }
    ];
    // pool 3: 背部
    let back: Array<ExercisePoolItem> = [
      { exerciseId: 9, name: '引体向上', category: 'back', categoryName: '背部', type: 'count' },
      { exerciseId: 10, name: '俯身划船', category: 'back', categoryName: '背部', type: 'count' }
    ];
    // pool 4: 腹部
    let abs: Array<ExercisePoolItem> = [
      { exerciseId: 6, name: '仰卧起坐', category: 'abs', categoryName: '腹部', type: 'count' },
      { exerciseId: 7, name: '平板支撑', category: 'abs', categoryName: '腹部', type: 'timer' },
      { exerciseId: 8, name: '卷腹', category: 'abs', categoryName: '腹部', type: 'count' }
    ];
    // pool 5: 综合(混搭)
    let mixed: Array<ExercisePoolItem> = [
      { exerciseId: 1, name: '俯卧撑', category: 'chest', categoryName: '胸部', type: 'count' },
      { exerciseId: 7, name: '平板支撑', category: 'abs', categoryName: '腹部', type: 'timer' },
      { exerciseId: 3, name: '杠铃深蹲', category: 'leg', categoryName: '腿部', type: 'count' },
      { exerciseId: 11, name: '开合跳', category: 'cardio', categoryName: '有氧', type: 'timer' },
      { exerciseId: 8, name: '卷腹', category: 'abs', categoryName: '腹部', type: 'count' }
    ];
    return [cardio, leg, chest, back, abs, mixed];
  }

  private static getTrainingDayIndices(frequency: number): Array<number> {
    if (frequency === 3) {
      return [0, 2, 4]; // 周一、周三、周五
    } else if (frequency === 4) {
      return [0, 1, 3, 4]; // 周一、周二、周四、周五
    } else if (frequency === 5) {
      return [0, 1, 2, 3, 4]; // 周一到周五
    } else if (frequency === 6) {
      return [0, 1, 2, 3, 4, 5]; // 周一到周六
    } else {
      return [0, 1, 2, 3, 4, 5, 6]; // 全周
    }
  }

  private static toPlanExercise(item: ExercisePoolItem, sets: number, reps: number, duration: number): PlanExercise {
    let ex: PlanExercise = new PlanExercise();
    ex.exerciseId = item.exerciseId;
    ex.name = item.name;
    ex.category = item.category;
    ex.categoryName = item.categoryName;
    ex.type = item.type;
    ex.sets = sets;
    ex.reps = item.type === 'count' ? reps : 0;
    ex.duration = item.type === 'timer' ? duration : 0;
    return ex;
  }

  static generateDefaultPlan(goal: string, frequency: number): WeeklyPlan {
    let sets: number = 3;
    let reps: number = 15;
    let duration: number = 30;
    if (goal === 'lose_fat') {
      sets = 3;
      reps = 20;
      duration = 30;
    } else if (goal === 'gain_muscle') {
      sets = 4;
      reps = 12;
      duration = 45;
    }

    let pools: Array<Array<ExercisePoolItem>> = PlanService.getExercisePools();
    let trainingDays: Array<number> = PlanService.getTrainingDayIndices(frequency);

    let plan: WeeklyPlan = new WeeklyPlan();
    plan.goal = goal;
    plan.frequency = frequency;

    let dayPlans: Array<DayPlan> = [];
    let trainingDayIdx: number = 0;
    for (let d: number = 0; d < 7; d++) {
      let dayPlan: DayPlan = new DayPlan();
      dayPlan.dayOfWeek = d + 1;
      dayPlan.dayName = PlanService.dayNames[d];
      dayPlan.isRestDay = true;
      dayPlan.exercises = [];

      let isTrainingDay: boolean = false;
      for (let t: number = 0; t < trainingDays.length; t++) {
        if (trainingDays[t] === d) {
          isTrainingDay = true;
          break;
        }
      }

      if (isTrainingDay) {
        dayPlan.isRestDay = false;
        let exercises: Array<PlanExercise> = [];

        if (goal === 'lose_fat') {
          // 轮换：有氧日、腿部日、综合日
          let poolIdx: number = trainingDayIdx % 3;
          if (poolIdx === 0) {
            // 有氧日
            let pool: Array<ExercisePoolItem> = pools[0];
            for (let i: number = 0; i < pool.length; i++) {
              exercises.push(PlanService.toPlanExercise(pool[i], sets, reps, duration));
            }
            // + 卷腹
            exercises.push(PlanService.toPlanExercise(pools[4][2], sets, reps, duration));
          } else if (poolIdx === 1) {
            // 腿部日
            let pool: Array<ExercisePoolItem> = pools[1];
            for (let i: number = 0; i < pool.length; i++) {
              exercises.push(PlanService.toPlanExercise(pool[i], sets, reps, duration));
            }
            // + 开合跳
            exercises.push(PlanService.toPlanExercise(pools[0][0], sets, reps, duration));
          } else {
            // 综合日
            let pool: Array<ExercisePoolItem> = pools[5];
            for (let i: number = 0; i < pool.length; i++) {
              exercises.push(PlanService.toPlanExercise(pool[i], sets, reps, duration));
            }
          }
        } else if (goal === 'gain_muscle') {
          // 轮换：胸部日、背部日、腿部日
          let poolIdx: number = trainingDayIdx % 3;
          if (poolIdx === 0) {
            // 胸部日
            let pool: Array<ExercisePoolItem> = pools[2];
            for (let i: number = 0; i < pool.length; i++) {
              exercises.push(PlanService.toPlanExercise(pool[i], sets, reps, duration));
            }
            exercises.push(PlanService.toPlanExercise(pools[4][2], sets, reps, duration)); // 卷腹
            exercises.push(PlanService.toPlanExercise(pools[4][1], sets, reps, duration)); // 平板支撑
          } else if (poolIdx === 1) {
            // 背部日
            let pool: Array<ExercisePoolItem> = pools[3];
            for (let i: number = 0; i < pool.length; i++) {
              exercises.push(PlanService.toPlanExercise(pool[i], sets, reps, duration));
            }
            exercises.push(PlanService.toPlanExercise(pools[1][0], sets, reps, duration)); // 深蹲
            exercises.push(PlanService.toPlanExercise(pools[4][0], sets, reps, duration)); // 仰卧起坐
          } else {
            // 腿部日
            let pool: Array<ExercisePoolItem> = pools[1];
            for (let i: number = 0; i < pool.length; i++) {
              exercises.push(PlanService.toPlanExercise(pool[i], sets, reps, duration));
            }
            exercises.push(PlanService.toPlanExercise(pools[2][0], sets, reps, duration)); // 俯卧撑
          }
        } else {
          // keep_fit: 综合日
          let pool: Array<ExercisePoolItem> = pools[5];
          for (let i: number = 0; i < pool.length; i++) {
            exercises.push(PlanService.toPlanExercise(pool[i], sets, reps, duration));
          }
        }

        dayPlan.exercises = exercises;
        trainingDayIdx++;
      }

      dayPlans.push(dayPlan);
    }

    plan.days = dayPlans;
    return plan;
  }

  static async saveWeeklyPlan(plan: WeeklyPlan): Promise<void> {
    let context: Context = getContext();
    let store: preferences.Preferences = await preferences.getPreferences(context, PlanService.STORE_NAME);
    let jsonStr: string = JSON.stringify(plan);
    await store.put(PlanService.KEY_WEEKLY_PLAN, jsonStr);
    await store.flush();
  }

  static async getWeeklyPlan(): Promise<WeeklyPlan | null> {
    let context: Context = getContext();
    let store: preferences.Preferences = await preferences.getPreferences(context, PlanService.STORE_NAME);
    let jsonStr: string = await store.get(PlanService.KEY_WEEKLY_PLAN, '') as string;
    if (jsonStr === '') {
      return null;
    }
    let plan: WeeklyPlan = PlanService.parseWeeklyPlan(jsonStr);
    return plan;
  }

  static async getTodayPlan(): Promise<DayPlan> {
    let plan: WeeklyPlan | null = await PlanService.getWeeklyPlan();
    if (plan === null) {
      let restDay: DayPlan = new DayPlan();
      let now: Date = new Date();
      let dayOfWeek: number = now.getDay();
      if (dayOfWeek === 0) {
        dayOfWeek = 7;
      }
      restDay.dayOfWeek = dayOfWeek;
      restDay.dayName = PlanService.dayNames[dayOfWeek - 1];
      restDay.isRestDay = true;
      restDay.exercises = [];
      return restDay;
    }
    let now: Date = new Date();
    let dayOfWeek: number = now.getDay();
    if (dayOfWeek === 0) {
      dayOfWeek = 7;
    }
    let todayIdx: number = dayOfWeek - 1;
    if (todayIdx >= 0 && todayIdx < plan.days.length) {
      return plan.days[todayIdx];
    }
    let restDay: DayPlan = new DayPlan();
    restDay.dayOfWeek = dayOfWeek;
    restDay.dayName = PlanService.dayNames[dayOfWeek - 1];
    restDay.isRestDay = true;
    restDay.exercises = [];
    return restDay;
  }

  private static parseWeeklyPlan(jsonStr: string): WeeklyPlan {
    let raw: Record<string, Object> = JSON.parse(jsonStr) as Record<string, Object>;
    let plan: WeeklyPlan = new WeeklyPlan();
    plan.goal = raw['goal'] !== undefined ? raw['goal'] as string : 'keep_fit';
    plan.frequency = raw['frequency'] !== undefined ? raw['frequency'] as number : 5;

    let daysRaw: Array<Object> = raw['days'] !== undefined ? raw['days'] as Array<Object> : [];
    let days: Array<DayPlan> = [];
    for (let i: number = 0; i < daysRaw.length; i++) {
      let dayRaw: Record<string, Object> = daysRaw[i] as Record<string, Object>;
      let dayPlan: DayPlan = new DayPlan();
      dayPlan.dayOfWeek = dayRaw['dayOfWeek'] !== undefined ? dayRaw['dayOfWeek'] as number : 0;
      dayPlan.dayName = dayRaw['dayName'] !== undefined ? dayRaw['dayName'] as string : '';
      dayPlan.isRestDay = dayRaw['isRestDay'] !== undefined ? dayRaw['isRestDay'] as boolean : true;

      let exercisesRaw: Array<Object> = dayRaw['exercises'] !== undefined ? dayRaw['exercises'] as Array<Object> : [];
      let exercises: Array<PlanExercise> = [];
      for (let j: number = 0; j < exercisesRaw.length; j++) {
        let exRaw: Record<string, Object> = exercisesRaw[j] as Record<string, Object>;
        let ex: PlanExercise = new PlanExercise();
        ex.exerciseId = exRaw['exerciseId'] !== undefined ? exRaw['exerciseId'] as number : 0;
        ex.name = exRaw['name'] !== undefined ? exRaw['name'] as string : '';
        ex.category = exRaw['category'] !== undefined ? exRaw['category'] as string : '';
        ex.categoryName = exRaw['categoryName'] !== undefined ? exRaw['categoryName'] as string : '';
        ex.sets = exRaw['sets'] !== undefined ? exRaw['sets'] as number : 0;
        ex.reps = exRaw['reps'] !== undefined ? exRaw['reps'] as number : 0;
        ex.duration = exRaw['duration'] !== undefined ? exRaw['duration'] as number : 0;
        ex.type = exRaw['type'] !== undefined ? exRaw['type'] as string : '';
        exercises.push(ex);
      }
      dayPlan.exercises = exercises;
      days.push(dayPlan);
    }
    plan.days = days;
    return plan;
  }
}
