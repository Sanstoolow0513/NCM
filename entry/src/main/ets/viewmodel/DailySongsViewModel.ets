import { CatalogRepository } from '../model/repository/CatalogRepository';
import { SongInfo } from '../model/entity/models';
import { PlayerService } from '../service/player/PlayerService';

@ObservedV2
export class DailySongsViewModel {
  @Trace songs: SongInfo[] = [];
  @Trace heroSongs: SongInfo[] = [];
  @Trace loading: boolean = true;
  @Trace error: string = '';
  @Trace toastMessage: string = '';

  async load(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      this.songs = await CatalogRepository.get().dailyRecommendSongs();
      this.heroSongs = this.takeHeroSongs(this.songs);
    } catch (e) {
      console.error(`[DailySongsViewModel] load failed: ${JSON.stringify(e)}`);
      this.error = '加载失败，请稍后重试';
      this.heroSongs = [];
    }
    this.loading = false;
  }

  private takeHeroSongs(songs: SongInfo[]): SongInfo[] {
    const covers: SongInfo[] = [];
    const limit: number = Math.min(10, songs.length);
    for (let i = 0; i < limit; i++) {
      covers.push(songs[i]);
    }
    return covers;
  }

  playAll(): void {
    PlayerService.get().playList(this.songs, 0);
    this.toastMessage = '开始播放';
  }

  playAt(songIndex: number): void {
    PlayerService.get().playList(this.songs, songIndex);
  }
}
