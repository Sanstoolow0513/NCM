import { CatalogRepository } from '../model/repository/CatalogRepository';
import { BannerInfo, SongListInfo } from '../model/entity/models';

@ObservedV2
export class DiscoverViewModel {
  @Trace banners: BannerInfo[] = [];
  @Trace playlists: SongListInfo[] = [];
  @Trace loading: boolean = true;
  @Trace error: string = '';

  async load(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      const repo = CatalogRepository.get();
      this.banners = await repo.banners();
      this.playlists = await repo.topSongLists(0, 30);
    } catch (e) {
      console.error(`[DiscoverViewModel] load failed: ${JSON.stringify(e)}`);
      this.error = '加载失败，请检查网络后重试';
    }
    this.loading = false;
  }
}
