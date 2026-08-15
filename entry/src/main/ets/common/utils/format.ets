/** 毫秒时长格式化为 mm:ss */
export function formatDuration(ms: number): string {
  const totalSec = Math.floor(ms / 1000);
  const m = Math.floor(totalSec / 60);
  const s = totalSec % 60;
  return `${m}:${s.toString().padStart(2, '0')}`;
}

export function sleep(ms: number): Promise<void> {
  return new Promise<void>((resolve: () => void) => {
    setTimeout(() => {
      resolve();
    }, ms);
  });
}

export function errMsg(e: Object): string {
  const m = (e as Error).message;
  return m !== undefined && m.length > 0 ? m : JSON.stringify(e);
}

/** 全局主色（网易云红） */
export const ACCENT_COLOR = $r('app.color.accent');
/** 红底上的文字/图标 */
export const ON_ACCENT = $r('app.color.on_accent');
/** 页面背景 */
export const PAGE_BG = $r('app.color.page_bg');
/** 卡片/控件背景 */
export const CARD_BG = $r('app.color.card_bg');
/** 主文字颜色 */
export const TEXT_PRIMARY = $r('app.color.text_primary');
/** 次级文字颜色 */
export const TEXT_SECONDARY = $r('app.color.text_secondary');
/** 分割线 */
export const DIVIDER_COLOR = $r('app.color.divider');
/** 封面占位底色 */
export const COVER_PLACEHOLDER = $r('app.color.cover_placeholder');
/** 进度条未选中轨道 */
export const SLIDER_TRACK = $r('app.color.slider_track');
/** 进度条滑块 */
export const SLIDER_BLOCK = $r('app.color.slider_block');
/** 主色弱底（VIP 徽章、选中态、高亮 chip） */
export const ACCENT_SOFT = $r('app.color.accent_soft');
/** 迷你播放器半透明底（配合材质模糊） */
export const MINIPLAYER_BG = $r('app.color.miniplayer_bg');
/** 封面模糊背景上的页面色蒙版（详情页头部） */
export const BLUR_SCRIM = $r('app.color.blur_scrim');
/** 底部手势条（小白条）占位，getWindowAvoidArea 尚未返回时的回退值 */
export const NAV_INDICATOR_PAD: number = 20;
/** 文本 TabBar 内容高度回退（不含小白条；小白条由 ChromeInsets.safeBottom 叠加） */
export const TAB_BAR_HEIGHT: number = 56;
/** 迷你播放条高度 */
export const MINIPLAYER_HEIGHT: number = 56;
/** 迷你播放条与 Tab 栏 / 底部安全区之间的间隙 */
export const MINIPLAYER_GAP: number = 8;
/** 迷你条封面与播放页封面的 geometryTransition id */
export const PLAYER_COVER_GEOMETRY_ID: string = 'playerCover';
/** 迷你条展开/收起播放页的 animateTo 时长 */
export const PLAYER_EXPAND_DURATION: number = 350;

/** 圆角梯度 */
export const RADIUS_S: number = 8;
export const RADIUS_M: number = 12;
export const RADIUS_L: number = 16;
export const RADIUS_XL: number = 20;

/** 间距梯度 */
export const SPACE_S: number = 8;
export const SPACE_M: number = 12;
export const SPACE_L: number = 16;
export const SPACE_XL: number = 24;

/** 页面统一左右边距 */
export const PAGE_PAD: number = 16;
