/*
 * Cookie 管理：对应桌面版 ncm-core 的 cookie_store 持久化方案。
 * 所有请求只面向 music.163.com，因此简化为单一域的 name=value 映射，
 * 持久化到应用沙箱 filesDir/cookies.json；设备标识 Cookie 生成一次后持久化。
 */
import { fileIo as fs } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';

const COOKIE_FILE = '/cookies.json';
const DEVICE_COOKIE_FILE = '/device_cookie.txt';
/** Set-Cookie 属性名（解析时需要跳过的键） */
const ATTR_NAMES: string[] = [
  'path', 'domain', 'expires', 'max-age', 'httponly', 'secure', 'samesite', 'version', 'priority', 'partitioned'
];

function randomHex(len: number): string {
  const chars = '0123456789abcdef';
  let out = '';
  for (let i = 0; i < len; i++) {
    out += chars.charAt(Math.floor(Math.random() * 16));
  }
  return out;
}

export class CookieJar {
  private cookies: Map<string, string> = new Map();
  private cookieFile: string = '';
  private deviceCookie: string = '';

  init(context: common.UIAbilityContext): void {
    this.cookieFile = context.filesDir + COOKIE_FILE;
    this.load();
    this.initDeviceCookie(context.filesDir + DEVICE_COOKIE_FILE);
  }

  private initDeviceCookie(path: string): void {
    try {
      if (fs.accessSync(path)) {
        this.deviceCookie = this.readTextFile(path);
      }
    } catch (e) {
      console.error(`[CookieJar] read device cookie failed: ${JSON.stringify(e)}`);
    }
    if (this.deviceCookie.length === 0) {
      // 与 ncm-api build_cookie 的结构一致：os/appver/osver + 随机设备标识
      const now = Date.now().toString();
      const nuid = `${randomHex(16)}${randomHex(16)}`;
      const wnmcid = `${randomHex(6)}.${now}`;
      const nmtid = randomHex(16);
      this.deviceCookie =
        `os=pc; appver=2.7.1.198277; osver=10; deviceId=; WEVNSM=1.0.0; WNMCID=${wnmcid}; ` +
        `_ntes_nnid=${nuid},${now}; _ntes_nuid=${nuid}; NMTID=${nmtid}; __remember_me=true; channel=`;
      try {
        this.writeTextFile(path, this.deviceCookie);
      } catch (e) {
        console.error(`[CookieJar] write device cookie failed: ${JSON.stringify(e)}`);
      }
    }
  }

  getDeviceCookie(): string {
    return this.deviceCookie;
  }

  get(name: string): string {
    return this.cookies.get(name) ?? '';
  }

  headerValue(): string {
    const parts: string[] = [];
    this.cookies.forEach((v, k) => {
      if (v.length > 0) {
        parts.push(`${k}=${v}`);
      }
    });
    return parts.join('; ');
  }

  /**
   * 从 response.header['set-cookie'] 中提取 Cookie。
   * 注意：OHOS 的 HttpResponse.cookies 是 Netscape cookie 文件格式（Tab 分隔），不是 Set-Cookie
   * 格式，不能用它解析；set-cookie 响应头才是标准的独立字符串数组（多值不合并）。
   * 每条 Set-Cookie 的第一个 name=value 段即 Cookie 本体，后续为 Path/Expires 等属性。
   */
  storeFromSetCookie(list: string[]): void {
    if (list.length === 0) {
      return;
    }
    let changed = false;
    for (const sc of list) {
      const firstSemi = sc.indexOf(';');
      const pair = (firstSemi >= 0 ? sc.substring(0, firstSemi) : sc).trim();
      const eq = pair.indexOf('=');
      if (eq <= 0) {
        continue;
      }
      const name = pair.substring(0, eq).trim();
      const value = pair.substring(eq + 1).trim();
      if (ATTR_NAMES.indexOf(name.toLowerCase()) >= 0) {
        continue;
      }
      if (value.length === 0 || value === 'deleted') {
        if (this.cookies.has(name)) {
          this.cookies.delete(name);
          changed = true;
        }
        continue;
      }
      const old = this.cookies.get(name);
      if (old !== value) {
        this.cookies.set(name, value);
        changed = true;
      }
    }
    if (changed) {
      this.save();
    }
  }

  clear(): void {
    this.cookies.clear();
    try {
      if (fs.accessSync(this.cookieFile)) {
        fs.unlinkSync(this.cookieFile);
      }
    } catch (e) {
      console.error(`[CookieJar] clear failed: ${JSON.stringify(e)}`);
    }
  }

  private load(): void {
    try {
      if (!fs.accessSync(this.cookieFile)) {
        return;
      }
      const text = this.readTextFile(this.cookieFile);
      const obj = JSON.parse(text) as Record<string, string>;
      for (const k of Object.keys(obj)) {
        this.cookies.set(k, obj[k]);
      }
    } catch (e) {
      console.error(`[CookieJar] load failed: ${JSON.stringify(e)}`);
    }
  }

  save(): void {
    try {
      const obj: Record<string, string> = {};
      this.cookies.forEach((v, k) => {
        obj[k] = v;
      });
      this.writeTextFile(this.cookieFile, JSON.stringify(obj));
    } catch (e) {
      console.error(`[CookieJar] save failed: ${JSON.stringify(e)}`);
    }
  }

  private readTextFile(path: string): string {
    const file = fs.openSync(path, fs.OpenMode.READ_ONLY);
    try {
      const buf = new ArrayBuffer(128 * 1024);
      const len = fs.readSync(file.fd, buf);
      return util.TextDecoder.create('utf-8').decodeToString(new Uint8Array(buf, 0, len)).trim();
    } finally {
      fs.closeSync(file);
    }
  }

  private writeTextFile(path: string, content: string): void {
    const file = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
    try {
      fs.writeSync(file.fd, content);
    } finally {
      fs.closeSync(file);
    }
  }
}
