/**
 * 完整播放页
 * 封面模糊沉浸背景（固定深色蒙版 + 白色文字层级），歌词滚动 + 播放控制
 * 叠在首页 Stack 上，与迷你条封面通过 geometryTransition 一镜到底；滑动歌词时封面缩小以露出更多歌词
 */
import { LyricLine } from '../../model/entity/models';
import { PlayerViewModel } from '../../viewmodel/PlayerViewModel';
import { StoreHub } from '../../store/StoreHub';
import { PlayerSnapshot } from '../../store/PlayerSnapshot';
import { QueuePanel } from '../components/QueuePanel';
import { ChromeInsets } from '../../common/utils/ChromeInsets';
import {
  formatDuration, PAGE_BG, PLAYER_COVER_GEOMETRY_ID, PLAYER_EXPAND_DURATION, RADIUS_L, TEXT_PRIMARY
} from '../../common/utils/format';

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

/** 播放页封面展开/收起宽度与上边距 */
const COVER_EXPANDED: string = '72%';
const COVER_COLLAPSED: string = '28%';
const COVER_MARGIN_EXPANDED: number = 14;
const COVER_MARGIN_COLLAPSED: number = 8;

/** 非共享元素入场淡入上移；离场只淡出，避免位移拖累封面回缩 */
const PLAYER_CHROME_TRANSITION: TransitionEffect = TransitionEffect.asymmetric(
  TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 40 }))
    .animation({ duration: 280, curve: Curve.Friction }),
  TransitionEffect.OPACITY.animation({ duration: 180, curve: Curve.EaseIn })
);

@ComponentV2
export struct PlayerPage {
  @Consumer('chromeInsets') chrome: ChromeInsets = new ChromeInsets();
  @Local vm: PlayerViewModel = new PlayerViewModel();
  @Local player: PlayerSnapshot = StoreHub.player();
  @Local showQueue: boolean = false;
  @Local coverCollapsed: boolean = false;
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.vm.loadLyric(this.player.currentSong);
  }

  @Monitor('player.currentSong')
  onSongChanged(_mon: IMonitor): void {
    this.coverCollapsed = false;
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

  private coverSrc(): string {
    if (this.player.currentSong !== null && this.player.currentSong.picUrl.length > 0) {
      return `${this.player.currentSong.picUrl}?param=500y500`;
    }
    return '';
  }

  /** 沉浸背景用更大图，Cover 裁切铺满竖屏，与正方形封面解耦 */
  private backdropSrc(): string {
    if (this.player.currentSong !== null && this.player.currentSong.picUrl.length > 0) {
      return `${this.player.currentSong.picUrl}?param=1080y1080`;
    }
    return '';
  }

  private loopModeSymbol(): Resource {
    if (this.player.loopMode >= 0 && this.player.loopMode < LOOP_MODE_SYMBOLS.length) {
      return LOOP_MODE_SYMBOLS[this.player.loopMode];
    }
    return LOOP_MODE_SYMBOLS[0];
  }

  private setCoverCollapsed(collapsed: boolean): void {
    if (this.coverCollapsed === collapsed) {
      return;
    }
    this.getUIContext().animateTo({ duration: 280, curve: Curve.EaseOut }, () => {
      this.coverCollapsed = collapsed;
    });
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 封面模糊沉浸背景 + 固定深色蒙版
      Image(this.backdropSrc())
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .blur(80)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
        .transition(TransitionEffect.OPACITY.animation({ duration: 280, curve: Curve.Friction }))
      Column() {
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#99000000')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
      .transition(TransitionEffect.OPACITY.animation({ duration: 280, curve: Curve.Friction }))

      Column() {
        Row() {
          SymbolGlyph($r('sys.symbol.chevron_down'))
            .fontSize(24)
            .fontColor([Color.White])
            .onClick(() => {
              this.getUIContext().animateTo({ duration: PLAYER_EXPAND_DURATION, curve: Curve.Friction }, () => {
                this.player.fullPlayerOpen = false;
              });
            })
          Text('正在播放')
            .fontSize(16)
            .fontColor(Color.White)
          Text('')
            .width(24)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({ left: 16, right: 16, top: 12 + this.chrome.safeTop })
        .transition(PLAYER_CHROME_TRANSITION)

        Image(this.coverSrc())
          .width(this.coverCollapsed ? COVER_COLLAPSED : COVER_EXPANDED)
          .aspectRatio(1)
          .borderRadius(RADIUS_L)
          .clip(true)
          .objectFit(ImageFit.Cover)
          .backgroundColor('#33FFFFFF')
          .geometryTransition(PLAYER_COVER_GEOMETRY_ID)
          .transition(TransitionEffect.opacity(0.99).animation({
            duration: PLAYER_EXPAND_DURATION,
            curve: Curve.Friction
          }))
          .shadow({ radius: 24, color: '#66000000', offsetY: 8 })
          .margin({ top: this.coverCollapsed ? COVER_MARGIN_COLLAPSED : COVER_MARGIN_EXPANDED })
          .onClick(() => {
            this.setCoverCollapsed(false);
          })

        Text(this.player.currentSong?.name ?? '')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 14, left: 24, right: 24 })
          .transition(PLAYER_CHROME_TRANSITION)
        Text(`${this.player.currentSong?.singer ?? ''} - ${this.player.currentSong?.album ?? ''}`)
          .fontSize(13)
          .fontColor(TEXT_ON_DARK_SUB)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4, left: 24, right: 24 })
          .transition(PLAYER_CHROME_TRANSITION)

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
          .transition(PLAYER_CHROME_TRANSITION)
          .onDidScroll((_offset: number, scrollState: ScrollState) => {
            if (!this.coverCollapsed && scrollState === ScrollState.Scroll) {
              this.setCoverCollapsed(true);
            }
          })
        } else {
          Column() {
            Text('纯音乐 / 暂无歌词')
              .fontSize(13)
              .fontColor(TEXT_ON_DARK_SUB)
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .width('100%')
          .transition(PLAYER_CHROME_TRANSITION)
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
        .transition(PLAYER_CHROME_TRANSITION)

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
        .padding({ top: 10, bottom: 8 + this.chrome.safeBottom })
        .transition(PLAYER_CHROME_TRANSITION)
      }
      .width('100%')
      .height('100%')

      if (this.showQueue) {
        Column() {
          Column()
            .width('100%')
            .layoutWeight(1)
            .onClick(() => {
              this.showQueue = false;
            })
          Column() {
            Row() {
              Text('播放列表')
                .fontSize(16)
                .fontColor(TEXT_PRIMARY)
                .layoutWeight(1)
              Text('关闭')
                .fontSize(14)
                .fontColor(TEXT_PRIMARY)
                .onClick(() => {
                  this.showQueue = false;
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 8 })
            QueuePanel()
              .layoutWeight(1)
          }
          .width('100%')
          .height('70%')
          .backgroundColor(PAGE_BG)
          .borderRadius({ topLeft: RADIUS_L, topRight: RADIUS_L })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#80000000')
        .transition(TransitionEffect.OPACITY.animation({ duration: 200, curve: Curve.EaseOut }))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .onAppear(() => {
      if (this.vm.lyrics.length === 0) {
        this.vm.loadLyric(this.player.currentSong);
      }
    })
  }
}
