/**
 * 发现页
 * 顶栏搜索 + 每日推荐沉浸卡（封面模糊头图底部播放/查看全部 + 预览歌曲）
 */
import { SongInfo } from '../../model/entity/models';
import { DailySongsViewModel } from '../../viewmodel/DailySongsViewModel';
import { SearchViewModel } from '../../viewmodel/SearchViewModel';
import { StoreHub } from '../../store/StoreHub';
import { SessionSnapshot } from '../../store/SessionSnapshot';
import { RouteName } from '../../common/router/RouteName';
import { ChromeInsets } from '../../common/utils/ChromeInsets';
import { SongRow } from '../components/SongRow';
import { SearchResultPanel } from '../components/SearchResultPanel';
import {
  ACCENT_COLOR, CARD_BG, ON_ACCENT, PAGE_BG, PAGE_PAD, RADIUS_L, SPACE_L, SPACE_M,
  SPACE_S, TEXT_PRIMARY, TEXT_SECONDARY
} from '../../common/utils/format';

@ComponentV2
export struct DiscoverPage {
  @Consumer('navStack') navStack: NavPathStack = new NavPathStack();
  @Consumer('chromeInsets') chrome: ChromeInsets = new ChromeInsets();
  @Local dailyVm: DailySongsViewModel = new DailySongsViewModel();
  @Local searchVm: SearchViewModel = new SearchViewModel();
  @Local session: SessionSnapshot = StoreHub.session();
  @Local todayDay: string = new Date().getDate().toString();

  aboutToAppear(): void {
    this.loadDailyIfLoggedIn();
  }

  @Monitor('dailyVm.toastMessage')
  onDailyToast(_mon: IMonitor): void {
    if (this.dailyVm.toastMessage.length > 0) {
      this.getUIContext().getPromptAction().showToast({ message: this.dailyVm.toastMessage });
      this.dailyVm.toastMessage = '';
    }
  }

  @Monitor('searchVm.toastMessage')
  onSearchToast(_mon: IMonitor): void {
    if (this.searchVm.toastMessage.length > 0) {
      this.getUIContext().getPromptAction().showToast({ message: this.searchVm.toastMessage });
      this.searchVm.toastMessage = '';
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

  private openDailySongs(): void {
    this.navStack.pushPath({ name: RouteName.DAILY_SONGS });
  }

  private heroSubtitle(): string {
    if (this.dailyVm.songs.length === 0) {
      return '根据你的音乐口味每日更新';
    }
    return `今日推荐 · ${this.dailyVm.songs.length} 首`;
  }

  private weekday(): string {
    const names: string[] = ['日', '一', '二', '三', '四', '五', '六'];
    return `周${names[new Date().getDay()]}`;
  }

  private heroCover(): string {
    if (this.dailyVm.previewSongs.length === 0) {
      return '';
    }
    const url: string = this.dailyVm.previewSongs[0].picUrl;
    if (url.length === 0) {
      return '';
    }
    return `${url}?param=300y300`;
  }

  @Builder
  DailyHeroHeader() {
    Stack() {
      if (this.heroCover().length > 0) {
        // 首曲封面强模糊打底，放大消除模糊边缘溢出
        Image(this.heroCover())
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .blur(30)
          .scale({ x: 1.2, y: 1.2 })
      } else {
        // 无封面时降级为主色渐变底
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            direction: GradientDirection.RightBottom,
            colors: [[ACCENT_COLOR, 0.0], ['#B32626', 1.0]]
          })
      }

      // 深色渐变蒙版，保证深浅色主题下白字均可读
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [['#33000000', 0.0], ['#B3000000', 1.0]]
        })

