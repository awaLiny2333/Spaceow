import { privacyManager } from '@kit.AppGalleryKit';
import { meow, meowLevel } from './catsLogger';

export default function getPrivacyPolicyLink() {
  try {
    const infos = privacyManager.getAppPrivacyMgmtInfo().privacyInfo;
    if (infos.length == 0) {
      return undefined;
    }
    // Find latest
    let latestIdx: number = -1;
    for (let i = 0; i < infos.length; i++) {
      if (infos[i].versionCode > infos[latestIdx].versionCode) {
        latestIdx = i;
      }
    }
    return infos[latestIdx].url;
  } catch (e) {
    meow(`privacyManager.getAppPrivacyMgmtInfo().privacyInfo failed: ${e}`, 'getPrivacyPolicyLink', meowLevel.ERROR);
  }
  return undefined;
}