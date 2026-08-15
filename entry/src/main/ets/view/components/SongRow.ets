/**
 * 歌曲行组件
 * 封面缩略图 + 歌名/歌手 + 时长，正在播放的歌曲歌名高亮为主色
 */
import { SongInfo } from '../../model/entity/models';
import { PlayerService } from '../../service/player/PlayerService';
import { StoreHub } from '../../store/StoreHub';
import { PlayerSnapshot } from '../../store/PlayerSnapshot';
import {
  ACCENT_COLOR, COVER_PLACEHOLDER, formatDuration, PAGE_PAD, RADIUS_S, TEXT_PRIMARY, TEXT_SECONDARY
} from '../../common/utils/format';

@ComponentV2
export struct SongRow {
  @Param song: SongInfo = new SongInfo();
  @Param songIndex: number = 0;
  @Param showIndex: boolean = false;
  @Event onTap: (songIndex: number) => void = (_songIndex: number) => {
  };
  @Local player: PlayerSnapshot = StoreHub.player();

  private isPlayingThis(): boolean {
    return this.player.currentSong !== null && this.player.currentSong.id === this.song.id && this.song.id !== 0;
  }

  private coverSrc(): string {
    if (this.song.picUrl.length > 0) {
      return `${this.song.picUrl}?param=96y96`;
    }
    return '';
  }

  build() {
    Row() {
      Row() {
        if (this.showIndex) {
          Text((this.songIndex + 1).toString())
            .fontSize(14)
            .fontColor(TEXT_SECONDARY)
            .width(30)
        }
        Image(this.coverSrc())
          .width(48)
          .height(48)
          .borderRadius(RADIUS_S)
          .objectFit(ImageFit.Cover)
          .backgroundColor(COVER_PLACEHOLDER)
        Column() {
          Text(this.song.name)
            .fontSize(15)
            .fontColor(this.isPlayingThis() ? ACCENT_COLOR : TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(`${this.song.singer} - ${this.song.album}`)
            .fontSize(12)
            .fontColor(TEXT_SECONDARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10, right: 8 })

        Text(formatDuration(this.song.duration))
          .fontSize(12)
          .fontColor(TEXT_SECONDARY)
      }
      .layoutWeight(1)
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.onTap(this.songIndex);
      })

      SymbolGlyph($r('sys.symbol.ellipsis_circle'))
        .fontSize(20)
        .fontColor([TEXT_SECONDARY])
        .width(32)
        .height(32)
        .margin({ left: 4 })
        .bindMenu([
          {
            value: '下一首播放',
            action: () => {
              PlayerService.get().insertNext(this.song);
            }
          },
          {
            value: '添加到播放列表',
            action: () => {
              PlayerService.get().append(this.song);
            }
          }
        ])
    }
    .width('100%')
    .padding({ left: PAGE_PAD, right: PAGE_PAD, top: 8, bottom: 8 })
  }
}
