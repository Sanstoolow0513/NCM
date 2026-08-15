/**
 * 歌单 / 专辑详情页
 * 头部为封面模糊背景 + 封面与简介 + 播放全部胶囊按钮，下方为歌曲列表
 */
import { SongInfo } from '../../model/entity/models';
import { PlaylistDetailViewModel } from '../../viewmodel/PlaylistDetailViewModel';
import { SongRow } from '../components/SongRow';
import {
  ACCENT_COLOR, BLUR_SCRIM, ON_ACCENT, PAGE_BG, PAGE_PAD, RADIUS_M, SPACE_L, SPACE_M, SPACE_S, TEXT_PRIMARY,
  TEXT_SECONDARY
} from '../../common/utils/format';

@ComponentV2
export struct PlaylistDetailPage {
  @Param navPathStack: NavPathStack = new NavPathStack();
  @Param listId: number = 0;
  @Param isAlbum: boolean = false;
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
      // 封面模糊背景 + 页面色蒙版
      Image(coverUrl)
        .width('100%')
        .height(210)
        .objectFit(ImageFit.Cover)
        .blur(40)
      Column() {
      }
      .width('100%')
      .height(210)
      .backgroundColor(BLUR_SCRIM)

      Row() {
        Image(coverUrl)
          .width(120)
          .height(120)
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
          Text(description)
            .fontSize(12)
            .fontColor(TEXT_SECONDARY)
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 6 })
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
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 14 })
      }
      .width('100%')
      .padding({ left: PAGE_PAD, right: PAGE_PAD, top: SPACE_S, bottom: SPACE_M })
    }
    .width('100%')
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
          .contentEndOffset(120)
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
