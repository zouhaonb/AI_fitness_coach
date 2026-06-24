// entry/src/main/ets/service/DatabaseService.ts
import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { RecordModel, PieData, ExerciseModel, HistoryRecord } from '../model/ExerciseModel';
import { GlobalContext } from '../common/GlobalContext';
import { getCategoryColor } from '../common/ExerciseUtils';
import { getTodayDateStr } from '../common/ExerciseUtils';

class DateRange {
  startDate: string = '';
  endDate: string = '';
}

export class DatabaseService {
  private static DB_NAME: string = 'fitness.db';
  private static STORE_CONFIG: relationalStore.StoreConfig = {
    name: DatabaseService.DB_NAME,
    securityLevel: relationalStore.SecurityLevel.S1
  };

  // #32: 缓存数据库连接
  private static cachedStore: relationalStore.RdbStore | null = null;

  private static async getStore(): Promise<relationalStore.RdbStore> {
    if (DatabaseService.cachedStore !== null) {
      return DatabaseService.cachedStore;
    }
    let context: common.UIAbilityContext = GlobalContext.getContext();
    let store: relationalStore.RdbStore = await relationalStore.getRdbStore(context, DatabaseService.STORE_CONFIG);
    DatabaseService.cachedStore = store;
    return store;
  }

  static async initDatabase(): Promise<relationalStore.RdbStore> {
    let context: common.UIAbilityContext = GlobalContext.getContext();
    let store: relationalStore.RdbStore = await relationalStore.getRdbStore(context, DatabaseService.STORE_CONFIG);
    DatabaseService.cachedStore = store;

    let exerciseSql: string = `CREATE TABLE IF NOT EXISTS exercise (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      categoryName TEXT NOT NULL,
      description TEXT,
      defaultSets INTEGER DEFAULT 0,
      defaultReps INTEGER DEFAULT 0,
      defaultDuration INTEGER DEFAULT 0,
      type TEXT NOT NULL
    )`;

    // #40: UNIQUE 约束防止重复记录
    let recordSql: string = `CREATE TABLE IF NOT EXISTS record (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      exerciseId INTEGER NOT NULL,
      exerciseName TEXT NOT NULL,
      date TEXT NOT NULL,
      setsCompleted INTEGER DEFAULT 0,
      repsCompleted INTEGER DEFAULT 0,
      durationCompleted INTEGER DEFAULT 0,
      completed INTEGER DEFAULT 0,
      UNIQUE(exerciseId, date)
    )`;

    await store.executeSql(exerciseSql);
    await store.executeSql(recordSql);

    return store;
  }

  // #40: 使用 INSERT OR REPLACE 防止重复
  static async addRecord(record: RecordModel): Promise<void> {
    let store: relationalStore.RdbStore = await DatabaseService.getStore();
    // INSERT OR REPLACE：如果 (exerciseId, date) 已存在则更新
    let sql: string = `INSERT OR REPLACE INTO record (exerciseId, exerciseName, date, setsCompleted, repsCompleted, durationCompleted, completed)
      VALUES (?, ?, ?, ?, ?, ?, ?)`;
    await store.executeSql(sql, [
      record.exerciseId, record.exerciseName, record.date,
      record.setsCompleted, record.repsCompleted, record.durationCompleted,
      record.completed ? 1 : 0
    ]);
  }

  // #4: 取消打卡时删除记录
  static async deleteRecordByExerciseAndDate(exerciseId: number, date: string): Promise<void> {
    let store: relationalStore.RdbStore = await DatabaseService.getStore();
    let predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('record');
    predicates.equalTo('exerciseId', exerciseId);
    predicates.equalTo('date', date);
    await store.delete(predicates);
  }

