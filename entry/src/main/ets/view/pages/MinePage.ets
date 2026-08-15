/**
 * 我的页
 * 与发现页同一套顶栏 + 滚动卡片：用户卡、创建/收藏歌单；未登录时展示登录面板
 */
import { LoginPanel } from '../components/LoginPanel';
import { PlaylistRow } from '../components/PlaylistRow';
import { MineViewModel } from '../../viewmodel/MineViewModel';
import { StoreHub } from '../../store/StoreHub';
import { SessionSnapshot } from '../../store/SessionSnapshot';
import { SongListInfo } from '../../model/entity/models';
import { RouteName } from '../../common/router/RouteName';
import { PlaylistRouteParam } from '../../common/router/RouteParams';
import { ChromeInsets } from '../../common/utils/ChromeInsets';
import {
  ACCENT_COLOR, ACCENT_SOFT, CARD_BG, PAGE_BG, PAGE_PAD, RADIUS_L, SPACE_L, SPACE_M, SPACE_S,
  TEXT_PRIMARY, TEXT_SECONDARY
} from '../../common/utils/format';

@ComponentV2
export struct MinePage {
  @Consumer('navStack') navStack: NavPathStack = new NavPathStack();
  @Consumer('chromeInsets') chrome: ChromeInsets = new ChromeInsets();
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

  private userSubtitle(): string {
    return `创建 ${this.vm.myPlaylists.length} · 收藏 ${this.vm.favPlaylists.length}`;
  }

  @Builder
  TopBar() {
    Row() {
      Text('我的')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_PRIMARY)
        .layoutWeight(1)
      SymbolGlyph($r('sys.symbol.gearshape'))
        .fontSize(22)
        .fontColor([TEXT_SECONDARY])
        .width(40)
        .height(40)
        .onClick(() => {
          this.openSettings();
        })
    }
    .width('100%')
    .height(40)
    .padding({ left: PAGE_PAD, right: PAGE_PAD })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  UserCard() {
    Row() {
      Image(this.session.loginInfo!.avatarUrl)
        .width(56)
        .height(56)
        .borderRadius(28)
        .objectFit(ImageFit.Cover)
      Column() {
        Row() {
          Text(this.session.loginInfo!.nickname)
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor(TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          if (this.session.loginInfo!.vipType > 0) {
            Text('VIP')
              .fontSize(10)
              .fontWeight(FontWeight.Medium)
              .fontColor(ACCENT_COLOR)
              .backgroundColor(ACCENT_SOFT)
              .borderRadius(8)
              .padding({ left: 6, right: 6, top: 1, bottom: 1 })
              .margin({ left: SPACE_S })
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        Text(this.userSubtitle())
          .fontSize(12)
          .fontColor(TEXT_SECONDARY)
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: SPACE_M })
    }
    .width('100%')
    .padding(SPACE_L)
    .alignItems(VerticalAlign.Center)
    .backgroundColor(CARD_BG)
    .borderRadius(RADIUS_L)
    .shadow({ radius: 12, color: '#33000000', offsetY: 2 })
  }

  @Builder
  StatusCard() {
    Column() {
      if (this.vm.playlistsLoading) {
        LoadingProgress().width(40).height(40).color(TEXT_SECONDARY)
      } else {
        Text(this.vm.playlistsError)
          .fontSize(14)
          .fontColor(TEXT_SECONDARY)
        Button('重试')
          .type(ButtonType.Capsule)
          .controlSize(ControlSize.SMALL)
          .margin({ top: SPACE_M })
          .onClick(() => {
            this.vm.retry();
          })
      }
    }
    .width('100%')
    .height(220)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(CARD_BG)
    .borderRadius(RADIUS_L)
    .shadow({ radius: 12, color: '#33000000', offsetY: 2 })
  }

  @Builder
  EmptyPlaylistsCard() {
    Row() {
      SymbolGlyph($r('sys.symbol.music_note_list'))
        .fontSize(24)
        .fontColor([ACCENT_COLOR])
      Column() {
        Text('还没有歌单')
          .fontSize(15)
          .fontColor(TEXT_PRIMARY)
        Text('创建或收藏后会显示在这里')
          .fontSize(12)
          .fontColor(TEXT_SECONDARY)
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: SPACE_M })
    }
    .width('100%')
    .padding(SPACE_L)
    .backgroundColor(CARD_BG)
    .borderRadius(RADIUS_L)
    .shadow({ radius: 12, color: '#33000000', offsetY: 2 })
  }

  @Builder
  CreatedSection() {
    Column() {
      Text(`我创建的歌单 · ${this.vm.myPlaylists.length}`)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_PRIMARY)
        .width('100%')
        .padding({ left: PAGE_PAD, right: PAGE_PAD, top: SPACE_L, bottom: SPACE_S })
      ForEach(this.vm.myPlaylists, (pl: SongListInfo) => {
        PlaylistRow({
          list: pl,
          showAuthor: false,
          onOpen: (listId: number) => {
            this.openList(listId);
          }
        })
      }, (pl: SongListInfo) => `c-${pl.id.toString()}`)
    }
    .width('100%')
    .backgroundColor(CARD_BG)
    .borderRadius(RADIUS_L)
    .clip(true)
    .shadow({ radius: 12, color: '#33000000', offsetY: 2 })
  }

  @Builder
  FavSection() {
    Column() {
      Text(`我收藏的歌单 · ${this.vm.favPlaylists.length}`)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(TEXT_PRIMARY)
        .width('100%')
        .padding({ left: PAGE_PAD, right: PAGE_PAD, top: SPACE_L, bottom: SPACE_S })
      ForEach(this.vm.favPlaylists, (pl: SongListInfo) => {
        PlaylistRow({
          list: pl,
          showAuthor: true,
          onOpen: (listId: number) => {
            this.openList(listId);
          }
        })
      }, (pl: SongListInfo) => `f-${pl.id.toString()}`)
    }
    .width('100%')
    .backgroundColor(CARD_BG)
    .borderRadius(RADIUS_L)
    .clip(true)
    .shadow({ radius: 12, color: '#33000000', offsetY: 2 })
  }

  @Builder
  HomeScroll() {
    Scroll() {
      Column({ space: SPACE_M }) {
        this.UserCard()
        if (this.vm.playlistsLoading || this.vm.playlistsError.length > 0) {
          this.StatusCard()
        } else if (this.vm.myPlaylists.length === 0 && this.vm.favPlaylists.length === 0) {
          this.EmptyPlaylistsCard()
        } else {
          if (this.vm.myPlaylists.length > 0) {
            this.CreatedSection()
          }
          if (this.vm.favPlaylists.length > 0) {
            this.FavSection()
          }
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: PAGE_PAD, right: PAGE_PAD, bottom: SPACE_M + this.chrome.listEndOffset })
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.Top)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
  }

  build() {
    Column({ space: SPACE_M }) {
      this.TopBar()
      if (this.isLoggedIn()) {
        this.HomeScroll()
      } else {
        LoginPanel()
      }
    }
    .width('100%')
    .height('100%')
    .padding({ top: SPACE_M })
    .backgroundColor(PAGE_BG)
  }
}