      Column() {
        Column() {
          Text(this.todayDay)
            .fontSize(34)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Text(this.weekday())
            .fontSize(12)
            .fontColor('#B3FFFFFF')
            .margin({ top: 2 })

          Blank()

          Text('每日推荐')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
          Text(this.heroSubtitle())
            .fontSize(12)
            .fontColor('#B3FFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
        }
        .width('100%')
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .onClick(() => {
          this.openDailySongs();
        })

        if (this.dailyVm.songs.length > 0) {
          Row({ space: SPACE_S }) {
            Button({ type: ButtonType.Capsule }) {
              Row() {
                SymbolGlyph($r('sys.symbol.play_fill'))
                  .fontSize(14)
                  .fontColor([ON_ACCENT])
                Text('播放全部')
                  .fontSize(13)
                  .fontColor(ON_ACCENT)
                  .margin({ left: 4 })
              }
              .alignItems(VerticalAlign.Center)
            }
            .layoutWeight(1)
            .height(36)
            .padding({ left: SPACE_L, right: SPACE_L })
            .backgroundColor(ACCENT_COLOR)
            .onClick(() => {
              this.dailyVm.playAll();
            })

            Button({ type: ButtonType.Capsule }) {
              Row() {
                Text(`查看全部 · ${this.dailyVm.songs.length} 首`)
                  .fontSize(13)
                  .fontColor(Color.White)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize(12)
                  .fontColor([Color.White])
                  .margin({ left: 2 })
              }
              .alignItems(VerticalAlign.Center)
            }
            .layoutWeight(1)
            .height(36)
            .padding({ left: SPACE_L, right: SPACE_L })
            .backgroundColor('#33FFFFFF')
            .backgroundBlurStyle(BlurStyle.Regular)
            .onClick(() => {
              this.openDailySongs();
            })
          }
          .width('100%')
          .margin({ top: SPACE_M })
        }
      }
      .width('100%')
      .height('100%')
      .padding(SPACE_L)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(200)
    .clip(true)
  }

  @Builder
  DailyRecommendCard() {
    Column() {
      this.DailyHeroHeader()

      if (this.dailyVm.previewSongs.length > 0) {
        Column() {
          ForEach(this.dailyVm.previewSongs, (song: SongInfo, songIndex: number) => {
            SongRow({
              song: song,
              songIndex: songIndex,
              onTap: (idx: number) => {
                this.dailyVm.playAt(idx);
              }
            })
          }, (song: SongInfo) => song.id.toString())
        }
        .width('100%')
      }
    }
    .width('100%')
    .backgroundColor(CARD_BG)
    .borderRadius(RADIUS_L)
    .clip(true)
    .shadow({ radius: 12, color: '#33000000', offsetY: 2 })
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
      this.DailyRecommendCard()
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
  }

  build() {
    Column({ space: SPACE_M }) {
      Column() {
        Search({ value: this.searchVm.keyword, placeholder: '搜索歌曲、歌单、专辑' })
          .placeholderColor(TEXT_SECONDARY)
          .fontColor(TEXT_PRIMARY)
          .backgroundColor(CARD_BG)
          .height(40)
          .width('100%')
          .cancelButton({ style: CancelButtonStyle.INPUT })
          .onChange((value: string) => {
            this.searchVm.onKeywordChange(value);
          })
          .onSubmit((value: string) => {
            this.searchVm.doSearch(value);
          })
      }
      .width('100%')
      .padding({ left: PAGE_PAD, right: PAGE_PAD })

      if (this.searchVm.loading) {
        Column() {
          LoadingProgress().width(40).height(40).color(TEXT_SECONDARY)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      } else if (this.searchVm.searched) {
        SearchResultPanel({ vm: this.searchVm })
      } else {
        Scroll() {
          Column() {
            if (this.isLoggedIn()) {
              this.DailyHeroArea()
            } else {
              this.LoginGuideCard()
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({ left: PAGE_PAD, right: PAGE_PAD, bottom: this.chrome.listEndOffset })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      }
    }
    .width('100%')
    .height('100%')
    .padding({ top: SPACE_M + this.chrome.safeTop })
    .backgroundColor(PAGE_BG)
  }
}
