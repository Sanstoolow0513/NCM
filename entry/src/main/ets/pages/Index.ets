import { curves, window } from '@kit.ArkUI';
import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { MiniPlayer } from '../view/components/MiniPlayer';
import { DailySongsPage } from '../view/pages/DailySongsPage';
import { DiscoverPage } from '../view/pages/DiscoverPage';
import { MinePage } from '../view/pages/MinePage';
import { PlayerPage } from '../view/pages/PlayerPage';
import { PlaylistDetailPage } from '../view/pages/PlaylistDetailPage';
import { SettingsPage } from '../view/pages/SettingsPage';
import { StoreHub } from '../store/StoreHub';
import { PlayerSnapshot } from '../store/PlayerSnapshot';
import { SessionSnapshot } from '../store/SessionSnapshot';
import { LikeService } from '../service/like/LikeService';
import { RouteName } from '../common/router/RouteName';
import { PlaylistRouteParam } from '../common/router/RouteParams';
import { ACCENT_COLOR, MINIPLAYER_GAP, PAGE_BG, PLAYER_EXPAND_DURATION, TEXT_SECONDARY } from '../common/utils/format';
import { ChromeInsets } from '../common/utils/ChromeInsets';
import { ThemeSettings } from '../store/ThemeSettings';

@Entry
@ComponentV2
struct Index {
  @Provider('navStack') navStack: NavPathStack = new NavPathStack();
  @Provider('chromeInsets') chrome: ChromeInsets = new ChromeInsets();
  @Local player: PlayerSnapshot = StoreHub.player();
  @Local session: SessionSnapshot = StoreHub.session();
  @Local theme: ThemeSettings = StoreHub.theme();
  @Local currentTab: number = 0;
  private tabsController: TabsController = new TabsController();
  private hostWindow: window.Window | undefined = undefined;
  private onNavBar: boolean = true;

  aboutToAppear(): void {
    LikeService.get().onSession(this.session.loginInfo);
    this.syncChrome();
    StoreHub.setColorModeListener((): void => {
      this.applySystemBars();
    });
    this.navStack.setInterception({
      didShow: (_from: NavDestinationContext | NavBar, to: NavDestinationContext | NavBar,
        _operation: NavigationOperation, _isAnimated: boolean) => {
        this.onNavBar = to === 'navBar';
        this.syncChrome();
      }
    });
    this.bindAvoidArea();
  }

  aboutToDisappear(): void {
    StoreHub.setColorModeListener(null);
    this.unbindAvoidArea();
  }

  @Monitor('session.loginInfo')
  onSessionChange(_mon: IMonitor): void {
    LikeService.get().onSession(this.session.loginInfo);
  }

  @Monitor('player.toastSeq')
  onPlayerToast(_mon: IMonitor): void {
    if (this.player.toastMessage.length > 0) {
      this.getUIContext().getPromptAction().showToast({ message: this.player.toastMessage });
    }
  }

  @Monitor('player.currentSong', 'player.fullPlayerOpen', 'theme.mode')
  onPlayerChrome(_mon: IMonitor): void {
    if (this.player.currentSong === null) {
      this.player.fullPlayerOpen = false;
      this.player.fullPlayerQueueOpen = false;
    } else if (!this.player.fullPlayerOpen && this.player.fullPlayerQueueOpen) {
      this.player.fullPlayerQueueOpen = false;
    }
    this.syncChrome();
    this.applySystemBars();
  }

  private syncChrome(): void {
    this.chrome.setTabBarVisible(this.onNavBar && !this.player.fullPlayerOpen);
    this.chrome.setMiniPlayerVisible(this.player.currentSong !== null && !this.player.fullPlayerOpen);
  }

  private closeFullPlayer(): void {
    if (!this.player.fullPlayerOpen) {
      this.player.fullPlayerQueueOpen = false;
      return;
    }
    this.player.fullPlayerQueueOpen = false;
    this.getUIContext().animateTo({ duration: PLAYER_EXPAND_DURATION, curve: Curve.Friction }, () => {
      this.player.fullPlayerOpen = false;
    });
  }

  onBackPress(): boolean {
    if (this.player.fullPlayerQueueOpen) {
      this.player.fullPlayerQueueOpen = false;
      return true;
    }
    if (this.player.fullPlayerOpen) {
      this.closeFullPlayer();
      return true;
    }
    return false;
  }

  /** 状态栏/导航条图标色跟实际 ColorMode，而不是设置项里有没有选「深色」 */
  private isDarkUi(): boolean {
    if (this.player.fullPlayerOpen) {
      return true;
    }
    if (this.theme.mode === 'dark') {
      return true;
    }
    if (this.theme.mode === 'light') {
      return false;
    }
    const host: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    return host.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
  }

  private applySystemBars(): void {
    if (this.hostWindow === undefined) {
      return;
    }
    const content: string = this.isDarkUi() ? '#FFFFFF' : '#000000';
    this.hostWindow.setWindowSystemBarProperties({
      statusBarColor: '#00000000',
      navigationBarColor: '#00000000',
      statusBarContentColor: content,
      navigationBarContentColor: content
    }).catch((err: Error) => {
      console.error('[Index] setWindowSystemBarProperties failed: ' + JSON.stringify(err));
    });
  }

