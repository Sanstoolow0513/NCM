/**
 * 窗口避让区（状态栏 / 小白条）
 * 首页 Column 用 safeTop、safeBottom 做 padding；迷你条和 Tab 走文档流，不再叠层抬升。
 */
import { NAV_INDICATOR_PAD, NAV_TITLE_CONTENT } from './format';

@ObservedV2
export class ChromeInsets {
  @Trace tabBarVisible: boolean = true;
  @Trace safeBottom: number = NAV_INDICATOR_PAD;
  /** 状态栏 / 挖孔高度 */
  @Trace safeTop: number = 0;
  @Trace miniPlayerVisible: boolean = false;
  /** 列表滚到底的额外避让；迷你条已在文档流中，保持 0 */
  @Trace listEndOffset: number = 0;

  setTabBarVisible(visible: boolean): void {
    if (visible === this.tabBarVisible) {
      return;
    }
    this.tabBarVisible = visible;
  }

  setSafeBottom(vp: number): void {
    const safe: number = vp > 0 ? vp : NAV_INDICATOR_PAD;
    if (safe === this.safeBottom) {
      return;
    }
    this.safeBottom = safe;
  }

  setSafeTop(vp: number): void {
    const top: number = vp > 0 ? vp : 0;
    if (top === this.safeTop) {
      return;
    }
    this.safeTop = top;
  }

  setMiniPlayerVisible(visible: boolean): void {
    if (visible === this.miniPlayerVisible) {
      return;
    }
    this.miniPlayerVisible = visible;
  }

  /** 子页标题栏高度（父级 Column 已垫过状态栏） */
  titleBarHeight(): number {
    return NAV_TITLE_CONTENT;
  }
}
