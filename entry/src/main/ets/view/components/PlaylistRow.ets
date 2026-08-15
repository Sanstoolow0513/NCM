/**
 * 歌单/专辑列表行
 * 封面 + 标题 + 可选作者副标题 + 右向箭头
 */
import { SongListInfo } from '../../model/entity/models';
import {
  COVER_PLACEHOLDER, PAGE_PAD, RADIUS_M, SPACE_M, TEXT_PRIMARY, TEXT_SECONDARY
} from '../../common/utils/format';

@ComponentV2
export struct PlaylistRow {
  @Param list: SongListInfo = new SongListInfo();
  @Param showAuthor: boolean = false;
  @Event onOpen: (listId: number) => void = (_listId: number) => {
  };

  private coverSrc(): string {
    if (this.list.coverImgUrl.length > 0) {
      return `${this.list.coverImgUrl}?param=120y120`;
    }
    return '';
  }

  build() {
    Row() {
      Image(this.coverSrc())
        .width(52)
        .height(52)
        .borderRadius(RADIUS_M)
        .objectFit(ImageFit.Cover)
        .backgroundColor(COVER_PLACEHOLDER)
      Column() {
        Text(this.list.name)
          .fontSize(15)
          .fontColor(TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (this.showAuthor && this.list.author.length > 0) {
          Text(`by ${this.list.author}`)
            .fontSize(12)
            .fontColor(TEXT_SECONDARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: SPACE_M, right: 8 })
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(12)
        .fontColor([TEXT_SECONDARY])
    }
    .width('100%')
    .padding({ left: PAGE_PAD, right: PAGE_PAD, top: 10, bottom: 10 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onOpen(this.list.id);
    })
  }
}
