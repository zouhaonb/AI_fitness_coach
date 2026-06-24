// entry/src/main/ets/service/ConfigService.ts
import { preferences } from '@kit.ArkData';
import { UserConfig } from '../model/ExerciseModel';
import { GlobalContext } from '../common/GlobalContext';

export class ConfigService {
  private static STORE_NAME: string = 'user_config';
  private static KEY_GOAL: string = 'goal';
  private static KEY_FREQUENCY: string = 'frequency';
  private static KEY_NICKNAME: string = 'nickname';
  private static KEY_TTS_ENABLED: string = 'ttsEnabled';
  private static KEY_BIO: string = 'bio';
  private static KEY_CITY: string = 'city';
  private static KEY_AVATAR_URI: string = 'avatarUri';

  static async getConfig(): Promise<UserConfig> {
    let context = GlobalContext.getContext();
    let store: preferences.Preferences = await preferences.getPreferences(context, ConfigService.STORE_NAME);

    let goal: string = await store.get(ConfigService.KEY_GOAL, 'lose_fat') as string;
    let frequency: number = await store.get(ConfigService.KEY_FREQUENCY, 5) as number;
    let nickname: string = await store.get(ConfigService.KEY_NICKNAME, '健身达人') as string;
    let ttsEnabled: boolean = await store.get(ConfigService.KEY_TTS_ENABLED, true) as boolean;
    let bio: string = await store.get(ConfigService.KEY_BIO, '坚持锻炼，遇见更好的自己') as string;
    let city: string = await store.get(ConfigService.KEY_CITY, '') as string;
    let avatarUri: string = await store.get(ConfigService.KEY_AVATAR_URI, '') as string;

    let config: UserConfig = new UserConfig();
    config.goal = goal;
    config.frequency = frequency;
    config.nickname = nickname;
    config.ttsEnabled = ttsEnabled;
    config.bio = bio;
    config.city = city;
    config.avatarUri = avatarUri;
    return config;
  }

  static async saveConfig(config: UserConfig): Promise<void> {
    let context = GlobalContext.getContext();
    let store: preferences.Preferences = await preferences.getPreferences(context, ConfigService.STORE_NAME);
    await store.put(ConfigService.KEY_GOAL, config.goal);
    await store.put(ConfigService.KEY_FREQUENCY, config.frequency);
    await store.put(ConfigService.KEY_NICKNAME, config.nickname);
    await store.put(ConfigService.KEY_TTS_ENABLED, config.ttsEnabled);
    await store.put(ConfigService.KEY_BIO, config.bio);
    await store.put(ConfigService.KEY_CITY, config.city);
    await store.put(ConfigService.KEY_AVATAR_URI, config.avatarUri);
    await store.flush();
  }

  static async saveGoal(goal: string): Promise<void> {
    let context = GlobalContext.getContext();
    let store: preferences.Preferences = await preferences.getPreferences(context, ConfigService.STORE_NAME);
    await store.put(ConfigService.KEY_GOAL, goal);
    await store.flush();
    console.info(`[ConfigService] saveGoal: ${goal} saved successfully`);
  }

  static async saveFrequency(frequency: number): Promise<void> {
    let context = GlobalContext.getContext();
    let store: preferences.Preferences = await preferences.getPreferences(context, ConfigService.STORE_NAME);
    await store.put(ConfigService.KEY_FREQUENCY, frequency);
    await store.flush();
  }

  static async getTtsEnabled(): Promise<boolean> {
    let context = GlobalContext.getContext();
    let store: preferences.Preferences = await preferences.getPreferences(context, ConfigService.STORE_NAME);
    let enabled: boolean = await store.get(ConfigService.KEY_TTS_ENABLED, true) as boolean;
    return enabled;
  }

  static async setTtsEnabled(enabled: boolean): Promise<void> {
    let context = GlobalContext.getContext();
    let store: preferences.Preferences = await preferences.getPreferences(context, ConfigService.STORE_NAME);
    await store.put(ConfigService.KEY_TTS_ENABLED, enabled);
    await store.flush();
  }
}
