import { CatalogRepository } from '../model/repository/CatalogRepository';
import { PlayListDetail } from '../model/entity/models';
import { PlayerService } from '../service/player/PlayerService';

@ObservedV2
export class PlaylistDetailViewModel {
  @Trace detail: PlayListDetail | null = null;
  @Trace loading: boolean = true;
  @Trace error: string = '';
  @Trace toastMessage: string = '';
  listId: number = 0;
  isAlbum: boolean = false;

  configure(listId: number, isAlbum: boolean): void {
    this.listId = listId;
    this.isAlbum = isAlbum;
  }

  async load(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      const repo = CatalogRepository.get();
      this.detail = this.isAlbum ? await repo.albumDetail(this.listId) : await repo.playlistDetail(this.listId);
    } catch (e) {
      console.error(`[PlaylistDetailViewModel] load failed: ${JSON.stringify(e)}`);
      this.error = '加载失败，请稍后重试';
    }
    this.loading = false;
  }

  playAll(): void {
    if (this.detail !== null) {
      PlayerService.get().playList(this.detail.songs, 0);
      this.toastMessage = '开始播放';
    }
  }

  playAt(songIndex: number): void {
    if (this.detail !== null) {
      PlayerService.get().playList(this.detail.songs, songIndex);
    }
  }
}
