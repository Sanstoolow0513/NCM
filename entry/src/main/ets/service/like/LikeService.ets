/**
 * 红心服务：登录后拉取喜欢列表，列表行乐观切换，失败回滚。
 */
import { CatalogRepository } from '../../model/repository/CatalogRepository';
import { LoginInfo } from '../../model/entity/models';
import { StoreHub } from '../../store/StoreHub';
import { LikeSnapshot } from '../../store/LikeSnapshot';

export class LikeService {
  private static instance: LikeService = new LikeService();
  /** 尚未与当前会话的喜欢列表合并的乐观覆盖层。 */
  private pending: Map<number, boolean> = new Map<number, boolean>();
  /** 正在提交的歌曲，避免同一首歌重复发请求。 */
  private committing: Set<number> = new Set<number>();
  private activeUid: number = 0;
  private sessionGeneration: number = 0;
  private loadingGeneration: number = 0;
  private likesReady: boolean = false;

  static get(): LikeService {
    return LikeService.instance;
  }

  private snap(): LikeSnapshot {
    return StoreHub.likes();
  }

  private isCurrentSession(uid: number, generation: number): boolean {
    return this.activeUid === uid && this.sessionGeneration === generation;
  }

  /** 列表请求已结束后，仅保留仍在提交的覆盖层。 */
  private dropResolvedPending(): void {
    const next: Map<number, boolean> = new Map<number, boolean>();
    this.pending.forEach((liked: boolean, songId: number) => {
      if (this.committing.has(songId)) {
        next.set(songId, liked);
      }
    });
    this.pending = next;
  }

  onSession(loginInfo: LoginInfo | null): void {
    const uid: number = loginInfo !== null && loginInfo.uid > 0 ? loginInfo.uid : 0;
    if (uid === this.activeUid) {
      return;
    }
    this.activeUid = uid;
    this.sessionGeneration = this.sessionGeneration + 1;
    this.loadingGeneration = 0;
    this.likesReady = false;
    this.pending.clear();
    this.committing.clear();
    this.snap().clear();
    if (uid > 0) {
      this.load(uid, this.sessionGeneration);
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
    const uid: number = info.uid;
    if (uid !== this.activeUid) {
      this.onSession(info);
    }
    if (uid !== this.activeUid || this.committing.has(songId)) {
      return;
    }
    if (!this.likesReady) {
      if (this.loadingGeneration !== this.sessionGeneration) {
        this.load(uid, this.sessionGeneration);
      }
      StoreHub.player().showToast('正在加载喜欢列表');
      return;
    }
    const nextLiked: boolean = !this.snap().has(songId);
    const generation: number = this.sessionGeneration;
    this.committing.add(songId);
    this.pending.set(songId, nextLiked);
    this.snap().setLiked(songId, nextLiked);
    this.commit(songId, nextLiked, uid, generation);
  }

  private async load(uid: number, generation: number): Promise<void> {
    this.loadingGeneration = generation;
    try {
      const ids = await CatalogRepository.get().likedIds(uid, () => this.isCurrentSession(uid, generation));
      if (this.isCurrentSession(uid, generation)) {
        this.snap().replaceAll(ids, this.pending);
        this.likesReady = true;
      }
    } catch (e) {
      if (this.isCurrentSession(uid, generation)) {
        console.error(`[LikeService] load failed: ${JSON.stringify(e)}`);
      }
    } finally {
      if (this.isCurrentSession(uid, generation) && this.loadingGeneration === generation) {
        this.loadingGeneration = 0;
        this.dropResolvedPending();
      }
    }
  }

  private async commit(songId: number, liked: boolean, uid: number, generation: number): Promise<void> {
    let succeeded: boolean = false;
    try {
      await CatalogRepository.get().setSongLike(songId, liked, () => this.isCurrentSession(uid, generation));
      succeeded = true;
    } catch (e) {
      if (!this.isCurrentSession(uid, generation)) {
        return;
      }
      console.error(`[LikeService] setLike failed: ${JSON.stringify(e)}`);
      this.snap().setLiked(songId, !liked);
      StoreHub.player().showToast(liked ? '红心失败' : '取消红心失败');
    } finally {
      if (this.isCurrentSession(uid, generation)) {
        this.committing.delete(songId);
        if (!succeeded || this.loadingGeneration !== generation) {
          this.pending.delete(songId);
        }
      }
    }
  }
}
