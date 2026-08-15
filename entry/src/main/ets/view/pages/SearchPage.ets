/**
 * 搜索页
 * 搜索框 + 单曲/歌单/专辑分段结果列表
 */
import { SegmentButtonV2Items, TabSegmentButtonV2 } from '@kit.ArkUI';
import { SongInfo, SongListInfo } from '../../model/entity/models';
import { SearchViewModel } from '../../viewmodel/SearchViewModel';
import { SongRow } from '../components/SongRow';
import { RouteName } from '../../common/router/RouteName';
import { PlaylistRouteParam } from '../../common/router/RouteParams';
import {
  CARD_BG, COVER_PLACEHOLDER, PAGE_BG, PAGE_PAD, RADIUS_M, SPACE_L, SPACE_M, SPACE_S, TEXT_PRIMARY, TEXT_SECONDARY
} from '../../common/utils/format';

@ComponentV2
export struct SearchPage {
  @Consumer('navStack') navStack: NavPathStack = new NavPathStack();
  @Local vm: SearchViewModel = new SearchViewModel();
  @Local searchTypeItems: SegmentButtonV2Items = new SegmentButtonV2Items([
    { text: '单曲' },
    { text: '歌单' },
    { text: '专辑' }
  ]);

  @Monitor('vm.toastMessage')
  onSearchToast(_mon: IMonitor): void {
    if (this.vm.toastMessage.length > 0) {
      this.getUIContext().getPromptAction().showToast({ message: this.vm.toastMessage });
      this.vm.toastMessage = '';
    }
  }

  private openList(listId: number, isAlbum: boolean): void {
    const param: PlaylistRouteParam = { listId: listId, isAlbum: isAlbum };
    this.navStack.pushPath({ name: RouteName.PLAYLIST_DETAIL, param: param });
  }

  @Builder
  SearchPlaceholder() {
    Column() {
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(40)
        .fontColor([TEXT_SECONDARY])
      Text('搜索歌曲、歌单、专辑')
        .fontSize(15)
        .fontColor(TEXT_PRIMARY)
        .margin({ top: SPACE_L })
      Text('输入关键词开始探索')
        .fontSize(13)
        .fontColor(TEXT_SECONDARY)
        .margin({ top: 6 })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .padding({ bottom: 120 })
  }

  @Builder
  ListResultRow(sl: SongListInfo) {
    Row() {
      Image(`${sl.coverImgUrl}?param=120y120`)
        .width(52)
        .height(52)
        .borderRadius(RADIUS_M)
        .objectFit(ImageFit.Cover)
        .backgroundColor(COVER_PLACEHOLDER)
      Column() {
        Text(sl.name)
          .fontSize(15)
          .fontColor(TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(sl.author)
          .fontSize(12)
          .fontColor(TEXT_SECONDARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: SPACE_M })
    }
    .width('100%')
    .padding({ left: PAGE_PAD, right: PAGE_PAD, top: 10, bottom: 10 })
    .onClick(() => {
      this.openList(sl.id, this.vm.tab === 2);
    })
  }

  @Builder
  SearchResults() {
    Column() {
      Column() {
        TabSegmentButtonV2({
          items: this.searchTypeItems,
          selectedIndex: this.vm.tab,
          enableStateAnimation: true,
          onItemClicked: (index: number) => {
            this.vm.selectTab(index);
          }
        })
      }
      .width('100%')
      .padding({ left: PAGE_PAD, right: PAGE_PAD, top: SPACE_S, bottom: 4 })

      if (this.vm.tab === 0) {
        if (this.vm.songs.length === 0) {
          Text('未找到相关单曲')
            .fontSize(14)
            .fontColor(TEXT_SECONDARY)
            .margin({ top: 48 })
            .width('100%')
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
        } else {
          List() {
            ForEach(this.vm.songs, (song: SongInfo, songIndex: number) => {
              ListItem() {
                SongRow({
                  song: song,
                  songIndex: songIndex,
                  onTap: (idx: number) => {
                    this.vm.playAt(idx);
                  }
                })
              }
            }, (song: SongInfo) => song.id.toString())
          }
          .layoutWeight(1)
          .width('100%')
          .scrollBar(BarState.Off)
          .contentEndOffset(140)
        }
      } else {
        if (this.vm.lists.length === 0) {
          Text('未找到相关结果')
            .fontSize(14)
            .fontColor(TEXT_SECONDARY)
            .margin({ top: 48 })
            .width('100%')
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
        } else {
          List() {
            ForEach(this.vm.lists, (sl: SongListInfo) => {
              ListItem() {
                this.ListResultRow(sl)
              }
            }, (sl: SongListInfo) => sl.id.toString())
          }
          .layoutWeight(1)
          .width('100%')
          .scrollBar(BarState.Off)
          .contentEndOffset(140)
        }
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  build() {
    Column() {
      Search({ placeholder: '搜索歌曲、歌单、专辑' })
        .placeholderColor(TEXT_SECONDARY)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(CARD_BG)
        .height(40)
        .margin({ left: PAGE_PAD, right: PAGE_PAD, top: SPACE_S })
        .onChange((value: string) => {
          this.vm.onKeywordChange(value);
        })
        .onSubmit((value: string) => {
          this.vm.doSearch(value);
        })

      if (this.vm.loading) {
        Column() {
          LoadingProgress().width(40).height(40).color(TEXT_SECONDARY)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      } else if (this.vm.searched) {
        this.SearchResults()
      } else {
        this.SearchPlaceholder()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BG)
  }
}
