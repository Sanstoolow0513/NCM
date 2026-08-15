import { CatalogRepository } from '../model/repository/CatalogRepository';
import { SongInfo } from '../model/entity/models';
import { PlayerService } from '../service/player/PlayerService';

/** 发现页日推预览条数 */
const PREVIEW_LIMIT: number = 6;

@ObservedV2
export class DailySongsViewModel {
  @Trace songs: SongInfo[] = [];
  @Trace previewSongs: SongInfo[] = [];
  @Trace loading: boolean = true;
  @Trace error: string = '';
  @Trace toastMessage: string = '';

  async load(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      this.songs = await CatalogRepository.get().dailyRecommendSongs();
      this.previewSongs = this.takeFirst(this.songs, PREVIEW_LIMIT);
    } catch (e) {
      console.error(`[DailySongsViewModel] load failed: ${JSON.stringify(e)}`);
      this.error = '加载失败，请稍后重试';
      this.previewSongs = [];
    }
    this.loading = false;
  }

  private takeFirst(songs: SongInfo[], limit: number): SongInfo[] {
    const out: SongInfo[] = [];
    const n: number = Math.min(limit, songs.length);
    for (let i = 0; i < n; i++) {
      out.push(songs[i]);
    }
    return out;
  }

  playAll(): void {
    PlayerService.get().playList(this.songs, 0);
    this.toastMessage = '开始播放';
  }

  playAt(songIndex: number): void {
    PlayerService.get().playList(this.songs, songIndex);
  }
}
