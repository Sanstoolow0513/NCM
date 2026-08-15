import { NcmHttp } from '../source/NcmHttp';
import { jArr, jNum, jStr } from '../source/json';
import { parseLrc, LyricLine, SongUrlInfo } from '../entity/models';

export class MediaRepository {
  private static instance: MediaRepository = new MediaRepository();

  static get(): MediaRepository {
    return MediaRepository.instance;
  }

  /**
   * 获取歌曲播放地址（eapi /api/song/enhance/player/url/v1），带音质回退：
   * 依次尝试 exhigh -> standard，返回第一个有效 url。
   */
  async songUrl(id: number): Promise<SongUrlInfo | null> {
    const levels: string[] = ['exhigh', 'standard'];
    for (const level of levels) {
      try {
        const p: Record<string, string> = {
          'ids': `[${id}]`, 'level': level, 'encodeType': 'aac'
        };
        const res = await NcmHttp.get().request('/api/song/enhance/player/url/v1', p, true, true);
        const obj = JSON.parse(res) as Object;
        if (jNum(obj, ['code']) === 200) {
          const arr = jArr(obj, ['data']);
          if (arr.length > 0) {
            const url = jStr(arr[0], ['url']);
            if (url.length > 0) {
              const info = new SongUrlInfo();
              info.id = id;
              info.url = url;
              info.br = jNum(arr[0], ['br']);
              info.level = jStr(arr[0], ['level'], level);
              return info;
            }
          }
        }
      } catch (e) {
        console.error(`[MediaRepository] songUrl(${id}, ${level}) failed: ${JSON.stringify(e)}`);
      }
    }
    return null;
  }

  async lyric(id: number): Promise<LyricLine[]> {
    const p: Record<string, string> = { 'id': id.toString(), 'lv': '-1', 'tv': '-1' };
    const res = await NcmHttp.get().request('/weapi/song/lyric', p, false, true);
    const obj = JSON.parse(res) as Object;
    if (jNum(obj, ['code']) === 200) {
      const lrc = jStr(obj, ['lrc', 'lyric']);
      const tlyric = jStr(obj, ['tlyric', 'lyric']);
      return parseLrc(lrc, tlyric);
    }
    return [];
  }
}
