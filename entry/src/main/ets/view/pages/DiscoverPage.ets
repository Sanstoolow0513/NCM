/**
 * 发现页
 * Banner 轮播 + 每日推荐 Hero 卡 + 热门歌单网格，作为应用首页内容
 */
import { BannerInfo, SongInfo, SongListInfo } from '../../model/entity/models';
import { DiscoverViewModel } from '../../viewmodel/DiscoverViewModel';
import { DailySongsViewModel } from '../../viewmodel/DailySongsViewModel';
import { StoreHub } from '../../store/StoreHub';
import { SessionSnapshot } from '../../store/SessionSnapshot';
import { RouteName } from '../../common/router/RouteName';
import { PlaylistRouteParam } from '../../common/router/RouteParams';
import {
  ACCENT_COLOR, CARD_BG, COVER_PLACEHOLDER, ON_ACCENT, PAGE_BG, PAGE_PAD, RADIUS_L, RADIUS_M, RADIUS_XL, SPACE_L,
  SPACE_M, SPACE_S, TEXT_PRIMARY, TEXT_SECONDARY
} from '../../common/utils/format';@ComponentV2
export struct DiscoverPage {
  @Consumer('navStack') navStack: NavPathStack = new NavPathStack();
  @Local vm: DiscoverViewModel = new DiscoverViewModel();
  @Local dailyVm: DailySongsViewModel = new DailySongsViewModel();
  @Local session: SessionSnapshot = StoreHub.session();
  @Local todayDay: string = new Date().getDate().toString();
  @Local heroIndex: number = 0;

  aboutToAppear(): void {
    this.vm.load();
    this.loadDailyIfLoggedIn();
  }

  @Monitor('dailyVm.toastMessage')
  onDailyToast(_mon: IMonitor): void {
    if (this.dailyVm.toastMessage.length > 0) {
      this.getUIContext().getPromptAction().showToast({ message: this.dailyVm.toastMessage });
      this.dailyVm.toastMessage = '';
    }
  }

  @Monitor('dailyVm.loading')
  onDailyLoading(_mon: IMonitor): void {
    if (!this.dailyVm.loading) {
      this.heroIndex = 0;
    }
  }

  @Monitor('session.loginInfo')
  onLoginChange(_mon: IMonitor): void {
    this.loadDailyIfLoggedIn();
  }

  private isLoggedIn(): boolean {
    return this.session.loginInfo !== null && this.session.loginInfo.uid > 0;
  }

  private loadDailyIfLoggedIn(): void {
    if (this.isLoggedIn()) {
      this.dailyVm.load();
    }
  }

  private openPlaylist(listId: number): void {
    const param: PlaylistRouteParam = { listId: listId, isAlbum: false };
    this.navStack.pushPath({ name: RouteName.PLAYLIST_DETAIL, param: param });
  }

  private openDailySongs(): void {
    this.navStack.pushPath({ name: RouteName.DAILY_SONGS });
  }

  private heroCoverSrc(song: SongInfo): string {
    if (song.picUrl.length > 0) {
      return `${song.picUrl}?param=500y500`;
    }
    return '';
  }

  private heroSongLabel(): string {
    if (this.dailyVm.heroSongs.length === 0) {
      return '根据你的音乐口味每日更新';
    }
    const idx: number = this.heroIndex < this.dailyVm.heroSongs.length ? this.heroIndex : 0;
    const song: SongInfo = this.dailyVm.heroSongs[idx];
    return `${song.name} · ${song.singer}`;
  }

