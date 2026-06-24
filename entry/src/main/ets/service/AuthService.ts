// entry/src/main/ets/service/AuthService.ts
import { preferences } from '@kit.ArkData';
import { GlobalContext } from '../common/GlobalContext';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';

const DOMAIN = 0x0000;
const TAG = 'AuthService';

export class AuthService {
  private static STORE_NAME: string = 'user_config';
  private static KEY_IS_LOGGED_IN: string = 'isLoggedIn';
  private static KEY_USERNAME: string = 'loginUsername';
  private static KEY_PASSWORD: string = 'loginPassword';

  private static DEFAULT_USERNAME: string = '8008123049';
  private static DEFAULT_PASSWORD: string = '123456';

  /** 密码哈希（SHA-256），演示用；生产环境应使用 salt + 慢哈希 */
  private static async hashPassword(password: string): Promise<string> {
    let md = cryptoFramework.createMd('SHA256');
    let encoder = new util.TextEncoder();
    let input = { data: encoder.encodeInto(password) };
    await md.update(input);
    let result = await md.digest();
    // 将字节数组转换为十六进制字符串
    let hexString = '';
    for (let i = 0; i < result.data.length; i++) {
      hexString += result.data[i].toString(16).padStart(2, '0');
    }
    return hexString;
  }

  /** 确保预设账号已初始化 */
  private static async ensureDefaultAccount(store: preferences.Preferences): Promise<void> {
    let existingUser: string = await store.get(AuthService.KEY_USERNAME, '') as string;
    if (existingUser.length === 0) {
      await store.put(AuthService.KEY_USERNAME, AuthService.DEFAULT_USERNAME);
      await store.put(AuthService.KEY_PASSWORD, await AuthService.hashPassword(AuthService.DEFAULT_PASSWORD));
      await store.flush();
      hilog.info(DOMAIN, TAG, 'default account initialized');
    }
  }

  /** 检查是否已登录 */
  static async isLoggedIn(): Promise<boolean> {
    try {
      let context = GlobalContext.getContext();
      let store: preferences.Preferences = await preferences.getPreferences(context, AuthService.STORE_NAME);
      await AuthService.ensureDefaultAccount(store);
      let loggedIn: boolean = await store.get(AuthService.KEY_IS_LOGGED_IN, false) as boolean;
      return loggedIn;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'isLoggedIn failed: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  /** 获取当前登录的用户名 */
  static async getUsername(): Promise<string> {
    let context = GlobalContext.getContext();
    let store: preferences.Preferences = await preferences.getPreferences(context, AuthService.STORE_NAME);
    return await store.get(AuthService.KEY_USERNAME, '') as string;
  }

  /** 注册新账号 */
  static async register(username: string, password: string): Promise<boolean> {
    let context = GlobalContext.getContext();
    let store: preferences.Preferences = await preferences.getPreferences(context, AuthService.STORE_NAME);

    // 检查是否已注册
    let existingUser: string = await store.get(AuthService.KEY_USERNAME, '') as string;
    if (existingUser.length > 0) {
      hilog.warn(DOMAIN, TAG, 'account already exists');
      return false;
    }

    await store.put(AuthService.KEY_USERNAME, username);
    await store.put(AuthService.KEY_PASSWORD, await AuthService.hashPassword(password));
    await store.put(AuthService.KEY_IS_LOGGED_IN, true);
    await store.flush();
    hilog.info(DOMAIN, TAG, 'register success');
    return true;
  }

  /** 登录验证 */
  static async login(username: string, password: string): Promise<boolean> {
    let context = GlobalContext.getContext();
    let store: preferences.Preferences = await preferences.getPreferences(context, AuthService.STORE_NAME);

    await AuthService.ensureDefaultAccount(store);

    let savedUser: string = await store.get(AuthService.KEY_USERNAME, '') as string;
    let savedPass: string = await store.get(AuthService.KEY_PASSWORD, '') as string;

    let hashedPassword = await AuthService.hashPassword(password);
    if (username === savedUser && hashedPassword === savedPass) {
      await store.put(AuthService.KEY_IS_LOGGED_IN, true);
      await store.flush();
      hilog.info(DOMAIN, TAG, 'login success');
      return true;
    }

    hilog.warn(DOMAIN, TAG, 'login failed: wrong credentials');
    return false;
  }

  /** 退出登录 */
  static async logout(): Promise<void> {
    let context = GlobalContext.getContext();
    let store: preferences.Preferences = await preferences.getPreferences(context, AuthService.STORE_NAME);
    await store.put(AuthService.KEY_IS_LOGGED_IN, false);
    await store.flush();
    hilog.info(DOMAIN, TAG, 'logout success');
  }

  /** 注销账号（清除所有账号数据） */
  static async deleteAccount(): Promise<void> {
    let context = GlobalContext.getContext();
    let store: preferences.Preferences = await preferences.getPreferences(context, AuthService.STORE_NAME);
    await store.delete(AuthService.KEY_IS_LOGGED_IN);
    await store.delete(AuthService.KEY_USERNAME);
    await store.delete(AuthService.KEY_PASSWORD);
    await store.flush();
    hilog.info(DOMAIN, TAG, 'account deleted');
  }
}
