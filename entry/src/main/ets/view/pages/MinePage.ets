/**
 * 我的页
 * 紧凑用户行 + 纵向歌单列表 + 设置入口；未登录时展示登录面板
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
  ACCENT_COLOR, ACCENT_SOFT, DIVIDER_COLOR, PAGE_BG, PAGE_PAD, SPACE_L, SPACE_M, SPACE_S, TEXT_PRIMARY,
  TEXT_SECONDARY
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

  @Builder
  SettingsEntry() {
    SymbolGlyph($r('sys.symbol.gearshape'))
      .fontSize(20)
      .fontColor([TEXT_SECONDARY])
      .padding(SPACE_S)
      .onClick(() => {
        this.openSettings();
      })
  }

  @Builder
  UserCard() {
    Row() {
      Image(this.session.loginInfo!.avatarUrl)
        .width(40)
        .height(40)
        .borderRadius(20)
      Column() {
        Row() {
          Text(this.session.loginInfo!.nickname)
            .fontSize(16)
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
              .margin({ left: 6 })
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 10, right: 4 })
      this.SettingsEntry()
    }
    .width('100%')
    .padding({ left: PAGE_PAD, right: PAGE_PAD - SPACE_S, top: SPACE_M, bottom: SPACE_S })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  CreatedHeader() {
    Text(`我创建的歌单 (${this.vm.myPlaylists.length})`)
      .fontSize(17)
      .fontWeight(FontWeight.Medium)
      .fontColor(TEXT_PRIMARY)
      .width('100%')
      .padding({ left: PAGE_PAD, right: PAGE_PAD, top: 18, bottom: SPACE_S })
      .backgroundColor(PAGE_BG)
  }

  @Builder
  FavHeader() {
    Text(`我收藏的歌单 (${this.vm.favPlaylists.length})`)
      .fontSize(17)
      .fontWeight(FontWeight.Medium)
      .fontColor(TEXT_PRIMARY)
      .width('100%')
      .padding({ left: PAGE_PAD, right: PAGE_PAD, top: 18, bottom: SPACE_S })
      .backgroundColor(PAGE_BG)
  }

  build() {
    Column() {
      if (this.isLoggedIn()) {
        List() {
          ListItem() {
            this.UserCard()
          }

          if (this.vm.playlistsLoading) {
            ListItem() {
              Column() {
                LoadingProgress().width(32).height(32).color(TEXT_SECONDARY)
              }
              .width('100%')
              .padding({ top: 24 })
            }
          } else if (this.vm.playlistsError.length > 0) {
            ListItem() {
              Text(this.vm.playlistsError)
                .fontSize(13)
                .fontColor(TEXT_SECONDARY)
                .width('100%')
                .padding({ left: PAGE_PAD, top: SPACE_L })
                .onClick(() => {
                  this.vm.retry();
                })
            }
          } else {
            if (this.vm.myPlaylists.length > 0) {
              ListItemGroup({ header: this.CreatedHeader }) {
                ForEach(this.vm.myPlaylists, (pl: SongListInfo) => {
                  ListItem() {
                    PlaylistRow({
                      list: pl,
                      showAuthor: false,
                      onOpen: (listId: number) => {
                        this.openList(listId);
                      }
                    })
                  }
                }, (pl: SongListInfo) => `c-${pl.id.toString()}`)
              }
            }
            if (this.vm.favPlaylists.length > 0) {
              ListItemGroup({ header: this.FavHeader }) {
                ForEach(this.vm.favPlaylists, (pl: SongListInfo) => {
                  ListItem() {
                    PlaylistRow({
                      list: pl,
                      showAuthor: true,
                      onOpen: (listId: number) => {
                        this.openList(listId);
                      }
                    })
                  }
                }, (pl: SongListInfo) => `f-${pl.id.toString()}`)
              }
            }
          }
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        .divider({ strokeWidth: 0.5, color: DIVIDER_COLOR, startMargin: PAGE_PAD })
        .contentEndOffset(this.chrome.listEndOffset)
      } else {
        Row() {
          Blank()
          this.SettingsEntry()
        }
        .width('100%')
        .padding({ left: PAGE_PAD, right: PAGE_PAD - SPACE_S, top: SPACE_M })
        LoginPanel()
      }
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.chrome.safeTop })
    .backgroundColor(PAGE_BG)
  }
}