  @Builder
  DailyHeroCard() {
    Stack({ alignContent: Alignment.BottomStart }) {
      if (this.dailyVm.heroSongs.length > 0) {
        Swiper() {
          ForEach(this.dailyVm.heroSongs, (song: SongInfo, songIndex: number) => {
            Image(this.heroCoverSrc(song))
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)
              .onClick(() => {
                this.dailyVm.playAt(songIndex);
              })
          }, (song: SongInfo) => song.id.toString())
        }
        .autoPlay(this.dailyVm.heroSongs.length > 1)
        .interval(4000)
        .loop(this.dailyVm.heroSongs.length > 1)
        .indicator(false)
        .onChange((index: number) => {
          this.heroIndex = index;
        })
        .width('100%')
        .height('100%')
      } else {
        Column() {
        }
        .width('100%')
        .height('100%')
        .backgroundColor(ACCENT_COLOR)
      }

      // 底部毛玻璃信息条
      Row() {
        Column() {
          Text(this.todayDay)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Text('日')
            .fontSize(11)
            .fontColor(Color.White)
            .margin({ top: 1 })
        }
        .width(48)
        .height(48)
        .borderRadius(14)
        .backgroundColor(ACCENT_COLOR)
        .justifyContent(FlexAlign.Center)

        Column() {
          Text('每日推荐')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
          Text(this.heroSongLabel())
            .fontSize(12)
            .fontColor(Color.White)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: SPACE_M, right: SPACE_M })

        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.play_fill'))
            .fontSize(20)
            .fontColor([ON_ACCENT])
        }
        .width(48)
        .height(48)
        .backgroundColor(ACCENT_COLOR)
        .onClick(() => {
          this.dailyVm.playAll();
        })
      }
      .width('100%')
      .padding(SPACE_L)
      .backgroundColor('#33000000')
      .backgroundBlurStyle(BlurStyle.Regular)
    }
    .width('100%')
    .height(220)
    .borderRadius(RADIUS_XL)
    .clip(true)
    .backgroundColor(COVER_PLACEHOLDER)
    .margin({ left: PAGE_PAD, right: PAGE_PAD, top: SPACE_M })
  }

  @Builder
  DailyHeroArea() {
    if (this.dailyVm.loading) {
      Column() {
        LoadingProgress().width(40).height(40).color(TEXT_SECONDARY)
      }
      .width('100%')
      .height(220)
      .justifyContent(FlexAlign.Center)
      .margin({ top: SPACE_M })
    } else if (this.dailyVm.error.length > 0) {
      Column() {
        Text(this.dailyVm.error)
          .fontSize(14)
          .fontColor(TEXT_SECONDARY)
        Button('重试')
          .type(ButtonType.Capsule)
          .controlSize(ControlSize.SMALL)
          .margin({ top: SPACE_M })
          .onClick(() => {
            this.dailyVm.load();
          })
      }
      .width('100%')
      .height(220)
      .justifyContent(FlexAlign.Center)
    } else {
      Column() {
        this.DailyHeroCard()
        if (this.dailyVm.songs.length > 0) {
          Row() {
            Text(`今日推荐 · ${this.dailyVm.songs.length} 首`)
              .fontSize(13)
              .fontColor(TEXT_SECONDARY)
              .layoutWeight(1)
            Text('查看全部')
              .fontSize(13)
              .fontColor(ACCENT_COLOR)
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(12)
              .fontColor([ACCENT_COLOR])
              .margin({ left: 2 })
          }
          .width('100%')
          .padding({ left: 20, right: PAGE_PAD, top: SPACE_M })
          .onClick(() => {
            this.openDailySongs();
          })
        }
      }
      .width('100%')
    }
  }

  @Builder
  LoginGuideCard() {
    Row() {
      SymbolGlyph($r('sys.symbol.calendar'))
        .fontSize(24)
        .fontColor([ACCENT_COLOR])
      Column() {
        Text('登录后查看每日推荐')
          .fontSize(15)
          .fontColor(TEXT_PRIMARY)
        Text('前往「我的」完成登录')
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
    .margin({ left: PAGE_PAD, right: PAGE_PAD, top: SPACE_M })
  }

  @Builder
  BannerArea() {
    if (this.vm.banners.length > 0) {
      Swiper() {
        ForEach(this.vm.banners, (b: BannerInfo) => {
          Image(b.pic)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
            .borderRadius(RADIUS_L)
        }, (b: BannerInfo) => `${b.targetType}-${b.targetId}`)
      }
      .autoPlay(true)
      .interval(4000)
      .loop(true)
      .indicator(
        new DotIndicator()
          .itemWidth(6)
          .itemHeight(6)
          .selectedItemWidth(16)
          .selectedItemHeight(6)
          .color('#66FFFFFF')
          .selectedColor(Color.White)
      )
      .height(150)
      .padding({ left: PAGE_PAD, right: PAGE_PAD, top: SPACE_M })
    }
  }

  build() {
    Column() {
      Text('发现')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(TEXT_PRIMARY)
        .width('100%')
        .padding({ left: PAGE_PAD, top: SPACE_M, bottom: SPACE_S })

      if (this.vm.loading) {
        Column() {
          LoadingProgress().width(40).height(40).color(TEXT_SECONDARY)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      } else if (this.vm.error.length > 0) {
        Column() {
          Text(this.vm.error).fontColor(TEXT_SECONDARY).fontSize(14)
          Button('重试')
            .type(ButtonType.Capsule)
            .controlSize(ControlSize.SMALL)
            .margin({ top: SPACE_M })
            .onClick(() => {
              this.vm.load();
            })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      } else {
        Scroll() {
          Column() {
            this.BannerArea()

            if (this.isLoggedIn()) {
              this.DailyHeroArea()
            } else {
              this.LoginGuideCard()
            }

            Text('热门歌单')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor(TEXT_PRIMARY)
              .width('100%')
              .padding({ left: PAGE_PAD, top: 18, bottom: SPACE_S })

            Grid() {
              ForEach(this.vm.playlists, (pl: SongListInfo) => {
                GridItem() {
                  Column() {
                    Image(`${pl.coverImgUrl}?param=300y300`)
                      .width('100%')
                      .aspectRatio(1)
                      .borderRadius(RADIUS_M)
                      .backgroundColor(COVER_PLACEHOLDER)
                    Text(pl.name)
                      .fontSize(12)
                      .fontColor(TEXT_PRIMARY)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ top: 4 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .onClick(() => {
                    this.openPlaylist(pl.id);
                  })
                }
              }, (pl: SongListInfo) => pl.id.toString())
            }
            .columnsTemplate('1fr 1fr 1fr')
            .columnsGap(10)
            .rowsGap(10)
            .padding({ left: PAGE_PAD, right: PAGE_PAD, bottom: 140 })
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BG)
  }
}
