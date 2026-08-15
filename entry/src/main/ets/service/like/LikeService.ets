/**
 * 红心服务：登录后拉取喜欢列表，列表行乐观切换，失败回滚。
 */
import { CatalogRepository } from '../../model/repository/CatalogRepository';
import { LoginInfo } from '../../model/entity/models';
import { StoreHub } from '../../store/StoreHub';
import { LikeSnapshot } from '../../store/LikeSnapshot';

export class LikeService {
  private static instance: LikeService = new LikeService();
  private pending: Set<number> = new Set();
  private loadedUid: number = 0;

  static get(): LikeService {
    return LikeService.instance;
  }

  private snap(): LikeSnapshot {
    return StoreHub.likes();
  }

  onSession(loginInfo: LoginInfo | null): void {
    if (loginInfo !== null && loginInfo.uid > 0) {
      this.load(loginInfo.uid);
    } else {
      this.loadedUid = 0;
      this.pending.clear();
      this.snap().clear();
    }
  }

  toggle(songId: number): void {
    if (songId === 0) {
      return;
    }
    const info = StoreHub.session().loginInfo;
    if (info === null || info.uid <= 0) {
      StoreHub.player().showToast('请先登录');
      return;
    }
    if (this.pending.has(songId)) {
      return;
    }
    const nextLiked: boolean = !this.snap().has(songId);
    this.pending.add(songId);
    this.snap().setLiked(songId, nextLiked);
    this.commit(songId, nextLiked);
  }

  private async load(uid: number): Promise<void> {
    if (uid === this.loadedUid) {
      return;
    }
    this.loadedUid = uid;
    try {
      const ids = await CatalogRepository.get().likedIds(uid);
      if (this.loadedUid === uid) {
        this.snap().replaceAll(ids);
      }
    } catch (e) {
      console.error(`[LikeService] load failed: ${JSON.stringify(e)}`);
      if (this.loadedUid === uid) {
        this.loadedUid = 0;
      }
    }
  }

  private async commit(songId: number, liked: boolean): Promise<void> {
    try {
      await CatalogRepository.get().setSongLike(songId, liked);
    } catch (e) {
      console.error(`[LikeService] setLike failed: ${JSON.stringify(e)}`);
      this.snap().setLiked(songId, !liked);
      StoreHub.player().showToast(liked ? '红心失败' : '取消红心失败');
    } finally {
      this.pending.delete(songId);
    }
  }
}
