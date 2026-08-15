/**
 * 歌单 / 专辑详情页
 * 头部为封面模糊背景 + 封面与简介 + 播放全部胶囊按钮，下方为歌曲列表
 */
import { SongInfo } from '../../model/entity/models';
import { PlaylistDetailViewModel } from '../../viewmodel/PlaylistDetailViewModel';
import { SongRow } from '../components/SongRow';
import { ChromeInsets } from '../../common/utils/ChromeInsets';
import {
  ACCENT_COLOR, BLUR_SCRIM, ON_ACCENT, PAGE_BG, PAGE_PAD, RADIUS_M, SPACE_L, SPACE_M, TEXT_PRIMARY,
  TEXT_SECONDARY
} from '../../common/utils/format';

/** 详情头封面边长；头部高度随封面与内边距撑开，避免写死 210 在标题栏下留白 */
const HEADER_COVER: number = 120;

@ComponentV2
export struct PlaylistDetailPage {
  @Param navPathStack: NavPathStack = new NavPathStack();
  @Param listId: number = 0;
  @Param isAlbum: boolean = false;
  @Consumer('chromeInsets') chrome: ChromeInsets = new ChromeInsets();
  @Local vm: PlaylistDetailViewModel = new PlaylistDetailViewModel();

  aboutToAppear(): void {
    this.vm.configure(this.listId, this.isAlbum);
    this.vm.load();
  }

  @Monitor('vm.toastMessage')
  onToast(_mon: IMonitor): void {
    if (this.vm.toastMessage.length > 0) {
      this.getUIContext().getPromptAction().showToast({ message: this.vm.toastMessage });
      this.vm.toastMessage = '';
    }
  }

  @Builder
  DetailHeader(coverUrl: string, name: string, description: string, songCount: number) {
    Stack({ alignContent: Alignment.TopStart }) {
      // 封面模糊打底，略放大以消除 blur 边缘
      Image(coverUrl)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .blur(40)
        .scale({ x: 1.2, y: 1.2 })
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(BLUR_SCRIM)

      Row() {
        Image(coverUrl)
          .width(HEADER_COVER)
          .height(HEADER_COVER)
          .borderRadius(RADIUS_M)
          .objectFit(ImageFit.Cover)
          .shadow({ radius: 16, color: '#33000000', offsetY: 4 })
        Column() {
          Text(name)
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor(TEXT_PRIMARY)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (description.length > 0) {
            Text(description)
              .fontSize(12)
              .fontColor(TEXT_SECONDARY)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 6 })
          }
          Button({ type: ButtonType.Capsule }) {
            Row() {
              SymbolGlyph($r('sys.symbol.play_fill'))
                .fontSize(14)
                .fontColor([ON_ACCENT])
              Text(`播放全部 (${songCount})`)
                .fontSize(13)
                .fontColor(ON_ACCENT)
                .margin({ left: 4 })
            }
            .alignItems(VerticalAlign.Center)
          }
          .height(36)
          .padding({ left: SPACE_L, right: SPACE_L })
          .backgroundColor(ACCENT_COLOR)
          .margin({ top: 10 })
          .onClick(() => {
            this.vm.playAll();
          })
        }
        .layoutWeight(1)
        .height(HEADER_COVER)
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 14 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      .padding({ left: PAGE_PAD, right: PAGE_PAD, top: SPACE_M, bottom: SPACE_M })
    }
    .width('100%')
    .height(HEADER_COVER + SPACE_M + SPACE_M)
    .clip(true)
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
      } else if (this.vm.error.length > 0 || this.vm.detail === null) {
        Column() {
          Text(this.vm.error.length > 0 ? this.vm.error : '暂无数据')
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
          this.DetailHeader(
            `${this.vm.detail.coverImgUrl}?param=300y300`,
            this.vm.detail.name,
            this.vm.detail.description,
            this.vm.detail.songs.length
          )

          List() {
            ForEach(this.vm.detail.songs, (song: SongInfo, songIndex: number) => {
              ListItem() {
                SongRow({
                  song: song,
                  songIndex: songIndex,
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
    .title(this.isAlbum ? '专辑' : '歌单')
    .hideToolBar(true)
    .backgroundColor(PAGE_BG)
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.BOTTOM])
  }
}
