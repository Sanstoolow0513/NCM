/**
 * 每日推荐歌曲页
 * 顶部说明 + 播放全部胶囊按钮，下方为歌曲列表
 */
import { SongInfo } from '../../model/entity/models';
import { DailySongsViewModel } from '../../viewmodel/DailySongsViewModel';
import { SongRow } from '../components/SongRow';
import { ChromeInsets } from '../../common/utils/ChromeInsets';
import {
  ACCENT_COLOR, ON_ACCENT, PAGE_BG, PAGE_PAD, SPACE_L, SPACE_M, SPACE_S, TEXT_SECONDARY
} from '../../common/utils/format';

@ComponentV2
export struct DailySongsPage {
  @Param navPathStack: NavPathStack = new NavPathStack();
  @Consumer('chromeInsets') chrome: ChromeInsets = new ChromeInsets();
  @Local vm: DailySongsViewModel = new DailySongsViewModel();

  aboutToAppear(): void {
    this.vm.load();
  }

  @Monitor('vm.toastMessage')
  onToast(_mon: IMonitor): void {
    if (this.vm.toastMessage.length > 0) {
      this.getUIContext().getPromptAction().showToast({ message: this.vm.toastMessage });
      this.vm.toastMessage = '';
    }
  }

  build() {
    NavDestination() {
      if (this.vm.loading) {
        Column() {
          LoadingProgress().width(40).height(40).color(TEXT_SECONDARY)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.vm.error.length > 0) {
        Column() {
          Text(this.vm.error)
            .fontSize(14)
            .fontColor(TEXT_SECONDARY)
          Button('重试')
            .type(ButtonType.Capsule)
            .controlSize(ControlSize.SMALL)
            .margin({ top: SPACE_M })
            .onClick(() => {
              this.vm.load();
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Column() {
          Row() {
            Text(`根据口味更新 · ${this.vm.songs.length} 首`)
              .fontSize(13)
              .fontColor(TEXT_SECONDARY)
              .layoutWeight(1)
            Button({ type: ButtonType.Capsule }) {
              Row() {
                SymbolGlyph($r('sys.symbol.play_fill'))
                  .fontSize(14)
                  .fontColor([ON_ACCENT])
                Text('播放全部')
                  .fontSize(13)
                  .fontColor(ON_ACCENT)
                  .margin({ left: 4 })
              }
              .alignItems(VerticalAlign.Center)
            }
            .height(36)
            .padding({ left: SPACE_L, right: SPACE_L })
            .backgroundColor(ACCENT_COLOR)
            .onClick(() => {
              this.vm.playAll();
            })
          }
          .width('100%')
          .padding({ left: PAGE_PAD, right: PAGE_PAD, top: SPACE_S, bottom: SPACE_S })

          List() {
            ForEach(this.vm.songs, (song: SongInfo, songIndex: number) => {
              ListItem() {
                SongRow({
                  song: song,
                  songIndex: songIndex,
                  showIndex: true,
                  onTap: (idx: number) => {
                    this.vm.playAt(idx);
                  }
                })
              }
            }, (song: SongInfo, songIndex: number) => `${song.id}-${songIndex}`)
          }
          .layoutWeight(1)
          .width('100%')
          .scrollBar(BarState.Off)
          .contentEndOffset(this.chrome.listEndOffset)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
          .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.BOTTOM])
        }
        .width('100%')
        .height('100%')
      }
    }
    .title('每日推荐')
    .hideToolBar(true)
    .backgroundColor(PAGE_BG)
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.BOTTOM])
  }
}
