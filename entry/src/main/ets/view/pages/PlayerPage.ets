/**
 * 完整播放页
 * 封面模糊沉浸背景（固定深色蒙版 + 白色文字层级），歌词滚动 + 播放控制
 */
import { LyricLine } from '../../model/entity/models';
import { PlayerViewModel } from '../../viewmodel/PlayerViewModel';
import { StoreHub } from '../../store/StoreHub';
import { PlayerSnapshot } from '../../store/PlayerSnapshot';
import { QueuePanel } from '../components/QueuePanel';
import { formatDuration, NAV_INDICATOR_PAD, PAGE_BG, RADIUS_L } from '../../common/utils/format';

/** 深色蒙版上的白色文字层级 */
const LYRIC_INACTIVE: string = '#8CFFFFFF';
const LYRIC_TRANSLATION: string = '#73FFFFFF';
const TEXT_ON_DARK_SUB: string = '#B3FFFFFF';

/** 循环模式对应的图标（0 列表循环 / 1 单曲循环 / 2 随机播放） */
const LOOP_MODE_SYMBOLS: Resource[] = [
  $r('sys.symbol.repeat'),
  $r('sys.symbol.repeat_1'),
  $r('sys.symbol.shuffle')
];

@ComponentV2
export struct PlayerPage {
  @Param navPathStack: NavPathStack = new NavPathStack();
  @Local vm: PlayerViewModel = new PlayerViewModel();
  @Local player: PlayerSnapshot = StoreHub.player();
  @Local showQueue: boolean = false;
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.player.fullPlayerOpen = true;
    this.vm.loadLyric(this.player.currentSong);
  }

  aboutToDisappear(): void {
    this.player.fullPlayerOpen = false;
  }

  @Monitor('player.currentSong')
  onSongChanged(_mon: IMonitor): void {
    this.vm.loadLyric(this.player.currentSong);
    if (this.player.currentSong === null) {
      this.showQueue = false;
    }
  }

  @Monitor('player.positionMs')
  onPositionChanged(_mon: IMonitor): void {
    const prev: number = this.vm.activeLine;
    const idx: number = this.vm.updateActiveLine(this.player.positionMs);
    if (idx !== prev && idx > 0) {
      this.scroller.scrollToIndex(idx - 1, true);
    }
  }

  @LocalBuilder
  QueueSheet() {
    QueuePanel()
  }

  private coverSrc(): string {
    if (this.player.currentSong !== null && this.player.currentSong.picUrl.length > 0) {
      return `${this.player.currentSong.picUrl}?param=500y500`;
    }
    return '';
  }

  private loopModeSymbol(): Resource {
    if (this.player.loopMode >= 0 && this.player.loopMode < LOOP_MODE_SYMBOLS.length) {
      return LOOP_MODE_SYMBOLS[this.player.loopMode];
    }
    return LOOP_MODE_SYMBOLS[0];
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        // 封面模糊沉浸背景 + 固定深色蒙版
        Image(this.coverSrc())
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .blur(80)
        Column() {
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#B3000000')

        Column() {
          Row() {
            SymbolGlyph($r('sys.symbol.chevron_down'))
              .fontSize(24)
              .fontColor([Color.White])
              .onClick(() => {
                this.navPathStack.pop();
              })
            Text('正在播放')
              .fontSize(16)
              .fontColor(Color.White)
            Text('')
              .width(24)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ left: 16, right: 16, top: 12 })

          Image(this.coverSrc())
            .width('72%')
            .aspectRatio(1)
            .borderRadius(RADIUS_L)
            .backgroundColor('#33FFFFFF')
            .shadow({ radius: 24, color: '#66000000', offsetY: 8 })
            .margin({ top: 14 })

          Text(this.player.currentSong?.name ?? '')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 14, left: 24, right: 24 })
          Text(`${this.player.currentSong?.singer ?? ''} - ${this.player.currentSong?.album ?? ''}`)
            .fontSize(13)
            .fontColor(TEXT_ON_DARK_SUB)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4, left: 24, right: 24 })

          if (this.vm.lyrics.length > 0) {
            List({ scroller: this.scroller }) {
              ForEach(this.vm.lyrics, (line: LyricLine, lineIndex: number) => {
                ListItem() {
                  Column() {
                    Text(line.text)
                      .fontSize(lineIndex === this.vm.activeLine ? 16 : 14)
                      .fontColor(lineIndex === this.vm.activeLine ? Color.White : LYRIC_INACTIVE)
                      .fontWeight(lineIndex === this.vm.activeLine ? FontWeight.Bold : FontWeight.Normal)
                      .textAlign(TextAlign.Center)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    if (line.tText.length > 0) {
                      Text(line.tText)
                        .fontSize(12)
                        .fontColor(LYRIC_TRANSLATION)
                        .textAlign(TextAlign.Center)
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .margin({ top: 2 })
                    }
                  }
                  .width('100%')
                  .alignItems(HorizontalAlign.Center)
                  .padding({ top: 8, bottom: 8, left: 32, right: 32 })
                }
              }, (line: LyricLine, lineIndex: number) => `${line.timeMs}-${lineIndex}`)
            }
            .layoutWeight(1)
            .width('100%')
            .scrollBar(BarState.Off)
            .margin({ top: 8 })
          } else {
            Column() {
              Text('纯音乐 / 暂无歌词')
                .fontSize(13)
                .fontColor(TEXT_ON_DARK_SUB)
            }
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .width('100%')
          }

          Row() {
            Text(formatDuration(this.player.positionMs))
              .fontSize(11)
              .fontColor(TEXT_ON_DARK_SUB)
              .width(42)
            Slider({
              value: this.player.positionMs,
              min: 0,
              max: this.player.durationMs > 0 ? this.player.durationMs : 1,
              style: SliderStyle.OutSet
            })
              .layoutWeight(1)
              .trackColor('#33FFFFFF')
              .selectedColor(Color.White)
              .blockColor(Color.White)
              .onChange((value: number, mode: SliderChangeMode) => {
                if (mode === SliderChangeMode.End) {
                  this.vm.seekTo(value);
                }
              })
            Text(formatDuration(this.player.durationMs))
              .fontSize(11)
              .fontColor(TEXT_ON_DARK_SUB)
              .width(42)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .padding({ left: 16, right: 16 })

          Row() {
            SymbolGlyph(this.loopModeSymbol())
              .fontSize(24)
              .fontColor([Color.White])
              .width(56)
              .onClick(() => {
                this.vm.cycleLoopMode();
              })
            SymbolGlyph($r('sys.symbol.backward_end_fill'))
              .fontSize(36)
              .fontColor([Color.White])
              .onClick(() => {
                this.vm.prev();
              })
            SymbolGlyph(this.player.isPlaying ? $r('sys.symbol.pause_circle_fill') : $r('sys.symbol.play_circle_fill'))
              .fontSize(72)
              .fontColor([Color.White])
              .onClick(() => {
                this.vm.toggle();
              })
            SymbolGlyph($r('sys.symbol.forward_end_fill'))
              .fontSize(36)
              .fontColor([Color.White])
              .onClick(() => {
                this.vm.next();
              })
            SymbolGlyph($r('sys.symbol.music_note_list'))
              .fontSize(24)
              .fontColor([Color.White])
              .width(56)
              .onClick(() => {
                this.showQueue = true;
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceEvenly)
          .alignItems(VerticalAlign.Center)
          .padding({ top: 10, bottom: 30 + NAV_INDICATOR_PAD })
        }
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .hideToolBar(true)
    .backgroundColor(PAGE_BG)
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.BOTTOM])
    .transition(TransitionEffect.translate({ y: '100%' }).animation({ duration: 250, curve: Curve.EaseOut }))
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
