/**
 * 我的页
 * 用户信息卡 + 我的歌单货架 + 设置入口；未登录时展示登录面板
 */
import { LoginPanel } from '../components/LoginPanel';
import { PlaylistShelf } from '../components/PlaylistShelf';
import { MineViewModel } from '../../viewmodel/MineViewModel';
import { StoreHub } from '../../store/StoreHub';
import { SessionSnapshot } from '../../store/SessionSnapshot';
import { RouteName } from '../../common/router/RouteName';
import { PlaylistRouteParam } from '../../common/router/RouteParams';
import {
  ACCENT_COLOR, ACCENT_SOFT, PAGE_BG, PAGE_PAD, SPACE_L, SPACE_M, SPACE_S, TEXT_PRIMARY, TEXT_SECONDARY
} from '../../common/utils/format';

@ComponentV2
export struct MinePage {
  @Consumer('navStack') navStack: NavPathStack = new NavPathStack();
  @Local vm: MineViewModel = new MineViewModel();
  @Local session: SessionSnapshot = StoreHub.session();

  aboutToAppear(): void {
    this.vm.load();
  }

  @Monitor('session.loginInfo')
  onLoginChange(_mon: IMonitor): void {
    this.vm.onLoginChange(this.session.loginInfo);
  }

  private isLoggedIn(): boolean {
    return this.session.loginInfo !== null && this.session.loginInfo.uid > 0;
  }

  private openSettings(): void {
    this.navStack.pushPath({ name: RouteName.SETTINGS });
  }

  private openList(listId: number): void {
    const param: PlaylistRouteParam = { listId: listId, isAlbum: false };
    this.navStack.pushPath({ name: RouteName.PLAYLIST_DETAIL, param: param });
  }

  @Builder
  UserCard() {
    Row() {
      Image(this.session.loginInfo!.avatarUrl)
        .width(64)
        .height(64)
        .borderRadius(32)
      Column() {
        Row() {
          Text(this.session.loginInfo!.nickname)
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor(TEXT_PRIMARY)
          if (this.session.loginInfo!.vipType > 0) {
            Text('VIP')
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor(ACCENT_COLOR)
              .backgroundColor(ACCENT_SOFT)
              .borderRadius(10)
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .margin({ left: 8 })
          }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 14 })
    }
    .width('100%')
    .padding({ left: PAGE_PAD, right: PAGE_PAD, top: SPACE_S, bottom: SPACE_S })
  }

  @Builder
  PlaylistArea() {
    if (this.vm.playlistsLoading) {
      Column() {
        LoadingProgress().width(32).height(32).color(TEXT_SECONDARY)
      }
      .width('100%')
      .padding({ top: 24 })
    } else if (this.vm.playlistsError.length > 0) {
      Text(this.vm.playlistsError)
        .fontSize(13)
        .fontColor(TEXT_SECONDARY)
        .width('100%')
        .padding({ left: PAGE_PAD, top: SPACE_L })
        .onClick(() => {
          this.vm.retry();
        })
    } else {
      Column() {
        PlaylistShelf({
          title: '我创建的歌单',
          lists: this.vm.myPlaylists,
          showAuthor: false,
          onOpen: (listId: number) => {
            this.openList(listId);
          }
        })
        PlaylistShelf({
          title: '我收藏的歌单',
          lists: this.vm.favPlaylists,
          showAuthor: true,
          onOpen: (listId: number) => {
            this.openList(listId);
          }
        })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
  }

  build() {
    Column() {
      Row() {
        Text('我的')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(TEXT_PRIMARY)
          .layoutWeight(1)
        SymbolGlyph($r('sys.symbol.gearshape'))
          .fontSize(22)
          .fontColor([TEXT_SECONDARY])
          .padding(SPACE_S)
          .onClick(() => {
            this.openSettings();
          })
      }
      .width('100%')
      .padding({ left: PAGE_PAD, right: PAGE_PAD, top: SPACE_M, bottom: SPACE_S })

      if (this.isLoggedIn()) {
        Scroll() {
          Column() {
            this.UserCard()
            this.PlaylistArea()
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding({ bottom: 140 })
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
      } else {
        LoginPanel()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BG)
  }
}