  private bindAvoidArea(): void {
    const host: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    window.getLastWindow(host).then((win: window.Window) => {
      this.hostWindow = win;
      const bottomAvoid: window.AvoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      this.chrome.setSafeBottom(this.getUIContext().px2vp(bottomAvoid.bottomRect.height));
      const systemAvoid: window.AvoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      this.chrome.setSafeTop(this.getUIContext().px2vp(systemAvoid.topRect.height));
      this.applySystemBars();
      win.on('avoidAreaChange', (data: window.AvoidAreaOptions) => {
        if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
          this.chrome.setSafeBottom(this.getUIContext().px2vp(data.area.bottomRect.height));
        } else if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
          this.chrome.setSafeTop(this.getUIContext().px2vp(data.area.topRect.height));
        }
      });
    }).catch((err: Error) => {
      console.error('[Index] getLastWindow failed: ' + JSON.stringify(err));
    });
  }

  private unbindAvoidArea(): void {
    if (this.hostWindow !== undefined) {
      this.hostWindow.off('avoidAreaChange');
      this.hostWindow = undefined;
    }
  }

  @Builder
  PageMap(name: string, param: Object) {
    if (name === RouteName.PLAYLIST_DETAIL) {
      PlaylistDetailPage({
        navPathStack: this.navStack,
        listId: (param as PlaylistRouteParam).listId,
        isAlbum: (param as PlaylistRouteParam).isAlbum
      })
    } else if (name === RouteName.DAILY_SONGS) {
      DailySongsPage({ navPathStack: this.navStack })
    } else if (name === RouteName.SETTINGS) {
      SettingsPage({ navPathStack: this.navStack })
    }
  }

  @LocalBuilder
  HomeTabBar() {
    Row() {
      Column({ space: 4 }) {
        Text('发现')
          .fontSize(16)
          .fontWeight(this.currentTab === 0 ? FontWeight.Medium : FontWeight.Regular)
          .fontColor(this.currentTab === 0 ? ACCENT_COLOR : TEXT_SECONDARY)
        Row()
          .width(20)
          .height(2)
          .borderRadius(1)
          .backgroundColor(this.currentTab === 0 ? ACCENT_COLOR : Color.Transparent)
      }
      .layoutWeight(1)
      .padding({ top: 8, bottom: 10 })
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        this.tabsController.changeIndex(0);
        this.currentTab = 0;
      })

      Column({ space: 4 }) {
        Text('我的')
          .fontSize(16)
          .fontWeight(this.currentTab === 1 ? FontWeight.Medium : FontWeight.Regular)
          .fontColor(this.currentTab === 1 ? ACCENT_COLOR : TEXT_SECONDARY)
        Row()
          .width(20)
          .height(2)
          .borderRadius(1)
          .backgroundColor(this.currentTab === 1 ? ACCENT_COLOR : Color.Transparent)
      }
      .layoutWeight(1)
      .padding({ top: 8, bottom: 10 })
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        this.tabsController.changeIndex(1);
        this.currentTab = 1;
      })
    }
    .width('100%')
    .backgroundColor(PAGE_BG)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        Navigation(this.navStack) {
          Tabs({ barPosition: BarPosition.End, controller: this.tabsController, index: this.currentTab }) {
            TabContent() {
              DiscoverPage()
            }

            TabContent() {
              MinePage()
            }
          }
          .barHeight(0)
          .clip(false)
          .onChange((i: number) => {
            this.currentTab = i;
          })
          .width('100%')
          .height('100%')
        }
        .navDestination(this.PageMap)
        .hideTitleBar(true)
        .hideToolBar(true)
        .mode(NavigationMode.Stack)
        .clip(false)
        .width('100%')
        .layoutWeight(1)

        if (this.chrome.miniPlayerVisible) {
          Column() {
            MiniPlayer()
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .margin({ bottom: MINIPLAYER_GAP })
          .transition(TransitionEffect.OPACITY.animation({
            duration: PLAYER_EXPAND_DURATION,
            curve: Curve.Friction
          }))
          .animation({ curve: curves.springMotion() })
        }

        if (this.chrome.tabBarVisible) {
          this.HomeTabBar()
        }
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .clip(false)
      .padding({ top: this.chrome.safeTop, bottom: this.chrome.safeBottom })

      if (this.player.fullPlayerOpen) {
        Column() {
          PlayerPage()
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Black)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
        .clip(false)
        .transition(TransitionEffect.asymmetric(
          TransitionEffect.opacity(0.99).animation({ duration: PLAYER_EXPAND_DURATION, curve: Curve.Friction }),
          TransitionEffect.OPACITY.animation({ duration: PLAYER_EXPAND_DURATION, curve: Curve.Friction })
        ))
      }
    }
    .width('100%')
    .height('100%')
    .clip(false)
    .backgroundColor(PAGE_BG)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
  }
}
