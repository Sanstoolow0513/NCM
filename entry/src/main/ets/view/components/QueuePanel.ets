/**
 * 当前播放队列半模态面板
 * 切歌 / 移除单曲 / 清空队列
 */
import { SongInfo } from '../../model/entity/models';
import { QueuePanelViewModel } from '../../viewmodel/QueuePanelViewModel';
import {
  ACCENT_COLOR, COVER_PLACEHOLDER, PAGE_PAD, RADIUS_S, SPACE_M, SPACE_S, TEXT_PRIMARY, TEXT_SECONDARY
} from '../../common/utils/format';

@ComponentV2
export struct QueuePanel {
  @Param bottomInset: number = 0;
  @Local vm: QueuePanelViewModel = new QueuePanelViewModel();

  private isCurrent(songIndex: number): boolean {
    return this.vm.isCurrent(songIndex);
  }

  private coverSrc(song: SongInfo): string {
    if (song.picUrl.length > 0) {
      return `${song.picUrl}?param=96y96`;
    }
    return '';
  }

  private confirmClear(): void {
    if (this.vm.queueSize() === 0) {
      return;
    }
    this.getUIContext().showAlertDialog({
      title: '清空播放列表',
      message: '确定清空当前播放列表吗？',
      buttons: [
        { value: '取消', action: () => {
        } },
        {
          value: '清空',
          action: () => {
            this.vm.clearQueue();
          }
        }
      ]
    });
  }

  build() {
    Column() {
      Row() {
        Text(`${this.vm.queueSize()} 首`)
          .fontSize(13)
          .fontColor(TEXT_SECONDARY)
          .layoutWeight(1)
        Text('清空')
          .fontSize(14)
          .fontColor(this.vm.queueSize() > 0 ? ACCENT_COLOR : TEXT_SECONDARY)
          .onClick(() => {
            this.confirmClear();
          })
      }
      .width('100%')
      .padding({ left: PAGE_PAD, right: PAGE_PAD, top: SPACE_S, bottom: SPACE_M })

      if (this.vm.queueSize() === 0) {
        Text('播放列表为空')
          .fontSize(14)
          .fontColor(TEXT_SECONDARY)
          .margin({ top: 48 })
          .width('100%')
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
      } else {
        List() {
          ForEach(this.vm.songs(), (song: SongInfo, songIndex: number) => {
            ListItem() {
              Row() {
                Row() {
                  Image(this.coverSrc(song))
                    .width(48)
                    .height(48)
                    .borderRadius(RADIUS_S)
                    .objectFit(ImageFit.Cover)
                    .backgroundColor(COVER_PLACEHOLDER)
                  Column() {
                    Text(song.name)
                      .fontSize(15)
                      .fontColor(this.isCurrent(songIndex) ? ACCENT_COLOR : TEXT_PRIMARY)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(`${song.singer} - ${song.album}`)
                      .fontSize(12)
                      .fontColor(TEXT_SECONDARY)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ top: 2 })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                  .margin({ left: 10, right: 8 })
                }
                .layoutWeight(1)
                .alignItems(VerticalAlign.Center)
                .onClick(() => {
                  this.vm.playAt(songIndex);
                })

                SymbolGlyph($r('sys.symbol.minus_circle'))
                  .fontSize(22)
                  .fontColor([TEXT_SECONDARY])
                  .onClick(() => {
                    this.vm.removeAt(songIndex);
                  })
              }
              .width('100%')
              .padding({ left: PAGE_PAD, right: PAGE_PAD, top: 8, bottom: 8 })
            }
          }, (song: SongInfo, songIndex: number) => `${song.id}-${songIndex}`)
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ bottom: this.bottomInset })
  }
}
