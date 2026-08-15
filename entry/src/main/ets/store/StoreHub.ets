import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { PlayerSnapshot } from './PlayerSnapshot';
import { SessionSnapshot } from './SessionSnapshot';
import { LikeSnapshot } from './LikeSnapshot';
import { ThemeSettings } from './ThemeSettings';

const KEY_PLAYER: string = 'PlayerSnapshot';
const KEY_SESSION: string = 'SessionSnapshot';
const KEY_LIKES: string = 'LikeSnapshot';
const KEY_THEME: string = 'ThemeSettings';

export class StoreHub {
  private static appContext: common.ApplicationContext | null = null;
  private static fontReady: boolean = false;
  private static colorModeListener: (() => void) | null = null;

  static player(): PlayerSnapshot {
    return AppStorageV2.connect<PlayerSnapshot>(PlayerSnapshot, KEY_PLAYER, () => new PlayerSnapshot())!;
  }

  static session(): SessionSnapshot {
    return AppStorageV2.connect<SessionSnapshot>(SessionSnapshot, KEY_SESSION, () => new SessionSnapshot())!;
  }

  static likes(): LikeSnapshot {
    return AppStorageV2.connect<LikeSnapshot>(LikeSnapshot, KEY_LIKES, () => new LikeSnapshot())!;
  }

  static theme(): ThemeSettings {
    return PersistenceV2.connect<ThemeSettings>(ThemeSettings, KEY_THEME, () => new ThemeSettings())!;
  }

  static initTheme(context: common.UIAbilityContext): void {
    StoreHub.appContext = context.getApplicationContext();
    StoreHub.applyThemeMode(StoreHub.theme().mode);
  }

  /** 窗口创建完成后调用，此时才能 setFont / setFontSizeScale */
  static markFontReady(): void {
    StoreHub.fontReady = true;
    StoreHub.applyFont();
  }

  static setThemeMode(mode: string): void {
    StoreHub.theme().mode = mode;
    StoreHub.applyThemeMode(mode);
  }

  static setFontScale(scale: number): void {
    StoreHub.theme().fontScale = scale;
    StoreHub.applyFont();
  }

  static setFontFamily(family: string): void {
    StoreHub.theme().fontFamily = family;
    StoreHub.applyFont();
  }

  static applyThemeMode(mode: string): void {
    if (StoreHub.appContext === null) {
      return;
    }
    let colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
    if (mode === 'light') {
      colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
    } else if (mode === 'dark') {
      colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    }
    try {
      StoreHub.appContext.setColorMode(colorMode);
    } catch (err) {
      console.error(`[StoreHub] setColorMode failed: ${JSON.stringify(err)}`);
    }
    StoreHub.notifyColorModeChanged();
  }

  /** 系统深浅色变化时刷新状态栏图标色；勿写入 ThemeSettings（会持久化） */
  static setColorModeListener(cb: (() => void) | null): void {
    StoreHub.colorModeListener = cb;
  }

  static notifyColorModeChanged(): void {
    if (StoreHub.colorModeListener !== null) {
      StoreHub.colorModeListener();
    }
  }

  static applyFont(): void {
    if (StoreHub.appContext === null || !StoreHub.fontReady) {
      return;
    }
    const theme: ThemeSettings = StoreHub.theme();
    try {
      StoreHub.appContext.setFontSizeScale(theme.fontScale);
    } catch (err) {
      console.error(`[StoreHub] setFontSizeScale failed: ${JSON.stringify(err)}`);
    }
    try {
      StoreHub.appContext.setFont(theme.fontFamily);
    } catch (err) {
      console.error(`[StoreHub] setFont failed: ${JSON.stringify(err)}`);
    }
  }
}
