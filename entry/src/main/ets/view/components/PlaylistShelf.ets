/**
 * 歌单横滑货架组件
 * 以横滑列表展示一组歌单封面卡片，供发现页 / 我的页复用
 */
import { SongListInfo } from '../../model/entity/models';
import {
  COVER_PLACEHOLDER, PAGE_PAD, RADIUS_M, SPACE_S, SPACE_XL, TEXT_PRIMARY, TEXT_SECONDARY
} from '../../common/utils/format';

@ComponentV2
export struct PlaylistShelf {
  @Param title: string = '';
  @Param lists: SongListInfo[] = [];
  @Param showAuthor: boolean = false;
  @Event onOpen: (listId: number) => void = (_listId: number) => {
  };

  private coverSrc(pl: SongListInfo): string {
    if (pl.coverImgUrl.length > 0) {
      return `${pl.coverImgUrl}?param=240y240`;
    }
    return '';
  }

  private shelfHeight(): number {
    if (this.showAuthor) {
      return 176;
    }
    return 160;
  }

  build() {
    Column() {
      if (this.lists.length > 0) {
        Text(`${this.title} (${this.lists.length})`)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(TEXT_PRIMARY)
          .width('100%')
          .padding({ left: PAGE_PAD, right: PAGE_PAD, top: 18, bottom: SPACE_S })

        List({ space: 10 }) {
          ForEach(this.lists, (pl: SongListInfo) => {
            ListItem() {
              Column() {
                Image(this.coverSrc(pl))
                  .width(112)
                  .height(112)
                  .borderRadius(RADIUS_M)
                  .objectFit(ImageFit.Cover)
                  .backgroundColor(COVER_PLACEHOLDER)
                Text(pl.name)
                  .fontSize(12)
                  .fontColor(TEXT_PRIMARY)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width(112)
                  .margin({ top: 6 })
                if (this.showAuthor) {
                  Text(`by ${pl.author}`)
                    .fontSize(11)
                    .fontColor(TEXT_SECONDARY)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width(112)
                    .margin({ top: 2 })
                }
              }
              .width(112)
              .alignItems(HorizontalAlign.Start)
              .onClick(() => {
                this.onOpen(pl.id);
              })
            }
          }, (pl: SongListInfo) => pl.id.toString())
        }
        .listDirection(Axis.Horizontal)
        .scrollBar(BarState.Off)
        .height(this.shelfHeight())
        .padding({ left: PAGE_PAD, right: PAGE_PAD })
        .nestedScroll({
          scrollForward: NestedScrollMode.SELF_FIRST,
          scrollBackward: NestedScrollMode.SELF_FIRST
        })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
