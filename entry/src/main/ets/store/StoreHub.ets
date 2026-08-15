import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { PlayerSnapshot } from './PlayerSnapshot';
import { SessionSnapshot } from './SessionSnapshot';
import { ThemeSettings } from './ThemeSettings';

const KEY_PLAYER: string = 'PlayerSnapshot';
const KEY_SESSION: string = 'SessionSnapshot';
const KEY_THEME: string = 'ThemeSettings';

export class StoreHub {
  private static appContext: common.ApplicationContext | null = null;

  static player(): PlayerSnapshot {
    return AppStorageV2.connect<PlayerSnapshot>(PlayerSnapshot, KEY_PLAYER, () => new PlayerSnapshot())!;
  }

  static session(): SessionSnapshot {
    return AppStorageV2.connect<SessionSnapshot>(SessionSnapshot, KEY_SESSION, () => new SessionSnapshot())!;
  }

  static theme(): ThemeSettings {
    return PersistenceV2.connect<ThemeSettings>(ThemeSettings, KEY_THEME, () => new ThemeSettings())!;
  }

  static initTheme(context: common.UIAbilityContext): void {
    StoreHub.appContext = context.getApplicationContext();
    StoreHub.applyThemeMode(StoreHub.theme().mode);
  }

  static setThemeMode(mode: string): void {
    StoreHub.theme().mode = mode;
    StoreHub.applyThemeMode(mode);
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
  }
}
