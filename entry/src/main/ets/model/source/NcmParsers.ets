import { jArr, jGet, jNum, jStr } from './json';
import { LoginInfo, SongInfo, SongListInfo } from '../entity/models';

/** 登录类响应统一解析（code + profile），未登录/失败时 uid=0 */
export function parseLoginInfo(obj: Object): LoginInfo {
  const info = new LoginInfo();
  info.code = jNum(obj, ['code']);
  const profile = jGet(obj, ['profile']);
  if (profile !== null) {
    info.uid = jNum(profile, ['userId']);
    info.nickname = jStr(profile, ['nickname']);
    info.avatarUrl = jStr(profile, ['avatarUrl']);
    info.vipType = jNum(profile, ['vipType']);
  }
  return info;
}

/**
 * @param fromSearch true: 搜索结果结构（artists/album/duration）；false: 详情结构（ar/al/dt）
 */
export function parseSong(v: Object, fromSearch: boolean): SongInfo {
  const s = new SongInfo();
  s.id = jNum(v, ['id']);
  s.name = jStr(v, ['name']);
  const artists = fromSearch ? jArr(v, ['artists']) : jArr(v, ['ar']);
  const names: string[] = [];
  for (const ar of artists) {
    const n = jStr(ar, ['name']);
    if (n.length > 0) {
      names.push(n);
    }
  }
  s.singer = names.length > 0 ? names.join('/') : 'unknown';
  const albumKey = fromSearch ? 'album' : 'al';
  s.album = jStr(v, [albumKey, 'name'], 'unknown');
  s.albumId = jNum(v, [albumKey, 'id']);
  s.picUrl = jStr(v, [albumKey, 'picUrl']);
  s.duration = fromSearch ? jNum(v, ['duration']) : jNum(v, ['dt']);
  return s;
}

/** @param isAlbum true: 专辑结构（picUrl/artist.name）；false: 歌单结构（coverImgUrl/creator.nickname） */
export function parseSongList(v: Object, isAlbum: boolean): SongListInfo {
  const sl = new SongListInfo();
  sl.id = jNum(v, ['id']);
  sl.name = jStr(v, ['name']);
  if (isAlbum) {
    sl.coverImgUrl = jStr(v, ['picUrl']);
    sl.author = jStr(v, ['artist', 'name']);
  } else {
    sl.coverImgUrl = jStr(v, ['coverImgUrl']);
    sl.author = jStr(v, ['creator', 'nickname']);
    sl.creatorId = jNum(v, ['creator', 'userId']);
  }
  return sl;
}
