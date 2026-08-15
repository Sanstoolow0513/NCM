import { AuthRepository } from '../model/repository/AuthRepository';
import { QrCheckResult } from '../model/entity/models';
import { StoreHub } from '../store/StoreHub';
import { errMsg, sleep } from '../common/utils/format';

@ObservedV2
export class LoginViewModel {
  /** 登录入口模式：menu 选择菜单 / qr 扫码 / phone 手机号 */
  @Trace loginMode: string = 'menu';
  @Trace qrKey: string = '';
  @Trace qrStatus: string = '';
  @Trace phone: string = '';
  @Trace captcha: string = '';
  @Trace password: string = '';
  /** 0 验证码登录 / 1 密码登录 */
  @Trace phoneWay: number = 0;
  @Trace phoneStatus: string = '';
  @Trace phoneBusy: boolean = false;
  @Trace countdown: number = 0;
  @Trace toastMessage: string = '';
  private polling: boolean = false;
  private countdownTimer: number = -1;

  stop(): void {
    this.polling = false;
    this.clearCountdown();
  }

  backToMenu(): void {
    this.polling = false;
    this.loginMode = 'menu';
  }

  async startQrLogin(): Promise<void> {
    this.loginMode = 'qr';
    this.qrKey = '';
    this.qrStatus = '正在获取二维码...';
    try {
      const key = await AuthRepository.get().qrCreateKey();
      if (this.loginMode !== 'qr') {
        return;
      }
      this.qrKey = key;
      this.qrStatus = '请使用网易云音乐 App 扫码';
      this.polling = true;
      let fails = 0;
      while (this.polling) {
        let r: QrCheckResult;
        try {
          r = await AuthRepository.get().qrCheck(key);
          fails = 0;
        } catch (e) {
          fails++;
          console.error(`[LoginViewModel] qrCheck error (${fails}): ${JSON.stringify(e)}`);
          if (fails >= 5) {
            this.qrStatus = '网络异常，请重新获取二维码';
            this.polling = false;
            break;
          }
          await sleep(2000);
          continue;
        }
        if (r.code === 800) {
          this.qrStatus = '二维码已过期，请重新获取';
          this.polling = false;
        } else if (r.code === 801) {
          this.qrStatus = '等待扫码...';
        } else if (r.code === 802) {
          this.qrStatus = '已扫码，请在手机上确认';
        } else if (r.code === 803) {
          this.polling = false;
          const info = await AuthRepository.get().loginStatus();
          if (info.uid > 0) {
            StoreHub.session().loginInfo = info;
            this.toastMessage = `欢迎，${info.nickname}`;
            this.loginMode = 'menu';
          } else {
            StoreHub.session().loginInfo = null;
            this.qrStatus = '登录状态校验失败，请重试';
          }
          return;
        }
        await sleep(1800);
      }
    } catch (e) {
      console.error(`[LoginViewModel] qr login failed: ${JSON.stringify(e)}`);
      this.qrStatus = '登录失败，请重试';
      this.polling = false;
    }
  }

  async sendCaptcha(): Promise<void> {
    if (this.phone.length !== 11) {
      this.toastMessage = '请输入 11 位手机号';
      return;
    }
    try {
      await AuthRepository.get().captchaSend('86', this.phone);
      this.phoneStatus = '验证码已发送，请注意查收';
      this.countdown = 60;
      this.clearCountdown();
      this.countdownTimer = setInterval(() => {
        this.countdown--;
        if (this.countdown <= 0) {
          this.clearCountdown();
        }
      }, 1000);
    } catch (e) {
      console.error(`[LoginViewModel] send captcha failed: ${JSON.stringify(e)}`);
      this.phoneStatus = errMsg(e);
    }
  }

  async doPhoneLogin(): Promise<void> {
    if (this.phone.length !== 11) {
      this.toastMessage = '请输入 11 位手机号';
      return;
    }
    this.phoneBusy = true;
    this.phoneStatus = '登录中...';
    try {
      const info = this.phoneWay === 0
        ? await AuthRepository.get().loginCellphoneCaptcha('86', this.phone, this.captcha)
        : await AuthRepository.get().loginCellphonePassword(this.phone, this.password);
      StoreHub.session().loginInfo = info;
      this.toastMessage = `欢迎，${info.nickname}`;
      this.loginMode = 'menu';
      this.phoneStatus = '';
    } catch (e) {
      console.error(`[LoginViewModel] phone login failed: ${JSON.stringify(e)}`);
      this.phoneStatus = errMsg(e);
    } finally {
      this.phoneBusy = false;
    }
  }

  private clearCountdown(): void {
    if (this.countdownTimer !== -1) {
      clearInterval(this.countdownTimer);
      this.countdownTimer = -1;
    }
  }
}
