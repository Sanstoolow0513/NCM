/**
 * 设置页
 * 分组卡片式列表：账号 / 外观（主题、字号、字体）/ 关于（声明与鸣谢）
 */
import { SettingsViewModel } from '../../viewmodel/SettingsViewModel';
import { StoreHub } from '../../store/StoreHub';
import { SessionSnapshot } from '../../store/SessionSnapshot';
import { ThemeSettings } from '../../store/ThemeSettings';
import { ChromeInsets } from '../../common/utils/ChromeInsets';
import {
  ACCENT_COLOR, CARD_BG, DIVIDER_COLOR, PAGE_BG, PAGE_PAD, RADIUS_L, SPACE_L, SPACE_M, SPACE_S,
  SPACE_XL, TEXT_PRIMARY, TEXT_SECONDARY
} from '../../common/utils/format';

class ThemeOption {
  label: string = '';
  value: string = '';

  constructor(label: string, value: string) {
    this.label = label;
    this.value = value;
  }
}

class FontScaleOption {
  label: string = '';
  scale: number = 1.0;

  constructor(label: string, scale: number) {
    this.label = label;
    this.scale = scale;
  }
}

const THEME_OPTIONS: ThemeOption[] = [
  new ThemeOption('跟随系统', 'system'),
  new ThemeOption('浅色', 'light'),
  new ThemeOption('深色', 'dark')
];

const FONT_SCALE_OPTIONS: FontScaleOption[] = [
  new FontScaleOption('小', 0.85),
  new FontScaleOption('标准', 1.0),
  new FontScaleOption('大', 1.15),
  new FontScaleOption('特大', 1.3)
];

const FONT_FAMILY_OPTIONS: ThemeOption[] = [
  new ThemeOption('系统默认', 'HarmonyOS Sans'),
  new ThemeOption('鸿蒙窄体', 'HarmonyOS Sans Condensed'),
  new ThemeOption('衬线体', 'serif')
];

@ComponentV2
export struct SettingsPage {
  @Param navPathStack: NavPathStack = new NavPathStack();
  @Consumer('chromeInsets') chrome: ChromeInsets = new ChromeInsets();
  @Local vm: SettingsViewModel = new SettingsViewModel();
  @Local session: SessionSnapshot = StoreHub.session();
  @Local theme: ThemeSettings = StoreHub.theme();

  @Monitor('vm.toastMessage')
  onToast(_mon: IMonitor): void {
    if (this.vm.toastMessage.length > 0) {
      this.getUIContext().getPromptAction().showToast({ message: this.vm.toastMessage });
      this.vm.toastMessage = '';
    }
  }

  @Builder
  GroupTitle(title: string) {
    Text(title)
      .fontSize(13)
      .fontColor(TEXT_SECONDARY)
      .width('100%')
      .padding({ left: PAGE_PAD, top: SPACE_XL, bottom: SPACE_S })
  }

  @Builder
  InsetDivider() {
    Divider()
      .color(DIVIDER_COLOR)
      .margin({ left: PAGE_PAD })
  }

  @Builder
  ThemeRow(option: ThemeOption) {
    Row() {
      Text(option.label)
        .fontSize(15)
        .fontColor(TEXT_PRIMARY)
        .layoutWeight(1)
      Radio({ value: option.value, group: 'themeMode' })
        .checked(this.theme.mode === option.value)
        .radioStyle({ checkedBackgroundColor: ACCENT_COLOR })
        .onChange((isChecked: boolean) => {
          if (isChecked) {
            this.vm.setThemeMode(option.value);
          }
        })
    }
    .width('100%')
    .height(52)
    .padding({ left: PAGE_PAD, right: PAGE_PAD })
  }

  @Builder
  FontScaleRow(option: FontScaleOption) {
    Row() {
      Text(option.label)
        .fontSize(15)
        .fontColor(TEXT_PRIMARY)
        .layoutWeight(1)
      Radio({ value: option.label, group: 'fontScale' })
        .checked(this.theme.fontScale === option.scale)
        .radioStyle({ checkedBackgroundColor: ACCENT_COLOR })
        .onChange((isChecked: boolean) => {
          if (isChecked) {
            this.vm.setFontScale(option.scale);
          }
        })
    }
    .width('100%')
    .height(52)
    .padding({ left: PAGE_PAD, right: PAGE_PAD })
  }

