import { HdsTabs, HdsTabsController, hdsMaterial } from '@kit.UIDesignKit';
import { SymbolGlyphModifier, curves, window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
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
import { PAGE_BG } from '../common/utils/format';
import { ChromeInsets } from '../common/utils/ChromeInsets';

@Entry
@ComponentV2
struct Index {
  @Provider('navStack') navStack: NavPathStack = new NavPathStack();
  @Provider('chromeInsets') chrome: ChromeInsets = new ChromeInsets();
  @Local player: PlayerSnapshot = StoreHub.player();
  @Local session: SessionSnapshot = StoreHub.session();
  @Local currentTab: number = 0;
  private tabsController: HdsTabsController = new HdsTabsController();
  private discoverTabIcon: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.square_grid_2x2'));
  private mineTabIcon: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.person'));
  private hostWindow: window.Window | undefined = undefined;

  aboutToAppear(): void {
    LikeService.get().onSession(this.session.loginInfo);
    this.syncMiniPlayerVisible();
    this.navStack.setInterception({
      didShow: (_from: NavDestinationContext | NavBar, to: NavDestinationContext | NavBar,
        _operation: NavigationOperation, _isAnimated: boolean) => {
        this.chrome.setTabBarVisible(to === 'navBar');
      }
    });
    this.bindAvoidArea();
  }

  aboutToDisappear(): void {
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

  @Monitor('player.currentSong', 'player.fullPlayerOpen')
  onPlayerChrome(_mon: IMonitor): void {
    this.syncMiniPlayerVisible();
  }

  private syncMiniPlayerVisible(): void {
    this.chrome.setMiniPlayerVisible(this.player.currentSong !== null && !this.player.fullPlayerOpen);
  }

  private bindAvoidArea(): void {
    const host: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    window.getLastWindow(host).then((win: window.Window) => {
      this.hostWindow = win;
      const avoid: window.AvoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      this.chrome.setSafeBottom(this.getUIContext().px2vp(avoid.bottomRect.height));
      win.on('avoidAreaChange', (data: window.AvoidAreaOptions) => {
        if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
          this.chrome.setSafeBottom(this.getUIContext().px2vp(data.area.bottomRect.height));
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
    } else if (name === RouteName.PLAYER) {
      PlayerPage({ navPathStack: this.navStack })
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Navigation(this.navStack) {
        HdsTabs({ controller: this.tabsController, index: this.currentTab }) {
          TabContent() {
            DiscoverPage()
          }
          .tabBar(new BottomTabBarStyle({ normal: this.discoverTabIcon }, '发现'))

          TabContent() {
            MinePage()
          }
          .tabBar(new BottomTabBarStyle({ normal: this.mineTabIcon }, '我的'))
        }
        .barPosition(BarPosition.End)
        .vertical(false)
        .barOverlap(true)
        .barFloatingStyle({
          barBottomMargin: this.chrome.safeBottom,
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.IMMERSIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        })
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
      .height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.BOTTOM])

      if (!this.player.fullPlayerOpen && this.player.currentSong !== null) {
        Column() {
          MiniPlayer({ navPathStack: this.navStack })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ bottom: this.chrome.liftBelowPlayer })
        .hitTestBehavior(HitTestMode.Transparent)
        .transition(TransitionEffect.OPACITY
          .combine(TransitionEffect.translate({ y: 24 }))
          .animation({ duration: 200, curve: Curve.EaseOut }))
        .animation({ curve: curves.springMotion() })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BG)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.BOTTOM])
  }
}
