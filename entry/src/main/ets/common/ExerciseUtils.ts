// entry/src/main/ets/common/ExerciseUtils.ts
// 公共工具函数，消除跨文件重复代码

/** 难度等级枚举 */
export class DifficultyLevel {
  static readonly Beginner: string = '初级';
  static readonly Intermediate: string = '中级';
  static readonly Advanced: string = '高级';
}

/** 分类 → 主色 */
export function getCategoryColor(categoryName: string): string {
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

/** 分类 → 浅底色 */
export function getCategoryBgColor(categoryName: string): string {
  const bgMap: Map<string, string> = new Map([
    ['胸部', '#E3F7FF'],
    ['腿部', '#FFF0E8'],
    ['腹部', '#F0FAE8'],
    ['背部', '#FFF8E1'],
    ['有氧', '#FFEEF5'],
    ['拉伸', '#F3E8FF']
  ]);
  let color: string | undefined = bgMap.get(categoryName);
  return color !== undefined ? color : '#EBF5FF';
}

/** 颜色变亮 */
export function lightenColor(color: string): string {
  if (color.startsWith('#')) {
    let hex: string = color.substring(1);
    let r: number = parseInt(hex.substring(0, 2), 16);
    let g: number = parseInt(hex.substring(2, 4), 16);
    let b: number = parseInt(hex.substring(4, 6), 16);
    r = Math.min(255, r + 40);
    g = Math.min(255, g + 40);
    b = Math.min(255, b + 40);
    return '#' + r.toString(16).padStart(2, '0') + g.toString(16).padStart(2, '0') + b.toString(16).padStart(2, '0');
  }
  return color;
}

/** 运动参数 → 难度 */
export function getDifficulty(sets: number, reps: number): string {
  if (sets >= 5 && reps >= 20) {
    return DifficultyLevel.Advanced;
  } else if (sets >= 3 && reps >= 15) {
    return DifficultyLevel.Intermediate;
  }
  return DifficultyLevel.Beginner;
}

/** 难度 → 颜色 */
export function getDifficultyColor(difficulty: string): string {
  if (difficulty === DifficultyLevel.Advanced) {
    return '#FF6B6B';
  } else if (difficulty === DifficultyLevel.Intermediate) {
    return '#FFA94D';
  }
  return '#69DB7C';
}

/** 运动名 → 图片路径 */
export function getExerciseImagePath(name: string, category: string): string | Resource {
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
  let fileName: string | undefined = nameMap.get(name);
  if (fileName !== undefined) {
    return 'resource://RAWFILE/exercises/' + category + '/' + fileName + '.png';
  }
  return $r('app.media.exercise_placeholder');
}

/** 分类 → 推荐休息时间（秒） */
export function getRestTimeByCategory(category: string): number {
  let restMap: Map<string, number> = new Map([
    ['有氧', 60],
    ['腿部', 60],
    ['胸部', 45],
    ['背部', 45],
    ['腹部', 30],
    ['拉伸', 20]
  ]);
  let time: number | undefined = restMap.get(category);
  return time !== undefined ? time : 30;
}

/** 获取今日日期字符串 YYYY-MM-DD */
export function getTodayDateStr(): string {
  let now: Date = new Date();
  let year: number = now.getFullYear();
  let month: number = now.getMonth() + 1;
  let day: number = now.getDate();
  let monthStr: string = month < 10 ? '0' + month.toString() : month.toString();
  let dayStr: string = day < 10 ? '0' + day.toString() : day.toString();
  return year.toString() + '-' + monthStr + '-' + dayStr;
}

/** 格式化秒数为 MM:SS */
export function formatElapsed(seconds: number): string {
  let min: number = Math.floor(seconds / 60);
  let sec: number = seconds % 60;
  let minStr: string = min < 10 ? '0' + min.toString() : min.toString();
  let secStr: string = sec < 10 ? '0' + sec.toString() : sec.toString();
  return minStr + ':' + secStr;
}
