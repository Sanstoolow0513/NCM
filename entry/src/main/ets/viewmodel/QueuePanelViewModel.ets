/**
 * 播放队列视图模型：提供队列展示状态和播放、移除、清空操作。
 */
import { SongInfo } from '../model/entity/models';
import { PlayerService } from '../service/player/PlayerService';
import { PlayerSnapshot } from '../store/PlayerSnapshot';
import { StoreHub } from '../store/StoreHub';

@ObservedV2
export class QueuePanelViewModel {
  @Trace player: PlayerSnapshot = StoreHub.player();

  songs(): SongInfo[] {
    return this.player.queue;
  }

  queueSize(): number {
    return this.player.queue.length;
  }

  isCurrent(songIndex: number): boolean {
    return this.player.queueIndex === songIndex;
  }

  playAt(songIndex: number): void {
    PlayerService.get().playAt(songIndex);
  }

  removeAt(songIndex: number): void {
    PlayerService.get().removeAt(songIndex);
  }

  clearQueue(): void {
    PlayerService.get().clearQueue();
  }
}