  @Builder
  FontFamilyRow(option: ThemeOption) {
    Row() {
      Text(option.label)
        .fontSize(15)
        .fontColor(TEXT_PRIMARY)
        .layoutWeight(1)
      Radio({ value: option.value, group: 'fontFamily' })
        .checked(this.theme.fontFamily === option.value)
        .radioStyle({ checkedBackgroundColor: ACCENT_COLOR })
        .onChange((isChecked: boolean) => {
          if (isChecked) {
            this.vm.setFontFamily(option.value);
          }
        })
    }
    .width('100%')
    .height(52)
    .padding({ left: PAGE_PAD, right: PAGE_PAD })
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          this.GroupTitle('账号')

          Column() {
            if (this.session.loginInfo !== null && this.session.loginInfo.uid > 0) {
              Row() {
                Image(this.session.loginInfo.avatarUrl)
                  .width(44)
                  .height(44)
                  .borderRadius(22)
                Text(this.session.loginInfo.nickname)
                  .fontSize(16)
                  .fontColor(TEXT_PRIMARY)
                  .margin({ left: SPACE_M })
              }
              .width('100%')
              .padding({ left: PAGE_PAD, right: PAGE_PAD, top: SPACE_M, bottom: SPACE_M })

              this.InsetDivider()

              Text('退出登录')
                .fontSize(15)
                .fontColor(TEXT_PRIMARY)
                .width('100%')
                .height(52)
                .padding({ left: PAGE_PAD, right: PAGE_PAD })
                .onClick(() => {
                  this.vm.doLogout().then((ok: boolean) => {
                    if (ok) {
                      this.navPathStack.pop();
                    }
                  });
                })
            } else {
              Text('未登录')
                .fontSize(15)
                .fontColor(TEXT_SECONDARY)
                .width('100%')
                .padding({ left: PAGE_PAD, right: PAGE_PAD, top: SPACE_M, bottom: 4 })
              Text('去登录')
                .fontSize(15)
                .fontColor(TEXT_PRIMARY)
                .width('100%')
                .height(52)
                .padding({ left: PAGE_PAD, right: PAGE_PAD })
                .onClick(() => {
                  this.navPathStack.pop();
                })
            }
          }
          .width('100%')
          .backgroundColor(CARD_BG)
          .borderRadius(RADIUS_L)

          this.GroupTitle('外观')

          Column() {
            ForEach(THEME_OPTIONS, (option: ThemeOption, index: number) => {
              Column() {
                if (index > 0) {
                  this.InsetDivider()
                }
                this.ThemeRow(option)
              }
              .width('100%')
            }, (option: ThemeOption) => option.value)
          }
          .width('100%')
          .backgroundColor(CARD_BG)
          .borderRadius(RADIUS_L)

          this.GroupTitle('字号')

          Column() {
            ForEach(FONT_SCALE_OPTIONS, (option: FontScaleOption, index: number) => {
              Column() {
                if (index > 0) {
                  this.InsetDivider()
                }
                this.FontScaleRow(option)
              }
              .width('100%')
            }, (option: FontScaleOption) => option.label)
          }
          .width('100%')
          .backgroundColor(CARD_BG)
          .borderRadius(RADIUS_L)

          this.GroupTitle('字体')

          Column() {
            ForEach(FONT_FAMILY_OPTIONS, (option: ThemeOption, index: number) => {
              Column() {
                if (index > 0) {
                  this.InsetDivider()
                }
                this.FontFamilyRow(option)
              }
              .width('100%')
            }, (option: ThemeOption) => option.value)
          }
          .width('100%')
          .backgroundColor(CARD_BG)
          .borderRadius(RADIUS_L)

          this.GroupTitle('关于')

          Column() {
            Row() {
              Text('NCM for HarmonyOS')
                .fontSize(15)
                .fontColor(TEXT_PRIMARY)
                .layoutWeight(1)
              Text('版本 1.0.0')
                .fontSize(14)
                .fontColor(TEXT_SECONDARY)
            }
            .width('100%')
            .height(52)
            .padding({ left: PAGE_PAD, right: PAGE_PAD })

            this.InsetDivider()

            Text('声明')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(TEXT_PRIMARY)
              .width('100%')
              .padding({ left: PAGE_PAD, right: PAGE_PAD, top: SPACE_M, bottom: SPACE_S })
            Text('本应用为非营利、开源的第三方 HarmonyOS 客户端，仅供学习与个人使用，不提供任何商业服务。')
              .fontSize(13)
              .fontColor(TEXT_SECONDARY)
              .width('100%')
              .padding({ left: PAGE_PAD, right: PAGE_PAD, bottom: SPACE_S })
            Text('本应用与网易公司及其网易云音乐官方产品没有任何隶属、合作或授权关系。音乐版权归权利人所有。')
              .fontSize(13)
              .fontColor(TEXT_SECONDARY)
              .width('100%')
              .padding({ left: PAGE_PAD, right: PAGE_PAD, bottom: SPACE_M })

            this.InsetDivider()

            Text('鸣谢上游')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(TEXT_PRIMARY)
              .width('100%')
              .padding({ left: PAGE_PAD, right: PAGE_PAD, top: SPACE_M, bottom: SPACE_S })
            Text('加密协议移植自 gmg137/netease-cloud-music-api（ncm-api）的 weapi / eapi 实现。界面基于 HarmonyOS ArkUI 与 UIDesignKit。')
              .fontSize(13)
              .fontColor(TEXT_SECONDARY)
              .width('100%')
              .padding({ left: PAGE_PAD, right: PAGE_PAD, bottom: SPACE_L })
          }
          .width('100%')
          .backgroundColor(CARD_BG)
          .borderRadius(RADIUS_L)
        }
        .width('100%')
        .padding({ left: SPACE_M, right: SPACE_M, bottom: this.chrome.listEndOffset })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .title('设置')
    .hideToolBar(true)
    .backgroundColor(PAGE_BG)
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.BOTTOM])
  }
}
