/**
 * 底部沉浸层占位
 * Tab 可见时与 HdsTabs 共用 tabBarBottomMargin（视觉缝，不含手势条）；
 * Tab 隐藏时才用手势条高度，避免详情页可点区域压到小白条
 */
import {
  MINIPLAYER_GAP, MINIPLAYER_HEIGHT, NAV_INDICATOR_PAD, TAB_BAR_BOTTOM_GAP, TAB_BAR_HEIGHT
} from './format';

@ObservedV2
export class ChromeInsets {
  @Trace tabBarVisible: boolean = true;
  @Trace tabBarHeight: number = TAB_BAR_HEIGHT;
  /** 与 HdsTabs.barFloatingStyle.barBottomMargin 同一数值 */
  @Trace tabBarBottomMargin: number = TAB_BAR_BOTTOM_GAP;
  @Trace safeBottom: number = NAV_INDICATOR_PAD;
  @Trace miniPlayerVisible: boolean = false;
  @Trace miniPlayerHeight: number = MINIPLAYER_HEIGHT;
  @Trace gap: number = MINIPLAYER_GAP;
  /** 迷你播放条下方需要抬起的高度 */
  @Trace liftBelowPlayer: number = TAB_BAR_HEIGHT + TAB_BAR_BOTTOM_GAP + MINIPLAYER_GAP;
  /** 列表/滚动区滚到底时避让底部悬浮层的偏移 */
  @Trace listEndOffset: number = TAB_BAR_HEIGHT + TAB_BAR_BOTTOM_GAP;

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
