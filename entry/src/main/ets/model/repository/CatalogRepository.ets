import { NcmHttp } from '../source/NcmHttp';
import { jArr, jNum, jNumArr, jStr } from '../source/json';
import { parseSong, parseSongList } from '../source/NcmParsers';
import { BannerInfo, PlayListDetail, SongInfo, SongListInfo } from '../entity/models';

export class CatalogRepository {
  private static instance: CatalogRepository = new CatalogRepository();

  static get(): CatalogRepository {
    return CatalogRepository.instance;
  }

  async banners(): Promise<BannerInfo[]> {
    const p: Record<string, string> = { 'clientType': 'pc' };
    const res = await NcmHttp.get().request('/weapi/v2/banner/get', p, false, true);
    const obj = JSON.parse(res) as Object;
    const out: BannerInfo[] = [];
    if (jNum(obj, ['code']) === 200) {
      for (const v of jArr(obj, ['banners'])) {
        const b = new BannerInfo();
        b.pic = jStr(v, ['imageUrl']);
        b.targetId = jNum(v, ['targetId']);
        b.targetType = jNum(v, ['targetType']);
        if (b.pic.length > 0) {
          out.push(b);
        }
      }
    }
    return out;
  }

  async topSongLists(offset: number, limit: number): Promise<SongListInfo[]> {
    const p: Record<string, string> = {
      'cat': '全部', 'order': 'hot', 'total': 'true',
      'offset': offset.toString(), 'limit': limit.toString()
    };
    const res = await NcmHttp.get().request('/weapi/playlist/list', p, false, true);
    const obj = JSON.parse(res) as Object;
    const out: SongListInfo[] = [];
    if (jNum(obj, ['code']) === 200) {
      for (const v of jArr(obj, ['playlists'])) {
        out.push(parseSongList(v, false));
      }
    }
    return out;
  }

  async userPlaylists(uid: number, offset: number, limit: number): Promise<SongListInfo[]> {
    const p: Record<string, string> = {
      'uid': uid.toString(), 'offset': offset.toString(), 'limit': limit.toString()
    };
    const res = await NcmHttp.get().request('/weapi/user/playlist', p, false, true);
    const obj = JSON.parse(res) as Object;
    const out: SongListInfo[] = [];
    if (jNum(obj, ['code']) === 200) {
      for (const v of jArr(obj, ['playlist'])) {
        out.push(parseSongList(v, false));
      }
    }
    return out;
  }

  async dailyRecommendSongs(): Promise<SongInfo[]> {
    const p: Record<string, string> = { 'total': 'true' };
    const res = await NcmHttp.get().request('/weapi/v1/discovery/recommend/songs', p, false, true);
    const obj = JSON.parse(res) as Object;
    if (jNum(obj, ['code']) !== 200) {
      throw new Error(`获取每日推荐失败 code=${jNum(obj, ['code'])}`);
    }
    const out: SongInfo[] = [];
    for (const v of jArr(obj, ['recommend'])) {
      out.push(parseSong(v, true));
    }
    return out;
  }

  async playlistDetail(id: number): Promise<PlayListDetail> {
    const p: Record<string, string> = {
      'id': id.toString(), 'offset': '0', 'total': 'true', 'limit': '1000', 'n': '1000'
    };
    const res = await NcmHttp.get().request('/weapi/v6/playlist/detail', p, false, true);
    const obj = JSON.parse(res) as Object;
    if (jNum(obj, ['code']) !== 200) {
      throw new Error(`获取歌单详情失败 code=${jNum(obj, ['code'])}`);
    }
    const detail = new PlayListDetail();
    detail.id = jNum(obj, ['playlist', 'id']);
    detail.name = jStr(obj, ['playlist', 'name']);
    detail.coverImgUrl = jStr(obj, ['playlist', 'coverImgUrl']);
    detail.description = jStr(obj, ['playlist', 'description']);
    let tracks = jArr(obj, ['songs']);
    if (tracks.length === 0) {
      tracks = jArr(obj, ['playlist', 'tracks']);
    }
    for (const v of tracks) {
      detail.songs.push(parseSong(v, false));
    }
    return detail;
  }

  async albumDetail(id: number): Promise<PlayListDetail> {
    const p: Record<string, string> = {};
    const res = await NcmHttp.get().request(`/weapi/v1/album/${id}`, p, false, false);
    const obj = JSON.parse(res) as Object;
    if (jNum(obj, ['code']) !== 200) {
      throw new Error(`获取专辑详情失败 code=${jNum(obj, ['code'])}`);
    }
    const detail = new PlayListDetail();
    detail.id = jNum(obj, ['album', 'id']);
    detail.name = jStr(obj, ['album', 'name']);
    detail.coverImgUrl = jStr(obj, ['album', 'picUrl']);
    detail.description = jStr(obj, ['album', 'description']);
    for (const v of jArr(obj, ['songs'])) {
      const s = parseSong(v, false);
      if (s.album.length === 0 || s.album === 'unknown') {
        s.album = detail.name;
      }
      if (s.picUrl.length === 0) {
        s.picUrl = detail.coverImgUrl;
      }
      detail.songs.push(s);
    }
    return detail;
  }

  /** 当前账号喜欢的歌曲 id（无序） */
  async likedIds(uid: number, shouldContinue: (() => boolean) | null = null): Promise<number[]> {
    const p: Record<string, string> = { 'uid': uid.toString() };
    const res = await NcmHttp.get().request('/weapi/song/like/get', p, false, true, shouldContinue);
    const obj = JSON.parse(res) as Object;
    if (jNum(obj, ['code']) !== 200) {
      throw new Error(`获取喜欢列表失败 code=${jNum(obj, ['code'])}`);
    }
    return jNumArr(obj, ['ids']);
  }

  /** 红心 / 取消红心，写入「我喜欢的音乐」 */
  async setSongLike(trackId: number, like: boolean, shouldContinue: (() => boolean) | null = null): Promise<void> {
    const trackIdValue: string = trackId.toString();
    const likeValue: string = like ? 'true' : 'false';
    const p: Record<string, string> = {
      'alg': 'itembased',
      'trackId': trackIdValue,
      'like': likeValue,
      'time': '25'
    };
    const path: string = `/weapi/radio/like?alg=itembased&trackId=${trackIdValue}&like=${likeValue}&time=25`;
    const res = await NcmHttp.get().request(path, p, false, true, shouldContinue);
    const obj = JSON.parse(res) as Object;
    if (jNum(obj, ['code']) !== 200) {
      throw new Error(`红心操作失败 code=${jNum(obj, ['code'])}`);
    }
  }
}
