/**
 * 歌曲行视图模型：聚合播放与喜欢状态，并处理行内业务操作。
 */
import { SongInfo } from '../model/entity/models';
import { LikeService } from '../service/like/LikeService';
import { PlayerService } from '../service/player/PlayerService';
import { LikeSnapshot } from '../store/LikeSnapshot';
import { PlayerSnapshot } from '../store/PlayerSnapshot';
import { StoreHub } from '../store/StoreHub';

@ObservedV2
export class SongRowViewModel {
  @Trace player: PlayerSnapshot = StoreHub.player();
  @Trace likes: LikeSnapshot = StoreHub.likes();

  isPlaying(songId: number): boolean {
    return this.player.currentSong !== null && this.player.currentSong.id === songId && songId !== 0;
  }

  isLiked(songId: number): boolean {
    return this.likes.revision >= 0 && this.likes.has(songId);
  }

  insertNext(song: SongInfo): void {
    PlayerService.get().insertNext(song);
  }

  toggleLike(songId: number): void {
    LikeService.get().toggle(songId);
  }
}
