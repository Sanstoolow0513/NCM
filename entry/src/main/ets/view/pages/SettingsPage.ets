/**
 * 设置页
 * 分组卡片式列表：账号 / 外观（主题）/ 关于
 */
import { SettingsViewModel } from '../../viewmodel/SettingsViewModel';
import { StoreHub } from '../../store/StoreHub';
import { SessionSnapshot } from '../../store/SessionSnapshot';
import { ThemeSettings } from '../../store/ThemeSettings';
import {
  ACCENT_COLOR, CARD_BG, DIVIDER_COLOR, NAV_INDICATOR_PAD, PAGE_BG, PAGE_PAD, RADIUS_L, SPACE_M, SPACE_S,
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

const THEME_OPTIONS: ThemeOption[] = [
  new ThemeOption('跟随系统', 'system'),
  new ThemeOption('浅色', 'light'),
  new ThemeOption('深色', 'dark')
];

@ComponentV2
export struct SettingsPage {
  @Param navPathStack: NavPathStack = new NavPathStack();
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

  build() {
    NavDestination() {
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
        }
        .width('100%')
        .backgroundColor(CARD_BG)
        .borderRadius(RADIUS_L)
      }
      .width('100%')
      .height('100%')
      .padding({ left: SPACE_M, right: SPACE_M, bottom: NAV_INDICATOR_PAD })
    }
    .title('设置')
    .hideToolBar(true)
    .backgroundColor(PAGE_BG)
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.BOTTOM])
  }
}
