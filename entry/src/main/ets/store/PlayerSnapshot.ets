import { SongInfo } from '../model/entity/models';

@ObservedV2
export class PlayerSnapshot {
  @Trace currentSong: SongInfo | null = null;
  @Trace isPlaying: boolean = false;
  @Trace positionMs: number = 0;
  @Trace durationMs: number = 0;
  /** 0 列表循环 / 1 单曲循环 / 2 随机播放 */
  @Trace loopMode: number = 0;
  @Trace queue: SongInfo[] = [];
  @Trace queueIndex: number = -1;
  @Trace fullPlayerOpen: boolean = false;
  @Trace fullPlayerQueueOpen: boolean = false;
  @Trace toastMessage: string = '';
  @Trace toastSeq: number = 0;

  showToast(message: string): void {
    this.toastMessage = message;
    this.toastSeq = this.toastSeq + 1;
  }
}
