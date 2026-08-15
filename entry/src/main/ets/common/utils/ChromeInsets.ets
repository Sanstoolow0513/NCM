/**
 * 底部沉浸层占位
 * 根据系统导航指示条、悬浮 Tab 是否可见、迷你播放条是否出现，计算播放条抬升量与列表尾部偏移
 */
import { MINIPLAYER_GAP, MINIPLAYER_HEIGHT, NAV_INDICATOR_PAD, TAB_BAR_HEIGHT } from './format';

@ObservedV2
export class ChromeInsets {
  @Trace tabBarVisible: boolean = true;
  @Trace tabBarHeight: number = TAB_BAR_HEIGHT;
  @Trace safeBottom: number = NAV_INDICATOR_PAD;
  @Trace miniPlayerVisible: boolean = false;
  @Trace miniPlayerHeight: number = MINIPLAYER_HEIGHT;
  @Trace gap: number = MINIPLAYER_GAP;
  /** 迷你播放条下方需要抬起的高度（Tab 栏 + 安全区 + 间隙） */
  @Trace liftBelowPlayer: number = TAB_BAR_HEIGHT + NAV_INDICATOR_PAD + MINIPLAYER_GAP;
  /** 列表/滚动区滚到底时避让底部悬浮层的偏移 */
  @Trace listEndOffset: number = TAB_BAR_HEIGHT + NAV_INDICATOR_PAD;

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
    let lift: number = this.safeBottom + this.gap;
    if (this.tabBarVisible) {
      lift = lift + this.tabBarHeight;
    }
    this.liftBelowPlayer = lift;
    let listEnd: number = this.safeBottom;
    if (this.tabBarVisible) {
      listEnd = listEnd + this.tabBarHeight;
    }
    if (this.miniPlayerVisible) {
      listEnd = listEnd + this.miniPlayerHeight + this.gap;
    }
    this.listEndOffset = listEnd;
  }
}
