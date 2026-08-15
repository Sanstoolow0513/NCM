/*
 * PlayerService：AVPlayer 封装 + 播放队列 + 循环模式。
 * 状态写入 PlayerSnapshot（AppStorageV2），页面通过 @Local connect 订阅。
 */
import { media } from '@kit.MediaKit';
import { common } from '@kit.AbilityKit';
import { MediaRepository } from '../../model/repository/MediaRepository';
import { SongInfo, SongUrlInfo } from '../../model/entity/models';
import { StoreHub } from '../../store/StoreHub';
import { PlayerSnapshot } from '../../store/PlayerSnapshot';
import { AvSessionManager } from './AvSessionManager';

const STREAM_UA =
  'Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) ' +
  'Version/9.0 Mobile/13B143 Safari/601.1';

export const LOOP_LIST = 0;
export const LOOP_SINGLE = 1;
export const LOOP_SHUFFLE = 2;
export const LOOP_MODE_NAMES: string[] = ['列表循环', '单曲循环', '随机播放'];

export class PlayerService {
  private static instance: PlayerService = new PlayerService();
  private avPlayer: media.AVPlayer | null = null;
  private avState: string = 'idle';
  private queue: SongInfo[] = [];
  private index: number = -1;
  private loopMode: number = LOOP_LIST;
  private urlCache: Map<number, SongUrlInfo> = new Map();
  private avSession: AvSessionManager | null = null;
  /** 递增令牌，防止快速切歌时旧请求覆盖新歌曲 */
  private playToken: number = 0;
  /** reset() 到 idle 是异步的，setMediaSource 必须等 idle 后再调用，否则报 5400102 */
  private pendingUrl: string | null = null;
  /** 连续解析失败计数，超过队列长度即停止，避免全部无音源时无限跳转 */
  private failCount: number = 0;

  static get(): PlayerService {
    return PlayerService.instance;
  }

