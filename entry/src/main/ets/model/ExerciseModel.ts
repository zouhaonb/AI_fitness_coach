// entry/src/main/ets/model/ExerciseModel.ts

export class ExerciseModel {
  id: number = 0;
  name: string = '';
  category: string = '';
  categoryName: string = '';
  description: string = '';
  defaultSets: number = 0;
  defaultReps: number = 0;
  defaultDuration: number = 0;
  type: string = ''; // 'count' 或 'timer'
}

export class RecordModel {
  id: number = 0;
  exerciseId: number = 0;
  exerciseName: string = '';
  date: string = '';
  setsCompleted: number = 0;
  repsCompleted: number = 0;
  durationCompleted: number = 0;
  completed: boolean = false;
}

export class TodayTask {
  id: number = 0;
  exerciseId: number = 0;
  name: string = '';
  category: string = '';
  sets: number = 0;
  reps: number = 0;
  duration: number = 0;
  type: string = '';
  completed: boolean = false;
}

export class UserConfig {
  goal: string = 'lose_fat';
  frequency: number = 5;
  nickname: string = '健身达人';
  ttsEnabled: boolean = true;
  bio: string = '坚持锻炼，遇见更好的自己';
  city: string = '';
  avatarUri: string = '';
}

export class PieData {
  name: string = '';
  value: number = 0;
  color: string = '';
}

export class HistoryRecord {
  date: string = '';
  exercises: string = '';
}
