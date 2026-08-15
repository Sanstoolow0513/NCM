/**
 * 登录面板
 * 扫码 / 手机号（验证码或密码）两种登录方式，统一卡片化容器与胶囊按钮样式
 */
import { LoginViewModel } from '../../viewmodel/LoginViewModel';
import {
  ACCENT_COLOR, ACCENT_SOFT, CARD_BG, ON_ACCENT, PAGE_BG, RADIUS_M, RADIUS_XL, SPACE_L, SPACE_M, SPACE_S, SPACE_XL,
  TEXT_PRIMARY, TEXT_SECONDARY
} from '../../common/utils/format';

@ComponentV2
export struct LoginPanel {
  @Local vm: LoginViewModel = new LoginViewModel();

  aboutToDisappear(): void {
    this.vm.stop();
  }

  @Monitor('vm.toastMessage')
  onToast(_mon: IMonitor): void {
    if (this.vm.toastMessage.length > 0) {
      this.getUIContext().getPromptAction().showToast({ message: this.vm.toastMessage });
      this.vm.toastMessage = '';
    }
  }

  @Builder
  PrimaryButton(label: string, enabled: boolean, onTap: () => void) {
    Button(label)
      .type(ButtonType.Capsule)
      .fontSize(15)
      .fontColor(ON_ACCENT)
      .backgroundColor(ACCENT_COLOR)
      .width('100%')
      .height(44)
      .margin({ top: SPACE_XL })
      .enabled(enabled)
      .onClick(onTap)
  }

  @Builder
  SecondaryButton(label: string, onTap: () => void) {
    Button(label)
      .type(ButtonType.Capsule)
      .fontSize(15)
      .fontColor(TEXT_PRIMARY)
      .backgroundColor(PAGE_BG)
      .width('100%')
      .height(44)
      .margin({ top: SPACE_M })
      .onClick(onTap)
  }

  @Builder
  QrContent() {
    if (this.vm.qrKey.length > 0) {
      QRCode(`https://music.163.com/login?codekey=${this.vm.qrKey}`)
        .width(200)
        .height(200)
        .color(Color.Black)
        .padding(SPACE_S)
        .backgroundColor(Color.White)
        .borderRadius(RADIUS_M)
    } else {
      LoadingProgress().width(48).height(48).color(TEXT_SECONDARY)
    }
    Text(this.vm.qrStatus)
      .fontSize(14)
      .fontColor(TEXT_SECONDARY)
      .margin({ top: SPACE_L })
    this.SecondaryButton('返回', () => {
      this.vm.backToMenu();
    })
  }

  @Builder
  PhoneContent() {
    TextInput({ placeholder: '手机号', text: this.vm.phone })
      .type(InputType.PhoneNumber)
      .maxLength(11)
      .fontColor(TEXT_PRIMARY)
      .placeholderColor(TEXT_SECONDARY)
      .backgroundColor(PAGE_BG)
      .height(48)
      .borderRadius(RADIUS_M)
      .width('100%')
      .onChange((value: string) => {
        this.vm.phone = value;
      })

    Row() {
      Text('验证码登录')
        .fontSize(14)
        .fontColor(this.vm.phoneWay === 0 ? ACCENT_COLOR : TEXT_SECONDARY)
        .backgroundColor(this.vm.phoneWay === 0 ? ACCENT_SOFT : PAGE_BG)
        .borderRadius(16)
        .padding({ left: 20, right: 20, top: 8, bottom: 8 })
        .onClick(() => {
          this.vm.phoneWay = 0;
        })
      Text('密码登录')
        .fontSize(14)
        .fontColor(this.vm.phoneWay === 1 ? ACCENT_COLOR : TEXT_SECONDARY)
        .backgroundColor(this.vm.phoneWay === 1 ? ACCENT_SOFT : PAGE_BG)
        .borderRadius(16)
        .padding({ left: 20, right: 20, top: 8, bottom: 8 })
        .margin({ left: SPACE_M })
        .onClick(() => {
          this.vm.phoneWay = 1;
        })
    }
    .margin({ top: SPACE_L })

    if (this.vm.phoneWay === 0) {
      Row() {
        TextInput({ placeholder: '短信验证码', text: this.vm.captcha })
          .type(InputType.Number)
          .maxLength(6)
          .fontColor(TEXT_PRIMARY)
          .placeholderColor(TEXT_SECONDARY)
          .backgroundColor(PAGE_BG)
          .height(48)
          .borderRadius(RADIUS_M)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.vm.captcha = value;
          })
        Button(this.vm.countdown > 0 ? `${this.vm.countdown}s 后重发` : '发送验证码')
          .type(ButtonType.Capsule)
          .fontSize(13)
          .fontColor(this.vm.countdown > 0 ? TEXT_SECONDARY : ON_ACCENT)
          .backgroundColor(this.vm.countdown > 0 ? PAGE_BG : ACCENT_COLOR)
          .height(48)
          .margin({ left: 10 })
          .enabled(this.vm.countdown === 0)
          .onClick(() => {
            this.vm.sendCaptcha();
          })
      }
      .width('100%')
      .margin({ top: SPACE_M })
    } else {
      TextInput({ placeholder: '密码', text: this.vm.password })
        .type(InputType.Password)
        .fontColor(TEXT_PRIMARY)
        .placeholderColor(TEXT_SECONDARY)
        .backgroundColor(PAGE_BG)
        .height(48)
        .borderRadius(RADIUS_M)
        .width('100%')
        .margin({ top: SPACE_M })
        .onChange((value: string) => {
          this.vm.password = value;
        })
    }

    if (this.vm.phoneStatus.length > 0) {
      Text(this.vm.phoneStatus)
        .fontSize(13)
        .fontColor(TEXT_SECONDARY)
        .margin({ top: SPACE_M })
    }

    this.PrimaryButton('登录', !this.vm.phoneBusy, () => {
      this.vm.doPhoneLogin();
    })
    this.SecondaryButton('返回', () => {
      this.vm.backToMenu();
    })
  }

  @Builder
  MenuContent() {
    Text('登录后同步你的网易云音乐数据')
      .fontSize(14)
      .fontColor(TEXT_SECONDARY)
      .width('100%')
      .textAlign(TextAlign.Center)
    this.PrimaryButton('扫码登录', true, () => {
      this.vm.startQrLogin();
    })
    this.SecondaryButton('手机号登录', () => {
      this.vm.loginMode = 'phone';
    })
  }

  build() {
    Column() {
      Column() {
        if (this.vm.loginMode === 'qr') {
          this.QrContent()
        } else if (this.vm.loginMode === 'phone') {
          this.PhoneContent()
        } else {
          this.MenuContent()
        }
      }
      .width('100%')
      .padding(SPACE_XL)
      .backgroundColor(CARD_BG)
      .borderRadius(RADIUS_XL)
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .padding({ left: SPACE_XL, right: SPACE_XL, bottom: 80 })
  }
}
