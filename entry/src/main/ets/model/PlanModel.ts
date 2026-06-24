// entry/src/main/ets/model/PlanModel.ts

export class PlanExercise {
  exerciseId: number = 0;
  name: string = '';
  category: string = '';
  categoryName: string = '';
  sets: number = 0;
  reps: number = 0;
  duration: number = 0;
  type: string = ''; // 'count' 或 'timer'
}

export class DayPlan {
  dayOfWeek: number = 0; // 1=周一, 2=周二 ... 7=周日
  dayName: string = '';
  isRestDay: boolean = false;
  exercises: Array<PlanExercise> = [];
}

export class WeeklyPlan {
  goal: string = 'keep_fit';
  frequency: number = 5;
  days: Array<DayPlan> = [];
}
