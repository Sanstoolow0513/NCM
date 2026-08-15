import { MediaRepository } from '../model/repository/MediaRepository';
import { LyricLine, SongInfo } from '../model/entity/models';
import { StoreHub } from '../store/StoreHub';
import { PlayerService } from '../service/player/PlayerService';

@ObservedV2
export class PlayerViewModel {
  @Trace lyrics: LyricLine[] = [];
  @Trace activeLine: number = -1;

  async loadLyric(song: SongInfo | null): Promise<void> {
    this.lyrics = [];
    this.activeLine = -1;
    if (song === null) {
      return;
    }
    const songId = song.id;
    try {
      const lines = await MediaRepository.get().lyric(songId);
      const cur = StoreHub.player().currentSong;
      if (cur !== null && cur.id === songId) {
        this.lyrics = lines;
      }
    } catch (e) {
      console.error(`[PlayerViewModel] load lyric failed: ${JSON.stringify(e)}`);
    }
  }

  updateActiveLine(positionMs: number): number {
    if (this.lyrics.length === 0) {
      return this.activeLine;
    }
    let idx = -1;
    for (let i = 0; i < this.lyrics.length; i++) {
      if (this.lyrics[i].timeMs <= positionMs) {
        idx = i;
      } else {
        break;
      }
    }
    if (idx !== this.activeLine) {
      this.activeLine = idx;
    }
    return this.activeLine;
  }

  seekTo(ms: number): void {
    PlayerService.get().seekTo(Math.floor(ms));
  }

  cycleLoopMode(): void {
    PlayerService.get().cycleLoopMode();
  }

  prev(): void {
    PlayerService.get().prev();
  }

  toggle(): void {
    PlayerService.get().toggle();
  }

  next(): void {
    PlayerService.get().next(true);
  }
}
