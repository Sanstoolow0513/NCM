import { SearchRepository } from '../model/repository/SearchRepository';
import { SongInfo, SongListInfo } from '../model/entity/models';
import { PlayerService } from '../service/player/PlayerService';

@ObservedV2
export class SearchViewModel {
  @Trace keyword: string = '';
  @Trace tab: number = 0;
  @Trace songs: SongInfo[] = [];
  @Trace lists: SongListInfo[] = [];
  @Trace loading: boolean = false;
  @Trace searched: boolean = false;
  @Trace toastMessage: string = '';

  onKeywordChange(value: string): void {
    this.keyword = value;
    if (value.trim().length === 0) {
      this.searched = false;
      this.loading = false;
    }
  }

  async selectTab(index: number): Promise<void> {
    this.tab = index;
    if (this.keyword.length > 0) {
      await this.doSearch(this.keyword);
    }
  }

  async doSearch(kw: string): Promise<void> {
    const query = kw.trim();
    if (query.length === 0) {
      return;
    }
    this.keyword = query;
    this.loading = true;
    this.searched = true;
    try {
      const repo = SearchRepository.get();
      if (this.tab === 0) {
        this.songs = await repo.searchSongs(query, 0, 50);
      } else if (this.tab === 1) {
        this.lists = await repo.searchPlaylists(query, 0, 50);
      } else {
        this.lists = await repo.searchAlbums(query, 0, 50);
      }
    } catch (e) {
      console.error(`[SearchViewModel] search failed: ${JSON.stringify(e)}`);
      this.toastMessage = '搜索失败，请稍后重试';
    }
    this.loading = false;
  }

  playAt(songIndex: number): void {
    PlayerService.get().playList(this.songs, songIndex);
  }
}
