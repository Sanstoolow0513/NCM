/**
 * 全局迷你播放器悬浮条
 * 材质模糊胶囊 + 底部播放进度细条，点击封面/文字区进入完整播放页
 */
import { PlayerService } from '../../service/player/PlayerService';
import { StoreHub } from '../../store/StoreHub';
import { PlayerSnapshot } from '../../store/PlayerSnapshot';
import { RouteName } from '../../common/router/RouteName';
import { ChromeInsets } from '../../common/utils/ChromeInsets';
import { QueuePanel } from './QueuePanel';
import {
  ACCENT_COLOR, COVER_PLACEHOLDER, MINIPLAYER_BG, PAGE_BG, RADIUS_S, TEXT_PRIMARY, TEXT_SECONDARY
} from '../../common/utils/format';

@ComponentV2
export struct MiniPlayer {
  @Param navPathStack: NavPathStack = new NavPathStack();
  @Consumer('chromeInsets') chrome: ChromeInsets = new ChromeInsets();
  @Local player: PlayerSnapshot = StoreHub.player();
  @Local showQueue: boolean = false;

  @Monitor('player.currentSong')
  onCurrentSong(_mon: IMonitor): void {
    if (this.player.currentSong === null) {
      this.showQueue = false;
    }
  }

  @LocalBuilder
  QueueSheet() {
    QueuePanel()
  }

  private openPlayer(): void {
    this.navPathStack.pushPath({ name: RouteName.PLAYER });
  }

  private progressPercent(): string {
    if (this.player.durationMs <= 0) {
      return '0%';
    }
    const pct: number = Math.min(100, Math.max(0, this.player.positionMs / this.player.durationMs * 100));
    return `${pct}%`;
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      Row() {
        Row() {
          Image(this.player.currentSong?.picUrl ?? '')
            .width(42)
            .height(42)
            .borderRadius(RADIUS_S)
            .backgroundColor(COVER_PLACEHOLDER)
            .margin({ left: 10 })
          Column() {
            Text(this.player.currentSong?.name ?? '')
              .fontSize(14)
              .fontColor(TEXT_PRIMARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.player.currentSong?.singer ?? '')
              .fontSize(11)
              .fontColor(TEXT_SECONDARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 10, right: 8 })
        }
        .layoutWeight(1)
        .height('100%')
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.openPlayer();
        })

        SymbolGlyph(this.player.isPlaying ? $r('sys.symbol.pause_fill') : $r('sys.symbol.play_fill'))
          .fontSize(30)
          .fontColor([TEXT_PRIMARY])
          .margin({ right: 12 })
          .onClick(() => {
            PlayerService.get().toggle();
          })
        SymbolGlyph($r('sys.symbol.forward_end_fill'))
          .fontSize(24)
          .fontColor([TEXT_PRIMARY])
          .margin({ right: 10 })
          .onClick(() => {
            PlayerService.get().next(true);
          })
        SymbolGlyph($r('sys.symbol.music_note_list'))
          .fontSize(22)
          .fontColor([TEXT_PRIMARY])
          .margin({ right: 14 })
          .onClick(() => {
            this.showQueue = true;
          })
      }
      .width('100%')
      .height('100%')

      // 底部播放进度细条
      Row()
        .width(this.progressPercent())
        .height(2)
        .backgroundColor(ACCENT_COLOR)
    }
    .width('94%')
    .height(56)
    .borderRadius(28)
    .clip(true)
    .backgroundColor(MINIPLAYER_BG)
    .backgroundBlurStyle(BlurStyle.Regular)
    .shadow({ radius: 12, color: '#33000000', offsetY: 2 })
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      this.chrome.setMiniPlayerHeight(newValue.height as number);
    })
    .bindSheet($$this.showQueue, this.QueueSheet, {
      detents: [SheetSize.MEDIUM, SheetSize.LARGE],
      preferType: SheetType.BOTTOM,
      dragBar: true,
      showClose: true,
      title: { title: '播放列表' },
      backgroundColor: PAGE_BG,
      blurStyle: BlurStyle.COMPONENT_ULTRA_THICK
    })
  }
}
