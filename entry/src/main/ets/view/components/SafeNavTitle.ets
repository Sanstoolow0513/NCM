/**
 * 子页标题
 * 父级 Column 已用 safeTop 垫过状态栏，这里只放返回和标题
 */
import { NAV_TITLE_CONTENT, PAGE_PAD, TEXT_PRIMARY } from '../../common/utils/format';

@ComponentV2
export struct SafeNavTitle {
  @Param title: string = '';
  @Param navPathStack: NavPathStack = new NavPathStack();

  build() {
    Row() {
      SymbolGlyph($r('sys.symbol.chevron_left'))
        .fontSize(22)
        .fontColor([TEXT_PRIMARY])
        .width(40)
        .height(40)
        .onClick(() => {
          this.navPathStack.pop();
        })
      Text(this.title)
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_PRIMARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .width('100%')
    .height(NAV_TITLE_CONTENT)
    .alignItems(VerticalAlign.Center)
    .padding({ left: 4, right: PAGE_PAD })
  }
}
