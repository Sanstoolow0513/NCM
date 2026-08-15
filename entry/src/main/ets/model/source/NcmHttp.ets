/*
 * NCM HTTP 源：weapi / eapi 统一 POST、Cookie 与 csrf。
 * 业务解析在 Repository，加密在 crypto.ets。
 */
import { http } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
import { eapi, weapi } from './crypto';
import { CookieJar } from './cookiejar';

const BASE_URL = 'https://music.163.com';
const EAPI_BASE = 'https://interface.music.163.com';
const USER_AGENT =
  'Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) ' +
  'Version/9.0 Mobile/13B143 Safari/601.1';

export class NcmHttp {
  private static instance: NcmHttp = new NcmHttp();
  private jar: CookieJar = new CookieJar();
  private csrf: string = '';

  static get(): NcmHttp {
    return NcmHttp.instance;
  }

  init(context: common.UIAbilityContext): void {
    this.jar.init(context);
    this.csrf = this.jar.get('__csrf');
  }

  isLoggedIn(): boolean {
    return this.jar.get('MUSIC_U').length > 0;
  }

  clearLogin(): void {
    this.jar.clear();
    this.csrf = '';
  }

  persistSession(): void {
    this.csrf = this.jar.get('__csrf');
    this.jar.save();
  }

  private cookieHeader(): string {
    const jarStr = this.jar.headerValue();
    return jarStr.length > 0 ? `${this.jar.getDeviceCookie()}; ${jarStr}` : this.jar.getDeviceCookie();
  }

  /**
   * 统一请求入口（POST）。
   * @param path 原始路径（/weapi/... 或 /api/...）
   * @param params 业务参数（全部字符串，csrf_token 由本函数注入）
   * @param useEapi true 走 eapi（interface.music.163.com + AES-ECB），false 走 weapi
   * @param shouldContinue 发送请求及写入响应 Cookie 前的可选有效性校验
   */
  async request(
    path: string,
    params: Record<string, string>,
    useEapi: boolean,
    appendCsrf: boolean,
    shouldContinue: (() => boolean) | null = null
  ): Promise<string> {
    if (this.csrf.length === 0) {
      this.csrf = this.jar.get('__csrf');
    }
    const csrfSeparator: string = path.indexOf('?') >= 0 ? '&' : '?';
    let url = appendCsrf ? `${BASE_URL}${path}${csrfSeparator}csrf_token=${this.csrf}` : `${BASE_URL}${path}`;
    params['csrf_token'] = this.csrf;
    let body: string;
    if (useEapi) {
      const data: Record<string, Object> = {};
      for (const k of Object.keys(params)) {
        data[k] = params[k];
      }
      const nowMs = Date.now();
      const header: Record<string, Object> = {
        'osver': '16.2',
        'deviceId': '',
        'os': 'iPhone OS',
        'appver': '9.0.90',
        'versioncode': '140',
        'mobilename': '',
        'buildver': nowMs.toString().substring(0, 10),
        'resolution': '1920x1080',
        '__csrf': this.csrf,
        'channel': '',
        'requestId': `${nowMs}_${Math.floor(Math.random() * 1000).toString().padStart(4, '0')}`
      };
      data['header'] = header;
      const eapiPath = path.replace('/api', '/eapi');
      url = `${EAPI_BASE}${eapiPath}`;
      body = await eapi(path, JSON.stringify(data));
    } else {
      body = await weapi(JSON.stringify(params));
    }
    if (shouldContinue !== null && !shouldContinue()) {
      throw new Error('请求已失效');
    }

    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': this.cookieHeader(),
          'Referer': 'https://music.163.com',
          'User-Agent': USER_AGENT,
          'Accept': '*/*'
        },
        extraData: body,
        connectTimeout: 15000,
        readTimeout: 15000
      });
      if (shouldContinue !== null && !shouldContinue()) {
        throw new Error('请求已失效');
      }
      const respHeader = response.header as Record<string, Object>;
      const sc: Object | undefined = respHeader['set-cookie'];
      const setCookies: string[] = [];
      if (sc !== undefined && sc !== null) {
        if (Array.isArray(sc)) {
          for (const v of sc as Object[]) {
            setCookies.push(String(v));
          }
        } else if (typeof sc === 'string') {
          setCookies.push(sc);
        }
      }
      this.jar.storeFromSetCookie(setCookies);
      if (path.indexOf('login') >= 0 || path.indexOf('nuser') >= 0 || path.indexOf('captcha') >= 0) {
        console.info(`[NcmLogin] ${path} http=${response.responseCode} setCookies=${JSON.stringify(setCookies)}`);
        console.info(`[NcmLogin] ${path} body=${typeof response.result === 'string' ? response.result : JSON.stringify(response.result)}`);
        console.info(`[NcmLogin] jar MUSIC_U=${this.jar.get('MUSIC_U').length > 0 ? 'SET' : 'MISSING'} __csrf=${this.jar.get('__csrf').length > 0 ? 'SET' : 'MISSING'}`);
      }
      if (typeof response.result === 'string') {
        return response.result;
      }
      return JSON.stringify(response.result);
    } finally {
      httpRequest.destroy();
    }
  }
}
