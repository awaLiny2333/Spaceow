import lazy { defaultAnima, defaultRoundedRadius, meowAvoid, meowFreeWindowModeStatus, meowLayoutModeStatus } from '../catstypicalframework/utils/ui';
import { AppStorageV2 } from '@kit.ArkUI';
import { meowMisc } from '../catstypicalframework/hosts/meowMisc';
import lazy { resource2String } from '../catstypicalframework/utils/resource';
import lazy { addUnitsToSize, pickDirectory } from '../catstypicalframework/utils/storage';
import { meow, meowLevel } from '../catstypicalframework/utils/catsLogger';
import { meowFile } from '../hosts/meowFiles';
import lazy { MessageEvents, worker } from '@kit.ArkTS';
import lazy GridSpace from '../components/GridSpace';

@Entry
@ComponentV2
struct Index {
  @Local myMeowLayout: meowLayoutModeStatus = AppStorageV2.connect<meowLayoutModeStatus>(meowLayoutModeStatus)!;
  @Local myMeowFreeWindowModeStatus: meowFreeWindowModeStatus = AppStorageV2.connect<meowFreeWindowModeStatus>(meowFreeWindowModeStatus)!;
  @Local myMeowAvoid: meowAvoid = AppStorageV2.connect<meowAvoid>(meowAvoid)!;
  @Local myMeowMisc: meowMisc = AppStorageV2.connect<meowMisc>(meowMisc, 'meowMisc', () => new meowMisc())!;
  // Interaction
  baseFile: meowFile | undefined = undefined;
  @Local basePath: string = '¯\\_(ツ)_/¯';
  @Local baseSize: number = -1;
  @Local loading: boolean = false;
  // Runtime
  @Local render: boolean = false;
  context: Context = this.getUIContext().getHostContext()!;

  aboutToAppear(): void {
    if (this.myMeowMisc.newMeowFileObj) {
      this.baseFile = this.myMeowMisc.newMeowFileObj;
      this.basePath = this.baseFile.path;
      this.baseSize = this.baseFile.size;
      this.myMeowMisc.newMeowFileObj = undefined;
    }
  }

  build() {
    Stack() {
      if (this.render) {
        Column({ space: 10 }) {
          Scroll() {
            Row() {
              Button(`󰃅 ${resource2String($r('app.string.open'), this.context)}`)
                .onClick(() => {
                  this.loading = true;
                  this.baseFile = undefined;
                  this.basePath = '¯\\_(ツ)_/¯';
                  this.baseSize = -1;
                  pickDirectory().then((r) => {
                    if (!r) {
                      return;
                    }
                    meow(`Picked path: ${r}`, 'pickDirectory', meowLevel.INFO);
                    this.scan(r);
                  })
                })
                .backgroundColor($r('app.color.meow_brand'))
            }
            .padding(10)
          }
          .align(Alignment.TopStart)
          .edgeEffect(EdgeEffect.Spring)
          .scrollable(ScrollDirection.Horizontal)
          .borderRadius(defaultRoundedRadius)
          .width('100%')
          .borderWidth(1)
          .borderColor($r('sys.color.comp_background_tertiary'))
          .backgroundColor($r('app.color.blur_background'))
          .shadow(ShadowStyle.OUTER_DEFAULT_SM)

          if (!this.loading) {
            GridSpace({ fileObj: this.baseFile, bRadius: defaultRoundedRadius })
              .width('100%')
              .layoutWeight(1)
          }

        } // Contents
        .height('100%')
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(this.myMeowAvoid)

        Text(`${this.basePath} (${addUnitsToSize(this.baseSize)})`) // Title
          .padding(10)
          .maxLines(1)
          .wordBreak(WordBreak.BREAK_ALL)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: this.myMeowLayout.width - 250 })
      }
    } // Base
    .alignContent(Alignment.Top)
    .animation(defaultAnima)
    .useEffect(this.myMeowFreeWindowModeStatus.on, EffectType.WINDOW_EFFECT)
    .height('100%')
    .width('100%')
    .onAreaChange((o, n) => {
      if (o.width != n.width) {
        this.myMeowLayout.width = n.width as number;
        this.myMeowLayout.wideMode = this.myMeowLayout.width > 900;
      }
      if (o.height != n.height) {
        this.myMeowLayout.height = n.height as number;
      }
      if (!this.render) {
        this.render = true;
      }
    })
  }

  /**
   * Scans the directory.
   * @param path The path.
   * @returns True if succeeded.
   * */
  scan(path: string) {
    this.baseSize = 0;
    this.basePath = path;

    let workerInstance: worker.ThreadWorker | undefined = undefined;
    try {
      workerInstance = new worker.ThreadWorker("woof/ets/workers/Scanner.ets");
      workerInstance.postMessage(path);
      meow(`workerInstance.postMessage(${path})!`, 'scanBuild', meowLevel.WARN);
    } catch (e) {
      meow(`workerInstance.postMessage(${path}); Failed: ${e}`, 'scanBuild', meowLevel.ERROR);
      return false;
    }

    workerInstance.onmessage = (e: MessageEvents): void => {
      if (typeof e.data == 'number') {
        // Returned a new file's size
        this.baseSize += e.data;
      } else {
        // Returned the FileObject
        this.baseFile = e.data as meowFile;
        this.baseSize = this.baseFile.size;
        // Terminate
        try {
          workerInstance!.terminate();
          meow(`workerInstance.terminate()!`, 'scanBuild', meowLevel.WARN);
        } catch (e) {
          meow(`workerInstance.terminate(); Failed: ${e}`, 'scanBuild', meowLevel.ERROR);
        }
        this.loading = false;
      }
    }

    return true;
  }
}