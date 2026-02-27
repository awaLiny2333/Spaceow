import { AppStorageV2, window } from '@kit.ArkUI';
import { meow, meowLevel } from '../utils/catsLogger';
import { getUpdateAvoid, getUpdateFreeWindowMode, listenAvoid, listenFocus, listenFreeWindowMode, meowLayoutModeStatus, meowPx2vp } from '../utils/ui';
import { BusinessError } from '@kit.BasicServicesKit';

// Flows

/**
 * Called in onWindowStageCreate, before windowStage.LoadContent
 * @param window window.Window
 * */
export async function aboutToLoadContent(windowStage: window.WindowStage, window: window.Window, context: Context) {

  windowStage.setWindowRectAutoSave(true).then(() => {
    meow('windowStage.setWindowRectAutoSave(true) Success!', 'init', meowLevel.INFO);
  }).catch((err: BusinessError) => {
    meow(`windowStage.setWindowRectAutoSave(true) Failed: ${err}`, 'init', meowLevel.ERROR);
  });

  try {
    window.setImmersiveModeEnabledState(true);
  } catch (e) {
    meow(`window.setImmersiveModeEnabledState(true) Failed: ${e}`, 'init', meowLevel.ERROR);
  }
}

/**
 * Called immediately after windowStage.LoadContent
 * @param window window.Window
 * */
export function onLoadContent(window: window.Window, context: Context) {
  try {
    window.setWindowDecorVisible(false);
  } catch (e) {
    meow(`window.setWindowDecorVisible(false) Failed: ${e}`, 'init', meowLevel.ERROR);
  }

  try {
    const rect: window.Rect = window.getWindowProperties().windowRect;
    const width = meowPx2vp(rect.width);
    const height = meowPx2vp(rect.height);
    const wideMode = width > 900;
    AppStorageV2.connect(meowLayoutModeStatus, () => new meowLayoutModeStatus(wideMode, width, height));
  } catch (e) {
    meow(`AppStorageV2.connect(meowLayoutModeStatus, () => new meowLayoutModeStatus(wideMode)); Failed: ${e}`, 'init', meowLevel.ERROR);
  }
  
  getUpdateFreeWindowMode(context, window);
  listenFreeWindowMode(context, window);

  getUpdateAvoid(window);
  listenAvoid(window);

  listenFocus(window);
}

// Actions

