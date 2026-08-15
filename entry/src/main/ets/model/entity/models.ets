/*
 * 数据模型与歌词解析。
 * 字段与 ncm-core 的 model.rs 对齐（id/name/singer/album/picUrl/duration 等）。
 * DTO 保持普通 class：UI 通过 ViewModel 整引用替换刷新，不在此层加 @ObservedV2。
 */

export class SongInfo {
  id: number = 0;
  name: string = '';
  singer: string = '';
  album: string = '';
  albumId: number = 0;
  picUrl: string = '';
  /** 时长（毫秒） */
  duration: number = 0;
}

export class SongListInfo {
  id: number = 0;
  name: string = '';
  coverImgUrl: string = '';
  author: string = '';
  /** 创建者用户 id（用于区分"我创建的"与"我收藏的"歌单） */
  creatorId: number = 0;
}

export class PlayListDetail {
  id: number = 0;
  name: string = '';
  coverImgUrl: string = '';
  description: string = '';
  songs: SongInfo[] = [];
}

export class SongUrlInfo {
  id: number = 0;
  url: string = '';
  br: number = 0;
  level: string = '';
}

export class LoginInfo {
  code: number = 0;
  uid: number = 0;
  nickname: string = '';
  avatarUrl: string = '';
  vipType: number = 0;
}

export class BannerInfo {
  pic: string = '';
  targetId: number = 0;
  targetType: number = 0;
}

export class LyricLine {
  timeMs: number = 0;
  text: string = '';
  tText: string = '';
}

export class QrCheckResult {
  code: number = 0;
  message: string = '';
}

class ParsedStamp {
  timeMs: number = 0;
  text: string = '';
}

/**
 * 解析单行 LRC，返回该行携带的全部时间戳（一行多时间戳时返回多条）。
 * 同时兼容异常格式 [mm:ss:xx]（先归一化为 [mm:ss.xx]）。
 */
function parseLrcLine(line: string): ParsedStamp[] {
  const fixed = line.replace(/\[(\d{1,2}):(\d{2}):(\d{1,3})\]/g, '[$1:$2.$3]');
  const re = /\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]/g;
  const text = fixed.replace(re, '').trim();
  const out: ParsedStamp[] = [];
  let m: RegExpExecArray | null = re.exec(fixed);
  while (m !== null) {
    const min = parseInt(m[1]);
    const sec = parseInt(m[2]);
    let frac = 0;
    if (m[3] !== undefined) {
      const f = m[3];
      const n = parseInt(f);
      frac = f.length === 1 ? n * 100 : (f.length === 2 ? n * 10 : n);
    }
    const p = new ParsedStamp();
    p.timeMs = min * 60000 + sec * 1000 + frac;
    p.text = text;
    out.push(p);
    m = re.exec(fixed);
  }
  return out;
}

/**
 * 解析歌词并合并翻译：翻译行按相同时间戳并入主歌词（与 ncm-core lyrics.rs 的合并策略一致）。
 */
export function parseLrc(lrc: string, tlyric: string): LyricLine[] {
  const tMap = new Map<number, string>();
  for (const line of tlyric.split('\n')) {
    for (const p of parseLrcLine(line)) {
      if (p.text.length > 0) {
        tMap.set(p.timeMs, p.text);
      }
    }
  }
  const result: LyricLine[] = [];
  for (const line of lrc.split('\n')) {
    for (const p of parseLrcLine(line)) {
      if (p.text.length === 0) {
        continue;
      }
      const ll = new LyricLine();
      ll.timeMs = p.timeMs;
      ll.text = p.text;
      ll.tText = tMap.get(p.timeMs) ?? '';
      result.push(ll);
    }
  }
  result.sort((a, b) => a.timeMs - b.timeMs);
  return result;
}
