import { HdsTabs, HdsTabsController, hdsMaterial } from '@kit.UIDesignKit';
import { SymbolGlyphModifier } from '@kit.ArkUI';
import { MiniPlayer } from '../view/components/MiniPlayer';
import { DailySongsPage } from '../view/pages/DailySongsPage';
import { DiscoverPage } from '../view/pages/DiscoverPage';
import { MinePage } from '../view/pages/MinePage';
import { PlayerPage } from '../view/pages/PlayerPage';
import { PlaylistDetailPage } from '../view/pages/PlaylistDetailPage';
import { SearchPage } from '../view/pages/SearchPage';
import { SettingsPage } from '../view/pages/SettingsPage';
import { StoreHub } from '../store/StoreHub';
import { PlayerSnapshot } from '../store/PlayerSnapshot';
import { RouteName } from '../common/router/RouteName';
import { PlaylistRouteParam } from '../common/router/RouteParams';
import { NAV_INDICATOR_PAD, PAGE_BG } from '../common/utils/format';

@Entry
@ComponentV2
struct Index {
  @Provider('navStack') navStack: NavPathStack = new NavPathStack();
  @Local player: PlayerSnapshot = StoreHub.player();
  @Local currentTab: number = 0;
  private tabsController: HdsTabsController = new HdsTabsController();
  private discoverTabIcon: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.square_grid_2x2'));
  private searchTabIcon: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.magnifyingglass'));
  private mineTabIcon: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.person'));

  @Monitor('player.toastSeq')
  onPlayerToast(_mon: IMonitor): void {
    if (this.player.toastMessage.length > 0) {
      this.getUIContext().getPromptAction().showToast({ message: this.player.toastMessage });
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
            SearchPage()
          }
          .tabBar(new BottomTabBarStyle({ normal: this.searchTabIcon }, '搜索'))

          TabContent() {
            MinePage()
          }
          .tabBar(new BottomTabBarStyle({ normal: this.mineTabIcon }, '我的'))
        }
        .barPosition(BarPosition.End)
        .vertical(false)
        .barOverlap(true)
        .barFloatingStyle({
          barBottomMargin: NAV_INDICATOR_PAD,
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
        MiniPlayer({ navPathStack: this.navStack })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BG)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.BOTTOM])
  }
}
