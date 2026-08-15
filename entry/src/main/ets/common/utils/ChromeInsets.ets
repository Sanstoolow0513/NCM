/**
 * 底部沉浸层占位
 * 窗口全屏后 Tab / 迷你条都要加上手势条高度；Tab 可见时 barBottomMargin = 视觉缝 + 手势条
 */
import {
  MINIPLAYER_GAP, MINIPLAYER_HEIGHT, NAV_INDICATOR_PAD, TAB_BAR_BOTTOM_GAP, TAB_BAR_HEIGHT
} from './format';

@ObservedV2
export class ChromeInsets {
  @Trace tabBarVisible: boolean = true;
  @Trace tabBarHeight: number = TAB_BAR_HEIGHT;
  /** 与 HdsTabs.barFloatingStyle.barBottomMargin 同一数值（含手势条） */
  @Trace tabBarBottomMargin: number = TAB_BAR_BOTTOM_GAP + NAV_INDICATOR_PAD;
  @Trace safeBottom: number = NAV_INDICATOR_PAD;
  /** 状态栏 / 挖孔高度 */
  @Trace safeTop: number = 0;
  @Trace miniPlayerVisible: boolean = false;
  @Trace miniPlayerHeight: number = MINIPLAYER_HEIGHT;
  @Trace gap: number = MINIPLAYER_GAP;
  /** 迷你播放条下方需要抬起的高度 */
  @Trace liftBelowPlayer: number = TAB_BAR_HEIGHT + TAB_BAR_BOTTOM_GAP + NAV_INDICATOR_PAD + MINIPLAYER_GAP;
  /** 列表/滚动区滚到底时避让底部悬浮层的偏移 */
  @Trace listEndOffset: number = TAB_BAR_HEIGHT + TAB_BAR_BOTTOM_GAP + NAV_INDICATOR_PAD;

  setTabBarVisible(visible: boolean): void {
    if (visible === this.tabBarVisible) {
      return;
    }
    this.tabBarVisible = visible;
    this.sync();
  }

  setSafeBottom(vp: number): void {
    const safe: number = vp > 0 ? vp : NAV_INDICATOR_PAD;
    if (safe === this.safeBottom) {
      return;
    }
    this.safeBottom = safe;
    this.sync();
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
    this.sync();
  }

  setMiniPlayerHeight(height: number): void {
    if (height <= 0 || height === this.miniPlayerHeight) {
      return;
    }
    this.miniPlayerHeight = height;
    this.sync();
  }

  sync(): void {
    this.tabBarBottomMargin = TAB_BAR_BOTTOM_GAP + this.safeBottom;
    let lift: number = this.gap;
    if (this.tabBarVisible) {
      lift = lift + this.tabBarBottomMargin + this.tabBarHeight;
    } else {
      lift = lift + this.safeBottom;
    }
    this.liftBelowPlayer = lift;
    let listEnd: number = 0;
    if (this.tabBarVisible) {
      listEnd = listEnd + this.tabBarBottomMargin + this.tabBarHeight;
    } else {
      listEnd = listEnd + this.safeBottom;
    }
    if (this.miniPlayerVisible) {
      listEnd = listEnd + this.miniPlayerHeight + this.gap;
    }
    this.listEndOffset = listEnd;
  }
}
