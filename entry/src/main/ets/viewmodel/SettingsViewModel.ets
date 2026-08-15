import { AuthRepository } from '../model/repository/AuthRepository';
import { StoreHub } from '../store/StoreHub';

@ObservedV2
export class SettingsViewModel {
  @Trace toastMessage: string = '';

  setThemeMode(mode: string): void {
    StoreHub.setThemeMode(mode);
  }

  setFontScale(scale: number): void {
    StoreHub.setFontScale(scale);
  }

  setFontFamily(family: string): void {
    StoreHub.setFontFamily(family);
  }

  async doLogout(): Promise<boolean> {
    await AuthRepository.get().logout();
    StoreHub.session().loginInfo = null;
    this.toastMessage = '已退出登录';
    return true;
  }
}