  private snap(): PlayerSnapshot {
    return StoreHub.player();
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.avPlayer !== null) {
      return;
    }
    try {
      this.avPlayer = await media.createAVPlayer();
      this.bindEvents(this.avPlayer);
      this.avSession = new AvSessionManager();
      await this.avSession.init(context);
    } catch (e) {
      console.error(`[PlayerService] init failed: ${JSON.stringify(e)}`);
    }
  }

  private bindEvents(p: media.AVPlayer): void {
    p.on('stateChange', (state: media.AVPlayerState) => {
      console.info(`[PlayerService] stateChange: ${state}`);
      this.avState = state;
      if (state === 'idle') {
        const url = this.pendingUrl;
        if (url !== null) {
          this.pendingUrl = null;
          this.setSource(url);
        }
      } else if (state === 'initialized') {
        p.prepare();
      } else if (state === 'prepared') {
        p.play();
      } else if (state === 'playing') {
        this.snap().isPlaying = true;
        this.pushPlaybackState();
        if (this.avSession !== null) {
          this.avSession.startBackgroundTask();
        }
      } else if (state === 'paused') {
        this.snap().isPlaying = false;
        this.pushPlaybackState();
        if (this.avSession !== null) {
          this.avSession.stopBackgroundTask();
        }
      } else if (state === 'completed') {
        this.onComplete();
      } else if (state === 'error') {
        this.snap().isPlaying = false;
      }
    });
    p.on('timeUpdate', (ms: number) => {
      this.snap().positionMs = ms;
    });
    p.on('durationUpdate', (ms: number) => {
      console.info(`[PlayerService] durationUpdate: ${ms}`);
      this.snap().durationMs = ms;
    });
    p.on('error', (err) => {
      console.error(`[PlayerService] AVPlayer error: ${JSON.stringify(err)}`);
      this.snap().showToast('播放出错');
    });
  }

  async playList(songs: SongInfo[], startIndex: number): Promise<void> {
    if (songs.length === 0 || startIndex < 0 || startIndex >= songs.length) {
      return;
    }
    this.queue = songs;
    this.index = startIndex;
    const s = this.snap();
    s.queue = songs;
    s.queueIndex = startIndex;
    await this.playCurrent();
  }

  async playAt(index: number): Promise<void> {
    if (index < 0 || index >= this.queue.length) {
      return;
    }
    this.index = index;
    this.snap().queueIndex = index;
    await this.playCurrent();
  }

  private async playCurrent(): Promise<void> {
    const p = this.avPlayer;
    if (p === null || this.index < 0 || this.index >= this.queue.length) {
      return;
    }
    const song = this.queue[this.index];
    const snap = this.snap();
    snap.currentSong = song;
    snap.positionMs = 0;
    snap.durationMs = song.duration;
    const token = ++this.playToken;

    let urlInfo = this.urlCache.get(song.id) ?? null;
    if (urlInfo === null) {
      try {
        urlInfo = await MediaRepository.get().songUrl(song.id);
      } catch (e) {
        console.error(`[PlayerService] resolve url failed: ${JSON.stringify(e)}`);
        urlInfo = null;
      }
      if (urlInfo !== null) {
        this.urlCache.set(song.id, urlInfo);
      }
    }
    if (token !== this.playToken) {
      return;
    }
    if (urlInfo === null || urlInfo.url.length === 0) {
      this.failCount++;
      console.warn(`[PlayerService] no playable url for ${song.id} ${song.name} (fail ${this.failCount})`);
      snap.showToast(`「${song.name}」暂无播放源，已跳过`);
      if (this.failCount >= this.queue.length) {
        this.failCount = 0;
        snap.showToast('队列中没有可播放的歌曲');
        return;
      }
      this.next(false);
      return;
    }

    this.failCount = 0;
    console.info(`[PlayerService] play ${song.id} ${song.name} level=${urlInfo.level} br=${urlInfo.br} url=${urlInfo.url.substring(0, 80)}`);
    if (this.avState === 'idle') {
      this.setSource(urlInfo.url);
    } else {
      this.pendingUrl = urlInfo.url;
      p.reset();
    }
    if (this.avSession !== null) {
      this.avSession.updateMetadata(song);
    }
  }

  private setSource(url: string): void {
    const p = this.avPlayer;
    if (p === null) {
      return;
    }
    const source = media.createMediaSourceWithUrl(url, {
      'Referer': 'https://music.163.com',
      'User-Agent': STREAM_UA
    });
    const strategy: media.PlaybackStrategy = { preferredBufferDuration: 20 };
    p.setMediaSource(source, strategy);
  }

  toggle(): void {
    if (this.avState === 'playing') {
      this.pause();
    } else {
      this.resume();
    }
  }

  resume(): void {
    const p = this.avPlayer;
    if (p === null) {
      return;
    }
    if (this.avState === 'paused' || this.avState === 'prepared' || this.avState === 'completed') {
      p.play();
    }
  }

  pause(): void {
    if (this.avState === 'playing') {
      this.avPlayer?.pause();
    }
  }

  next(manual: boolean): void {
    if (this.queue.length === 0) {
      return;
    }
    if (this.loopMode === LOOP_SHUFFLE && this.queue.length > 1) {
      let n = this.index;
      while (n === this.index) {
        n = Math.floor(Math.random() * this.queue.length);
      }
      this.index = n;
    } else {
      this.index = (this.index + 1) % this.queue.length;
    }
    this.snap().queueIndex = this.index;
    this.playCurrent();
  }

  prev(): void {
    if (this.queue.length === 0) {
      return;
    }
    this.index = (this.index - 1 + this.queue.length) % this.queue.length;
    this.snap().queueIndex = this.index;
    this.playCurrent();
  }

  seekTo(ms: number): void {
    const p = this.avPlayer;
    if (p === null) {
      return;
    }
    if (this.avState === 'playing' || this.avState === 'paused' || this.avState === 'prepared') {
      p.seek(ms);
    }
  }

  cycleLoopMode(): void {
    this.loopMode = (this.loopMode + 1) % 3;
    this.snap().loopMode = this.loopMode;
    this.snap().showToast(LOOP_MODE_NAMES[this.loopMode]);
  }

  getLoopMode(): number {
    return this.loopMode;
  }

  private onComplete(): void {
    if (this.loopMode === LOOP_SINGLE) {
      this.seekTo(0);
      this.resume();
    } else {
      this.next(false);
    }
  }

  private pushPlaybackState(): void {
    if (this.avSession !== null) {
      this.avSession.updatePlaybackState(this.avState === 'playing', this.snap().positionMs);
    }
  }

  enterBackground(): void {
    if (this.avSession !== null && this.snap().isPlaying) {
      this.avSession.startBackgroundTask();
    }
  }

  exitBackground(): void {
    if (this.avSession !== null) {
      this.avSession.stopBackgroundTask();
    }
  }
}
