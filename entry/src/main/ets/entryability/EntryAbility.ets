/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { NcmHttp } from '../model/source/NcmHttp';
import { AuthRepository } from '../model/repository/AuthRepository';
import { PlayerService } from '../service/player/PlayerService';
import { StoreHub } from '../store/StoreHub';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    StoreHub.initTheme(this.context);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    NcmHttp.get().init(this.context);
    PlayerService.get().init(this.context);

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
      windowStage.getMainWindow().then((mainWindow: window.Window) => {
        mainWindow.setWindowSystemBarProperties({
          navigationBarColor: '#00000000'
        }).catch((barErr: Error) => {
          hilog.warn(DOMAIN, 'testTag', 'setWindowSystemBarProperties failed: %{public}s', JSON.stringify(barErr));
        });
      }).catch((winErr: Error) => {
        hilog.warn(DOMAIN, 'testTag', 'getMainWindow failed: %{public}s', JSON.stringify(winErr));
      });
    });

    if (NcmHttp.get().isLoggedIn()) {
      AuthRepository.get().loginStatus().then((info) => {
        if (info.code === 200 && info.uid > 0) {
          StoreHub.session().loginInfo = info;
        } else {
          NcmHttp.get().clearLogin();
          StoreHub.session().loginInfo = null;
        }
      }).catch((e: Error) => {
        hilog.warn(DOMAIN, 'testTag', 'loginStatus failed: %{public}s', JSON.stringify(e));
      });
    }
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
    PlayerService.get().exitBackground();
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
    PlayerService.get().enterBackground();
  }
}
