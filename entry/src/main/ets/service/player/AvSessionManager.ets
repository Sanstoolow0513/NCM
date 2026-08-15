/*
 * AvSessionManager：系统播控中心（AVSession）接入 + 音频长时任务。
 * 播控中心展示歌曲元数据/播放状态，并把 play/pause/next/previous/seek 命令转发给 PlayerService；
 * 应用退后台且正在播放时申请 audioPlayback 长时任务，回前台时取消。
 */
import { avSession } from '@kit.AVSessionKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { common, wantAgent, WantAgent } from '@kit.AbilityKit';
import { SongInfo } from '../../model/entity/models';
import { PlayerService } from './PlayerService';

export class AvSessionManager {
  private session: avSession.AVSession | null = null;
  private context: common.UIAbilityContext | null = null;
  private bgStarted: boolean = false;

  async init(context: common.UIAbilityContext): Promise<void> {
    this.context = context;
    try {
      this.session = await avSession.createAVSession(context, 'ncm_session', 'audio');
      this.registerEvents();
      await this.session.activate();
    } catch (e) {
      console.error(`[AvSessionManager] init failed: ${JSON.stringify(e)}`);
    }
  }

  private registerEvents(): void {
    const s = this.session;
    if (s === null) {
      return;
    }
    const player = PlayerService.get();
    s.on('play', () => {
      player.resume();
    });
    s.on('pause', () => {
      player.pause();
    });
    s.on('stop', () => {
      player.pause();
    });
    s.on('playNext', () => {
      player.next(true);
    });
    s.on('playPrevious', () => {
      player.prev();
    });
    s.on('seek', (time: number) => {
      player.seekTo(time);
    });
  }

  updateMetadata(song: SongInfo): void {
    const s = this.session;
    if (s === null) {
      return;
    }
    const metadata: avSession.AVMetadata = {
      assetId: song.id.toString(),
      title: song.name,
      artist: song.singer,
      album: song.album,
      duration: song.duration,
      mediaImage: song.picUrl
    };
    s.setAVMetadata(metadata).catch((e: Error) => {
      console.error(`[AvSessionManager] setAVMetadata failed: ${JSON.stringify(e)}`);
    });
  }

  updatePlaybackState(playing: boolean, positionMs: number): void {
    const s = this.session;
    if (s === null) {
      return;
    }
    const state: avSession.AVPlaybackState = {
      state: playing ? avSession.PlaybackState.PLAYBACK_STATE_PLAY : avSession.PlaybackState.PLAYBACK_STATE_PAUSE,
      speed: 1,
      position: { elapsedTime: positionMs, updateTime: Date.now() }
    };
    s.setAVPlaybackState(state).catch((e: Error) => {
      console.error(`[AvSessionManager] setAVPlaybackState failed: ${JSON.stringify(e)}`);
    });
  }

  async startBackgroundTask(): Promise<void> {
    if (this.bgStarted || this.context === null) {
      return;
    }
    const context = this.context;
    try {
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [{
          bundleName: context.abilityInfo.bundleName,
          abilityName: context.abilityInfo.name
        }],
        actionType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0,
        actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
      };
      const agent: WantAgent = await wantAgent.getWantAgent(wantAgentInfo);
      await backgroundTaskManager.startBackgroundRunning(context, ['audioPlayback'], agent);
      this.bgStarted = true;
    } catch (e) {
      console.error(`[AvSessionManager] startBackgroundRunning failed: ${JSON.stringify(e)}`);
    }
  }

  async stopBackgroundTask(): Promise<void> {
    if (!this.bgStarted || this.context === null) {
      return;
    }
    try {
      await backgroundTaskManager.stopBackgroundRunning(this.context);
    } catch (e) {
      console.error(`[AvSessionManager] stopBackgroundRunning failed: ${JSON.stringify(e)}`);
    }
    this.bgStarted = false;
  }
}
