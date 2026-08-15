/**
 * 账号喜欢歌曲集合。
 * ids 可能上千首，查找走内部 Set；UI 只订阅 @Trace revision。
 */
@ObservedV2
export class LikeSnapshot {
  @Trace revision: number = 0;
  private ids: Set<number> = new Set();

  has(id: number): boolean {
    return this.ids.has(id);
  }

  replaceAll(ids: number[], pending: Map<number, boolean>): void {
    const next: Set<number> = new Set();
    for (const id of ids) {
      next.add(id);
    }
    pending.forEach((liked: boolean, songId: number) => {
      if (liked) {
        next.add(songId);
      } else {
        next.delete(songId);
      }
    });
    this.ids = next;
    this.revision = this.revision + 1;
  }

  setLiked(id: number, liked: boolean): void {
    if (liked) {
      this.ids.add(id);
    } else {
      this.ids.delete(id);
    }
    this.revision = this.revision + 1;
  }

  clear(): void {
    this.ids.clear();
    this.revision = this.revision + 1;
  }
}
