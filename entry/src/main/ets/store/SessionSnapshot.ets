import { LoginInfo } from '../model/entity/models';

@ObservedV2
export class SessionSnapshot {
  @Trace loginInfo: LoginInfo | null = null;
}
