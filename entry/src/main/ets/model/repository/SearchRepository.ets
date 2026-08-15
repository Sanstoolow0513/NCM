import { NcmHttp } from '../source/NcmHttp';
import { jArr, jNum } from '../source/json';
import { parseSong, parseSongList } from '../source/NcmParsers';
import { SongInfo, SongListInfo } from '../entity/models';

export class SearchRepository {
  private static instance: SearchRepository = new SearchRepository();

  static get(): SearchRepository {
    return SearchRepository.instance;
  }

  private async search(keywords: string, type: string, offset: number, limit: number): Promise<Object> {
    const p: Record<string, string> = {
      's': keywords, 'type': type, 'offset': offset.toString(), 'limit': limit.toString()
    };
    const res = await NcmHttp.get().request('/weapi/search/get', p, false, true);
    return JSON.parse(res) as Object;
  }

  async searchSongs(keywords: string, offset: number, limit: number): Promise<SongInfo[]> {
    const obj = await this.search(keywords, '1', offset, limit);
    const out: SongInfo[] = [];
    if (jNum(obj, ['code']) === 200) {
      for (const v of jArr(obj, ['result', 'songs'])) {
        out.push(parseSong(v, true));
      }
    }
    return out;
  }

  async searchPlaylists(keywords: string, offset: number, limit: number): Promise<SongListInfo[]> {
    const obj = await this.search(keywords, '1000', offset, limit);
    const out: SongListInfo[] = [];
    if (jNum(obj, ['code']) === 200) {
      for (const v of jArr(obj, ['result', 'playlists'])) {
        out.push(parseSongList(v, false));
      }
    }
    return out;
  }

  async searchAlbums(keywords: string, offset: number, limit: number): Promise<SongListInfo[]> {
    const obj = await this.search(keywords, '10', offset, limit);
    const out: SongListInfo[] = [];
    if (jNum(obj, ['code']) === 200) {
      for (const v of jArr(obj, ['result', 'albums'])) {
        out.push(parseSongList(v, true));
      }
    }
    return out;
  }
}
