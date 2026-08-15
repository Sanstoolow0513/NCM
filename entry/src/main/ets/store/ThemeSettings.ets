@ObservedV2
export class ThemeSettings {
  /** system / light / dark */
  @Trace mode: string = 'system';
  /** 应用字号缩放，1.0 为标准 */
  @Trace fontScale: number = 1.0;
  /** 应用字体族，系统默认 HarmonyOS Sans */
  @Trace fontFamily: string = 'HarmonyOS Sans';
}
