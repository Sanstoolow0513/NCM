/**
 * 搜索结果面板
 * 单曲 / 歌单 / 专辑分段列表，供发现页顶栏搜索复用
 */
import { SegmentButtonV2Items, TabSegmentButtonV2 } from '@kit.ArkUI';
import { SongInfo, SongListInfo } from '../../model/entity/models';
import { SearchViewModel } from '../../viewmodel/SearchViewModel';
import { SongRow } from './SongRow';
import { PlaylistRow } from './PlaylistRow';
import { RouteName } from '../../common/router/RouteName';
import { PlaylistRouteParam } from '../../common/router/RouteParams';
import { ChromeInsets } from '../../common/utils/ChromeInsets';
import { PAGE_PAD, SPACE_S, TEXT_SECONDARY } from '../../common/utils/format';

@ComponentV2
export struct SearchResultPanel {
  @Consumer('navStack') navStack: NavPathStack = new NavPathStack();
  @Consumer('chromeInsets') chrome: ChromeInsets = new ChromeInsets();
  @Param vm: SearchViewModel = new SearchViewModel();
  @Local searchTypeItems: SegmentButtonV2Items = new SegmentButtonV2Items([
    { text: '单曲' },
    { text: '歌单' },
    { text: '专辑' }
  ]);

  private openList(listId: number, isAlbum: boolean): void {
    const param: PlaylistRouteParam = { listId: listId, isAlbum: isAlbum };
    this.navStack.pushPath({ name: RouteName.PLAYLIST_DETAIL, param: param });
  }

  build() {
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
          .contentEndOffset(this.chrome.listEndOffset)
        }
      } else if (this.vm.lists.length === 0) {
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
              PlaylistRow({
                list: sl,
                showAuthor: true,
                onOpen: (listId: number) => {
                  this.openList(listId, this.vm.tab === 2);
                }
              })
            }
          }, (sl: SongListInfo) => sl.id.toString())
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        .contentEndOffset(this.chrome.listEndOffset)
      }
    }
    .width('100%')
    .layoutWeight(1)
  }
}
