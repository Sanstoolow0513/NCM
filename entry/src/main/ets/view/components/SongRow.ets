/**
 * 歌曲行组件
 * 封面 + 歌名/歌手·专辑·时长，右侧下一首与红心；正在播放的歌曲歌名高亮为主色
 */
import { SongInfo } from '../../model/entity/models';
import { PlayerService } from '../../service/player/PlayerService';
import { LikeService } from '../../service/like/LikeService';
import { StoreHub } from '../../store/StoreHub';
import { PlayerSnapshot } from '../../store/PlayerSnapshot';
import { LikeSnapshot } from '../../store/LikeSnapshot';
import {
  ACCENT_COLOR, COVER_PLACEHOLDER, formatDuration, PAGE_PAD, RADIUS_S, TEXT_PRIMARY, TEXT_SECONDARY
} from '../../common/utils/format';

@ComponentV2
export struct SongRow {
  @Param song: SongInfo = new SongInfo();
  @Param songIndex: number = 0;
  @Event onTap: (songIndex: number) => void = (_songIndex: number) => {
  };
  @Local player: PlayerSnapshot = StoreHub.player();
  @Local likes: LikeSnapshot = StoreHub.likes();

  private isPlayingThis(): boolean {
    return this.player.currentSong !== null && this.player.currentSong.id === this.song.id && this.song.id !== 0;
  }

  private isLiked(): boolean {
    return this.likes.revision >= 0 && this.likes.has(this.song.id);
  }

  private coverSrc(): string {
    if (this.song.picUrl.length > 0) {
      return `${this.song.picUrl}?param=96y96`;
    }
    return '';
  }

  private subtitle(): string {
    return `${this.song.singer} · ${this.song.album} · ${formatDuration(this.song.duration)}`;
  }

  build() {
    Row() {
      Image(this.coverSrc())
        .width(48)
        .height(48)
        .borderRadius(RADIUS_S)
        .objectFit(ImageFit.Cover)
        .backgroundColor(COVER_PLACEHOLDER)
        .onClick(() => {
          this.onTap(this.songIndex);
        })
      Column() {
        Text(this.song.name)
          .fontSize(15)
          .fontColor(this.isPlayingThis() ? ACCENT_COLOR : TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(this.subtitle())
          .fontSize(12)
          .fontColor(TEXT_SECONDARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 10, right: 8 })
      .onClick(() => {
        this.onTap(this.songIndex);
      })

      SymbolGlyph($r('sys.symbol.plus'))
        .fontSize(20)
        .fontColor([TEXT_SECONDARY])
        .width(36)
        .height(36)
        .onClick(() => {
          PlayerService.get().insertNext(this.song);
        })

      SymbolGlyph(this.isLiked() ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart'))
        .fontSize(20)
        .fontColor([this.isLiked() ? ACCENT_COLOR : TEXT_SECONDARY])
        .width(36)
        .height(36)
        .onClick(() => {
          LikeService.get().toggle(this.song.id);
        })
    }
    .width('100%')
    .padding({ left: PAGE_PAD, right: PAGE_PAD, top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Center)
  }
}
