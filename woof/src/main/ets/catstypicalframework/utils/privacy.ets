import { privacyManager } from '@kit.AppGalleryKit';
import { meow, meowLevel } from './catsLogger';

export default function getPrivacyPolicyLink(id: string) {
  try {
    const infos = privacyManager.getAppPrivacyMgmtInfo().privacyInfo;
    // Find target
    for (let i = 0; i < infos.length; i++) {
      if (infos[i].id == id) {
        return infos[i].url;
      }
    }
  } catch (e) {
    meow(`privacyManager.getAppPrivacyMgmtInfo().privacyInfo failed: ${e}`, 'getPrivacyPolicyLink', meowLevel.ERROR);
  }
  return undefined;
}