  static async getRecordsByDate(date: string): Promise<Array<RecordModel>> {
    let store: relationalStore.RdbStore = await DatabaseService.getStore();
    let predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('record');
    predicates.equalTo('date', date);
    let resultSet: relationalStore.ResultSet = await store.query(predicates, ['id', 'exerciseId', 'exerciseName', 'date', 'setsCompleted', 'repsCompleted', 'durationCompleted', 'completed']);

    let result: Array<RecordModel> = [];
    while (resultSet.goToNextRow()) {
      let record: RecordModel = new RecordModel();
      record.id = resultSet.getLong(0);
      record.exerciseId = resultSet.getLong(1);
      record.exerciseName = resultSet.getString(2);
      record.date = resultSet.getString(3);
      record.setsCompleted = resultSet.getLong(4);
      record.repsCompleted = resultSet.getLong(5);
      record.durationCompleted = resultSet.getLong(6);
      record.completed = resultSet.getLong(7) === 1;
      result.push(record);
    }
    resultSet.close();
    return result;
  }

  static async getRecordsByMonth(yearMonth: string): Promise<Array<RecordModel>> {
    let store: relationalStore.RdbStore = await DatabaseService.getStore();
    let predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('record');
    predicates.like('date', yearMonth + '%');
    let resultSet: relationalStore.ResultSet = await store.query(predicates, ['id', 'exerciseId', 'exerciseName', 'date', 'setsCompleted', 'repsCompleted', 'durationCompleted', 'completed']);

    let result: Array<RecordModel> = [];
    while (resultSet.goToNextRow()) {
      let record: RecordModel = new RecordModel();
      record.id = resultSet.getLong(0);
      record.exerciseId = resultSet.getLong(1);
      record.exerciseName = resultSet.getString(2);
      record.date = resultSet.getString(3);
      record.setsCompleted = resultSet.getLong(4);
      record.repsCompleted = resultSet.getLong(5);
      record.durationCompleted = resultSet.getLong(6);
      record.completed = resultSet.getLong(7) === 1;
      result.push(record);
    }
    resultSet.close();
    return result;
  }

  // #3: 使用参数化查询
  static async getCheckedDays(yearMonth: string): Promise<Array<number>> {
    let store: relationalStore.RdbStore = await DatabaseService.getStore();
    let predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('record');
    predicates.like('date', yearMonth + '%');
    predicates.equalTo('completed', 1);
    let resultSet: relationalStore.ResultSet = await store.query(predicates, ['date']);

    let dateSet: Set<string> = new Set();
    while (resultSet.goToNextRow()) {
      let dateStr: string = resultSet.getString(0);
      // 提取日期中的"日"部分
      let day: string = dateStr.substring(8, 10);
      dateSet.add(day);
    }
    resultSet.close();

    let days: Array<number> = [];
    dateSet.forEach((dayStr: string) => {
      days.push(parseInt(dayStr));
    });
    days.sort((a: number, b: number) => a - b);
    return days;
  }

