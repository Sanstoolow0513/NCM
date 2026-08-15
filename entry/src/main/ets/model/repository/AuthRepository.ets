import { NcmHttp } from '../source/NcmHttp';
import { jNum, jStr } from '../source/json';
import { parseLoginInfo } from '../source/NcmParsers';
import { LoginInfo, QrCheckResult } from '../entity/models';

export class AuthRepository {
  private static instance: AuthRepository = new AuthRepository();

  static get(): AuthRepository {
    return AuthRepository.instance;
  }

  isLoggedIn(): boolean {
    return NcmHttp.get().isLoggedIn();
  }

  clearLogin(): void {
    NcmHttp.get().clearLogin();
  }

  /** 生成扫码登录 unikey（二维码内容为 https://music.163.com/login?codekey={unikey}） */
  async qrCreateKey(): Promise<string> {
    const p: Record<string, string> = { 'type': '1' };
    const res = await NcmHttp.get().request('/weapi/login/qrcode/unikey', p, false, true);
    const obj = JSON.parse(res) as Object;
    if (jNum(obj, ['code']) === 200) {
      return jStr(obj, ['unikey']);
    }
    throw new Error('获取登录二维码失败');
  }

  /** 轮询二维码状态：800 过期 / 801 等待扫码 / 802 待确认 / 803 登录成功 */
  async qrCheck(key: string): Promise<QrCheckResult> {
    const p: Record<string, string> = { 'type': '1', 'key': key };
    const res = await NcmHttp.get().request('/weapi/login/qrcode/client/login', p, false, true);
    const obj = JSON.parse(res) as Object;
    const r = new QrCheckResult();
    r.code = jNum(obj, ['code']);
    r.message = jStr(obj, ['message']);
    if (r.code === 803) {
      NcmHttp.get().persistSession();
    }
    return r;
  }

  /** 查询登录状态；未登录时 code=200 但 profile 为空（此时返回 uid=0） */
  async loginStatus(): Promise<LoginInfo> {
    const p: Record<string, string> = {};
    const res = await NcmHttp.get().request('/api/nuser/account/get', p, false, true);
    return parseLoginInfo(JSON.parse(res) as Object);
  }

  async captchaSend(ctcode: string, phone: string): Promise<void> {
    const p: Record<string, string> = {
      'cellphone': phone, 'ctcode': ctcode, 'secrete': 'music_middleuser_pclogin'
    };
    const res = await NcmHttp.get().request('/weapi/sms/captcha/sent', p, false, true);
    const obj = JSON.parse(res) as Object;
    if (jNum(obj, ['code']) !== 200 && jStr(obj, ['data']) !== 'true') {
      const msg = jStr(obj, ['message']);
      throw new Error(msg.length > 0 ? msg : `发送验证码失败 code=${jNum(obj, ['code'])}`);
    }
  }

  async loginCellphoneCaptcha(ctcode: string, phone: string, captcha: string): Promise<LoginInfo> {
    const p: Record<string, string> = {
      'phone': phone, 'countrycode': ctcode, 'type': '1',
      'https': 'true', 'remember': 'true', 'captcha': captcha
    };
    const res = await NcmHttp.get().request('/weapi/w/login/cellphone', p, false, true);
    return this.finishLogin(res);
  }

  async loginCellphonePassword(phone: string, password: string): Promise<LoginInfo> {
    const p: Record<string, string> = {
      'phone': phone, 'password': password, 'rememberLogin': 'true'
    };
    const res = await NcmHttp.get().request('/weapi/login/cellphone', p, false, true);
    return this.finishLogin(res);
  }

  private finishLogin(res: string): LoginInfo {
    const obj = JSON.parse(res) as Object;
    const info = parseLoginInfo(obj);
    if (info.code === 200 && info.uid > 0) {
      NcmHttp.get().persistSession();
      return info;
    }
    let msg = jStr(obj, ['msg']);
    if (msg.length === 0) {
      msg = jStr(obj, ['message']);
    }
    throw new Error(msg.length > 0 ? msg : `登录失败 code=${info.code}`);
  }

  async logout(): Promise<void> {
    try {
      const p: Record<string, string> = {};
      await NcmHttp.get().request('/weapi/logout', p, false, true);
    } catch (e) {
      console.error(`[AuthRepository] logout request failed: ${JSON.stringify(e)}`);
    }
    NcmHttp.get().clearLogin();
  }
}
