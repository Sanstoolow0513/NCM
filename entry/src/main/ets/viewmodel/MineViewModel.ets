import { CatalogRepository } from '../model/repository/CatalogRepository';
import { LoginInfo, SongListInfo } from '../model/entity/models';
import { StoreHub } from '../store/StoreHub';

@ObservedV2
export class MineViewModel {
  @Trace myPlaylists: SongListInfo[] = [];
  @Trace favPlaylists: SongListInfo[] = [];
  @Trace playlistsLoading: boolean = false;
  @Trace playlistsError: string = '';
  private loadedUid: number = 0;

  load(): void {
    const info = StoreHub.session().loginInfo;
    if (info !== null && info.uid > 0 && info.uid !== this.loadedUid) {
      this.loadMine(info.uid);
    }
  }

  onLoginChange(loginInfo: LoginInfo | null): void {
    if (loginInfo !== null && loginInfo.uid > 0) {
      if (loginInfo.uid !== this.loadedUid) {
        this.loadMine(loginInfo.uid);
      }
    } else {
      this.loadedUid = 0;
      this.myPlaylists = [];
      this.favPlaylists = [];
      this.playlistsError = '';
    }
  }

  async loadMine(uid: number): Promise<void> {
    this.playlistsLoading = true;
    this.playlistsError = '';
    try {
      const all = await CatalogRepository.get().userPlaylists(uid, 0, 100);
      const created: SongListInfo[] = [];
      const collected: SongListInfo[] = [];
      for (const pl of all) {
        if (pl.creatorId === uid) {
          created.push(pl);
        } else {
          collected.push(pl);
        }
      }
      this.myPlaylists = created;
      this.favPlaylists = collected;
      this.loadedUid = uid;
    } catch (e) {
      console.error(`[MineViewModel] load playlists failed: ${JSON.stringify(e)}`);
      this.playlistsError = '歌单加载失败，请稍后重试';
    }
    this.playlistsLoading = false;
  }

  retry(): void {
    const info = StoreHub.session().loginInfo;
    if (info !== null) {
      this.loadMine(info.uid);
    }
  }
}