  // #15: 连续打卡必须从今天或昨天开始
  static async getStreakDays(): Promise<number> {
    let store: relationalStore.RdbStore = await DatabaseService.getStore();
    let predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('record');
    predicates.equalTo('completed', 1);
    let resultSet: relationalStore.ResultSet = await store.query(predicates, ['date']);

    let dateSet: Set<string> = new Set();
    while (resultSet.goToNextRow()) {
      dateSet.add(resultSet.getString(0));
    }
    resultSet.close();

    if (dateSet.size === 0) {
      return 0;
    }

    let dates: Array<string> = [];
    dateSet.forEach((d: string) => dates.push(d));
    dates.sort().reverse(); // 降序

    // #15: 最近一次打卡必须是今天或昨天
    let today: string = getTodayDateStr();
    let yesterday: Date = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    let yesterdayStr: string = DatabaseService.formatDate(yesterday);

    if (dates[0] !== today && dates[0] !== yesterdayStr) {
      return 0;
    }

    let streak: number = 1;
    for (let i: number = 0; i < dates.length - 1; i++) {
      let currentDate: Date = new Date(dates[i]);
      let prevDate: Date = new Date(dates[i + 1]);
      let diffMs: number = currentDate.getTime() - prevDate.getTime();
      let diffDays: number = Math.floor(diffMs / (1000 * 60 * 60 * 24));
      if (diffDays === 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // #14: 按天数计算而非记录条数
  static async getWeekCount(): Promise<number> {
    let store: relationalStore.RdbStore = await DatabaseService.getStore();
    let range: DateRange = DatabaseService.getWeekRange();

    let predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('record');
    predicates.equalTo('completed', 1);
    predicates.greaterThanOrEqualTo('date', range.startDate);
    predicates.lessThanOrEqualTo('date', range.endDate);
    let resultSet: relationalStore.ResultSet = await store.query(predicates, ['date']);

    let dateSet: Set<string> = new Set();
    while (resultSet.goToNextRow()) {
      dateSet.add(resultSet.getString(0));
    }
    resultSet.close();
    return dateSet.size;
  }

  static async getTotalMinutes(): Promise<number> {
    let store: relationalStore.RdbStore = await DatabaseService.getStore();
    let sql: string = 'SELECT SUM(durationCompleted) FROM record WHERE completed = 1';
    let resultSet: relationalStore.ResultSet = await store.querySql(sql);

    let totalSeconds: number = 0;
    if (resultSet.goToNextRow()) {
      totalSeconds = resultSet.getLong(0);
    }
    resultSet.close();
    return Math.floor(totalSeconds / 60);
  }

  static async getCategoryDistribution(): Promise<Array<PieData>> {
    let store: relationalStore.RdbStore = await DatabaseService.getStore();
    let sql: string = 'SELECT e.categoryName, COUNT(*) as cnt FROM record r JOIN exercise e ON r.exerciseId = e.id WHERE r.completed = 1 GROUP BY e.categoryName';
    let resultSet: relationalStore.ResultSet = await store.querySql(sql);

    let total: number = 0;
    let categoryCount: Map<string, number> = new Map();
    while (resultSet.goToNextRow()) {
      let name: string = resultSet.getString(0);
      let count: number = resultSet.getLong(1);
      categoryCount.set(name, count);
      total += count;
    }
    resultSet.close();

    // #43: 使用 largest-remainder 法避免百分比之和不等于 100
    let result: Array<PieData> = [];
    let rawPercentages: Array<{ name: string; raw: number; count: number }> = [];
    let flooredSum: number = 0;
    categoryCount.forEach((count: number, name: string) => {
      let raw: number = total > 0 ? (count / total) * 100 : 0;
      let floored: number = Math.floor(raw);
      flooredSum += floored;
      rawPercentages.push({ name: name, raw: raw, count: count });
    });

    // 按小数部分降序排列，补足差额到 100
    rawPercentages.sort((a, b) => (a.raw - Math.floor(a.raw)) - (b.raw - Math.floor(b.raw)));
    let remainder: number = 100 - flooredSum;
    for (let i: number = 0; i < rawPercentages.length; i++) {
      let pie: PieData = new PieData();
      pie.name = rawPercentages[i].name;
      pie.value = Math.floor(rawPercentages[i].raw) + (i < remainder ? 1 : 0);
      let color: string = getCategoryColor(rawPercentages[i].name);
      pie.color = color;
      result.push(pie);
    }
    return result;
  }

  static async getPlannedExercises(date: string): Promise<Array<RecordModel>> {
    let store: relationalStore.RdbStore = await DatabaseService.getStore();
    let predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('record');
    predicates.equalTo('date', date);
    predicates.equalTo('completed', 0);
    let resultSet: relationalStore.ResultSet = await store.query(predicates, ['id', 'exerciseId', 'exerciseName', 'date', 'setsCompleted', 'repsCompleted', 'durationCompleted', 'completed']);

    let result: Array<RecordModel> = [];
    while (resultSet.goToNextRow()) {
      let record: RecordModel = new RecordModel();
      record.id = resultSet.getLong(0);
      record.exerciseId = resultSet.getLong(1);
      record.exerciseName = resultSet.getString(2);
      record.date = resultSet.getString(3);
      record.setsCompleted = resultSet.getLong(4);
      record.repsCompleted = resultSet.getLong(5);
      record.durationCompleted = resultSet.getLong(6);
      record.completed = resultSet.getLong(7) === 1;
      result.push(record);
    }
    resultSet.close();
    return result;
  }

  static async getAllExercises(): Promise<Array<ExerciseModel>> {
    let store: relationalStore.RdbStore = await DatabaseService.getStore();
    let sql: string = 'SELECT * FROM exercise';
    let resultSet: relationalStore.ResultSet = await store.querySql(sql);

    let result: Array<ExerciseModel> = [];
    while (resultSet.goToNextRow()) {
      let item: ExerciseModel = new ExerciseModel();
      item.id = resultSet.getLong(0);
      item.name = resultSet.getString(1);
      item.category = resultSet.getString(2);
      item.categoryName = resultSet.getString(3);
      item.description = resultSet.getString(4);
      item.defaultSets = resultSet.getLong(5);
      item.defaultReps = resultSet.getLong(6);
      item.defaultDuration = resultSet.getLong(7);
      item.type = resultSet.getString(8);
      result.push(item);
    }
    resultSet.close();
    return result;
  }

  // #3: 参数化查询
  static async getMonthTotalMinutes(yearMonth: string): Promise<number> {
    let store: relationalStore.RdbStore = await DatabaseService.getStore();
    let predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('record');
    predicates.equalTo('completed', 1);
    predicates.like('date', yearMonth + '%');
    let resultSet: relationalStore.ResultSet = await store.query(predicates, ['durationCompleted']);

    let totalSeconds: number = 0;
    while (resultSet.goToNextRow()) {
      totalSeconds += resultSet.getLong(0);
    }
    resultSet.close();
    return Math.floor(totalSeconds / 60);
  }

  static async getTotalCheckedDays(): Promise<number> {
    let store: relationalStore.RdbStore = await DatabaseService.getStore();
    let sql: string = 'SELECT COUNT(DISTINCT date) FROM record WHERE completed = 1';
    let resultSet: relationalStore.ResultSet = await store.querySql(sql);

    let count: number = 0;
    if (resultSet.goToNextRow()) {
      count = resultSet.getLong(0);
    }
    resultSet.close();
    return count;
  }

  // #39: 单条 SQL 替代 N+1 查询
  static async getRecentHistory(limit: number): Promise<Array<HistoryRecord>> {
    let store: relationalStore.RdbStore = await DatabaseService.getStore();
    let sql: string = `SELECT r.date, GROUP_CONCAT(DISTINCT r.exerciseName) as names
      FROM record r
      WHERE r.completed = 1
      GROUP BY r.date
      ORDER BY r.date DESC
      LIMIT ?`;
    let resultSet: relationalStore.ResultSet = await store.querySql(sql, [limit]);

    let result: Array<HistoryRecord> = [];
    while (resultSet.goToNextRow()) {
      let history: HistoryRecord = new HistoryRecord();
      history.date = resultSet.getString(0);
      history.exercises = resultSet.getString(1);
      result.push(history);
    }
    resultSet.close();
    return result;
  }

  static async clearAllRecords(): Promise<void> {
    let store: relationalStore.RdbStore = await DatabaseService.getStore();
    await store.executeSql('DELETE FROM record');
  }

  private static getWeekRange(): DateRange {
    let now: Date = new Date();
    let dayOfWeek: number = now.getDay();
    if (dayOfWeek === 0) {
      dayOfWeek = 7;
    }
    let monday: Date = new Date(now);
    monday.setDate(now.getDate() - (dayOfWeek - 1));
    let sunday: Date = new Date(monday);
    sunday.setDate(monday.getDate() + 6);

    let range: DateRange = new DateRange();
    range.startDate = DatabaseService.formatDate(monday);
    range.endDate = DatabaseService.formatDate(sunday);
    return range;
  }

  private static formatDate(date: Date): string {
    let year: number = date.getFullYear();
    let month: number = date.getMonth() + 1;
    let day: number = date.getDate();
    let monthStr: string = month < 10 ? '0' + month.toString() : month.toString();
    let dayStr: string = day < 10 ? '0' + day.toString() : day.toString();
    return year.toString() + '-' + monthStr + '-' + dayStr;
  }
}
