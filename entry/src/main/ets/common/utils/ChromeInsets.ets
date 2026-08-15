/**
 * 底部沉浸层占位
 * 迷你条铺满层只 ignore 顶部，底边走布局安全区躲避小白条；有文本 Tab 时再抬起栏高。
 * 列表滚到底：首页 Tab 已占布局，只需再避让迷你条；子页 ignore 了底部安全区，再叠加小白条。
 */
import {
  MINIPLAYER_GAP, MINIPLAYER_HEIGHT, NAV_INDICATOR_PAD, TAB_BAR_HEIGHT
} from './format';

@ObservedV2
export class ChromeInsets {
  @Trace tabBarVisible: boolean = true;
  @Trace tabBarHeight: number = TAB_BAR_HEIGHT;
  @Trace safeBottom: number = NAV_INDICATOR_PAD;
  /** 状态栏 / 挖孔高度 */
  @Trace safeTop: number = 0;
  @Trace miniPlayerVisible: boolean = false;
  @Trace miniPlayerHeight: number = MINIPLAYER_HEIGHT;
  @Trace gap: number = MINIPLAYER_GAP;
  /** 迷你条相对布局安全区底边再抬起的高度（不含小白条） */
  @Trace liftBelowPlayer: number = TAB_BAR_HEIGHT + MINIPLAYER_GAP;
  /** 列表/滚动区滚到底时避让底部悬浮层的偏移 */
  @Trace listEndOffset: number = 0;

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
    let lift: number = this.gap;
    if (this.tabBarVisible) {
      lift = lift + this.tabBarHeight;
    }
    this.liftBelowPlayer = lift;
    let listEnd: number = 0;
    if (!this.tabBarVisible) {
      listEnd = listEnd + this.safeBottom;
    }
    if (this.miniPlayerVisible) {
      listEnd = listEnd + this.miniPlayerHeight + this.gap;
    }
    this.listEndOffset = listEnd;
  }
}
