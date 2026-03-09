import { meow, meowLevel } from '../catstypicalframework/utils/catsLogger';
import { resource2String } from '../catstypicalframework/utils/resource';
import { addUnitsToSize, fileNameOfPath, showInFiles } from '../catstypicalframework/utils/storage';
import { defaultAnima, meowLayoutModeStatus } from '../catstypicalframework/utils/ui';
import { meowFile } from '../hosts/meowFiles';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { abilityManager, common, Want } from '@kit.AbilityKit';
import { copy } from '../catstypicalframework/utils/clipboard';
import { meowMisc } from '../catstypicalframework/hosts/meowMisc';
import { AppStorageV2 } from '@kit.ArkUI';

export const resolution: number = 14;

class gridSpacePosition {
  // Represents the position of a square tile
  file: meowFile;
  x: number;
  y: number;
  a: number; // Side length

  constructor(f: meowFile, x: number, y: number, a: number) {
    this.file = f;
    this.x = x;
    this.y = y;
    this.a = a;
  }
}

@ComponentV2
struct GridSpace {
  @Local isOpened: boolean = false;
  @Param fileObj: meowFile | undefined = undefined;
  @Param @Require bRadius: number;
  // Size
  @Local myMeowLayout: meowLayoutModeStatus = AppStorageV2.connect<meowLayoutModeStatus>(meowLayoutModeStatus)!;
  @Local spaceWidth: number = -1;
  @Local spaceHeight: number = -1;
  // UI
  @Local isMenu: boolean = false;
  @Local isFocus: boolean = false;
  @Local isHover: boolean = false;
  @Local hoverBiasX: number = 0;
  @Local hoverBiasY: number = 0;
  // Runtime
  context: Context = this.getUIContext()
    .getHostContext()!;

  build() {
    if (this.fileObj) {
      Stack() {
        if (this.isOpened) {
          ForEach(layoutFolder(this.fileObj, resolution), ((gsp: gridSpacePosition) => {
            GridSpace({ fileObj: gsp.file, bRadius: this.bRadius * 0.5 })
              .position({
                left: gsp.x * (this.spaceWidth - this.bRadius * 0.5) / resolution,
                top: gsp.y * (this.spaceHeight - this.bRadius * 0.5) / resolution,
              })
              .width(gsp.a * (this.spaceWidth - this.bRadius * 0.5) / resolution - this.bRadius * 0.5)
              .height(gsp.a * (this.spaceHeight - this.bRadius * 0.5) / resolution - this.bRadius * 0.5)
          }), (gsp: gridSpacePosition) => {
            return gsp.file.path + '_' + gsp.file.size.toFixed(16);
          })
        } else {
          if (this.spaceHeight > 0) {
            Column() {
              Text(`${fileNameOfPath(this.fileObj.path)}`)
                .fontWeight(FontWeight.Medium)
                .fontSize(this.spaceHeight / 5)
                .opacity(0.8)
                .maxLines(3)
              Text(`${addUnitsToSize(this.fileObj.size)}`)
                .fontWeight(FontWeight.Bold)
                .fontSize(this.spaceHeight / 6)
                .opacity(0.5)
            }
            .clip(true)
            .padding(this.bRadius * 0.5 * 0.5)
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
        }
        Column()
          .bindContextMenu(this.isMenu, this.bindMenuBuilder(), {
            aboutToDisappear: () => {
              this.isMenu = false;
            },
          })
      }
      .borderColor(this.isFocus ? $r('sys.color.font_secondary') : $r('sys.color.icon_fourth'))
      .borderWidth(this.isFocus ? 2 : 1)
      .padding({ left: this.bRadius * 0.5, top: this.bRadius * 0.5 })
      .backgroundColor(this.isOpened ? $r('app.color.blur_background') : (this.fileObj?.isFolder ? $r('app.color.meow_sub') : $r('app.color.meow_sub_sub')))
      .shadow(this.meowShadowOptions())
      .scale(this.isAppearanceHover() ? {
        x: ((this.bRadius * 1.5 + this.spaceWidth) / this.spaceWidth),
        y: ((this.bRadius * 1.5 + this.spaceHeight) / this.spaceHeight)
      } : undefined)
      .rotate(this.isAppearanceHover() ? { angleY: -this.hoverBiasX / this.spaceWidth * 5, angleX: this.hoverBiasY / this.spaceHeight * 5 } : {}) // Extremely laggy. Wait for Kirin X900.
      .brightness(this.meowBrightness())
      .animation(defaultAnima)
      .clickEffect({ level: ClickEffectLevel.MIDDLE })
      .hitTestBehavior(HitTestMode.BLOCK_HIERARCHY)
      .onFocus(() => {
        this.isFocus = true;
      })
      .onBlur(() => {
        this.isFocus = false;
      })
      .onAreaChange((o, n) => {
        if (o.width != n.width) {
          this.spaceWidth = n.width as number;
        }
        if (o.height != n.height) {
          this.spaceHeight = n.height as number;
        }
      })
      .onClick(() => {
        if (this.fileObj?.isFolder) {
          this.isOpened = !this.isOpened;
        }
        this.isMenu = false;
      })
      .onHover((isHover) => {
        this.isHover = isHover;
      })
      .width('100%')
      .height('100%')
      .borderRadius(this.bRadius)
      .gesture(
        LongPressGesture({ repeat: true })
          .onAction(() => {
            this.isMenu = false;
            setTimeout(() => {
              this.isMenu = true;
            }, 10);
          })
      )
      .onMouse((e) => {
        if ((e.button == MouseButton.Right) && (e.action == MouseAction.Press)) {
          this.isMenu = false;
          setTimeout(() => {
            this.isMenu = true;
          }, 10);
        }
        const bX = (e.x || 0) - this.spaceWidth / 2;
        const bY = (e.y || 0) - this.spaceHeight / 2;
        this.hoverBiasX = bX;
        this.hoverBiasY = bY;
        meow(`[${this.fileObj?.path}] Hover: ${this.isHover}, X: ${bX}, Y: ${bY}`, 'GridSpace', meowLevel.WARN);
      })
    }
  }

  meowBrightness() {
    if (!this.isHover) {
      return 1;
    }
    if (this.fileObj?.isFolder && this.isOpened) {
      return 1.03;
    }
    return 1;
  }

  meowShadowOptions() {
    if (this.isAppearanceHover()) {
      return { radius: this.shadowRadius(), fill: false, color: $r('app.color.meow_shadow'), offsetX: this.hoverBiasX / 10, offsetY: this.hoverBiasY / 10 } as ShadowOptions;
    }
    return { radius: 1, fill: false, color: $r('app.color.meow_shadow'), offsetX: 0, offsetY: 0 } as ShadowOptions
  }

  shadowRadius() {
    // Size of block
    const size = this.spaceWidth * this.spaceHeight;
    // Radius of shadow
    let targetRadius = size / 1000;
    if (targetRadius > 30) {
      targetRadius = 30;
    }
    if (targetRadius < 10) {
      targetRadius = 10
    }
    return targetRadius;
  }

  isAppearanceHover() {
    if (!this.isHover) {
      return false;
    }
    if (this.fileObj?.isFolder && this.isOpened) {
      return false;
    }
    return true;
  }

  @Builder
  bindMenuBuilder() {
    Column() {
      Text(`${this.fileObj?.isFolder ? '󰃅' : '󰂽'}  ${this.fileObj?.path || ':O'} (${addUnitsToSize(this.fileObj?.size || 0)})`)
        .fontWeight(FontWeight.Medium)
        .padding(8)
        .opacity(0.75)

      Text(`󰃋  ${resource2String($r('app.string.view_in_new_spaceow'), this.context)}`)
        .onClick(() => {
          if (!this.fileObj) {
            return;
          }
          this.openAsNew(this.fileObj);
        })
        .padding(8)
        .hoverEffect(HoverEffect.Highlight)
        .borderRadius(deviceInfo.deviceType == deviceInfo.DeviceTypes.TYPE_2IN1 ? 5 : 18)

      Text(`󰈱  ${resource2String($r('app.string.visit'), this.context)}`)
        .onClick(() => {
          if (!this.fileObj) {
            return;
          }
          showInFiles(this.fileObj.path, this.context as common.UIAbilityContext);
        })
        .padding(8)
        .hoverEffect(HoverEffect.Highlight)
        .borderRadius(deviceInfo.deviceType == deviceInfo.DeviceTypes.TYPE_2IN1 ? 5 : 18)

      Text(`󰆝  ${resource2String($r('app.string.copy'), this.context)}`)
        .onClick(() => {
          if (!this.fileObj) {
            return;
          }
          copy(this.fileObj.path);
        })
        .padding(8)
        .hoverEffect(HoverEffect.Highlight)
        .borderRadius(deviceInfo.deviceType == deviceInfo.DeviceTypes.TYPE_2IN1 ? 5 : 18)
    }
    .alignItems(HorizontalAlign.Start)
  }

  openAsNew(fileObj: meowFile | undefined) {
    if (!fileObj) {
      return;
    }

    abilityManager.getAbilityRunningInfos()
      .then((e) => {
        const bundleName = e[0].ability.bundleName;
        const moduleName = e[0].ability.moduleName;
        const abilityName = e[0].ability.abilityName;

        // Open new window
        let misc = AppStorageV2.connect<meowMisc>(meowMisc, 'meowMisc', () => new meowMisc())!;
        misc.newMeowFileObj = fileObj;
        let wantInfo: Want = {
          deviceId: '', // This device
          bundleName: bundleName,
          moduleName: moduleName,
          abilityName: abilityName,
        };

        // Call
        let context: common.UIAbilityContext = this.context as common.UIAbilityContext;
        context.startAbility(wantInfo)
          .then(() => {
            meow(`context.startAbility(wantInfo) OK!`, 'openAsNew', meowLevel.WARN);
          })
          .catch((e: BusinessError) => {
            meow(`context.startAbility(wantInfo) Failed! ${e}`, 'openAsNew', meowLevel.ERROR);
          });
      })
      .catch((e: BusinessError) => {
        meow(`abilityManager.getAbilityRunningInfos() Failed! ${e}`, 'openAsNew', meowLevel.ERROR);
      })
  }
}

export default GridSpace;

// 假设 meowFile 和 gridSpacePosition 已定义
// export class meowFile { ... }
// class gridSpacePosition { ... }

/**
 * 将文件夹内的所有内容平铺在 resolution x resolution 的棋盘上
 * @param folder 保证是文件夹的 meowFile 对象
 * @param resolution 棋盘边长（整数）
 * @returns 每个内容对应的位置信息数组
 * @author DeepSeek Web @ Feb 18 2026, modified and adapted by awa_Liny!
 */
function layoutFolder(folder: meowFile, resolution: number): gridSpacePosition[] {
  meow(`layoutFolder ${folder.path}`, 'layoutFolder', meowLevel.WARN);
  // 获取文件夹内容
  const items = Array.from(folder.contents!);
  if (!items || items.length === 0) {
    return [];
  }

  // 计算总大小
  const totalSize = folder.size;
  // const totalSize = items.reduce((sum, f) => sum + f.size, 0);
  if (totalSize === 0) {
    // 如果所有文件大小都为 0，则全部使用边长为 1 的正方形
    return layoutAllOnes(items, resolution);
  }

  // 尝试不同的缩放因子，从 1.0 开始逐渐减小，直到布局成功
  let scale = 1.5;
  const maxAttempts = 20; // 避免无限循环
  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    // 根据当前缩放因子计算每个文件的边长
    const candidates = items.map(file => {
      // 目标面积 = (file.size / totalSize) * resolution^2 * scale
      const area = (file.size / totalSize) * resolution * resolution * scale;
      let a = Math.max(1, Math.ceil(Math.sqrt(area)));
      // 边长不能超过棋盘
      a = Math.min(a, resolution);
      return { file: file, a: a } as itemInterface;
    });

    // 按边长降序排序（大的先放，提高成功率）
    candidates.sort((a, b) => b.a - a.a);

    // 尝试布局
    const result = tryLayout(candidates, resolution);
    if (result) {
      return result; // 成功则返回
    }

    // 失败则缩小缩放因子
    scale *= 0.9;
  }

  // 如果多次尝试均失败，回退到所有边长为 1（只要数量不超过 resolution^2 就能成功）
  return layoutAllOnes(items, resolution);
}

interface itemInterface {
  file: meowFile;
  a: number;
}

/**
 * 使用 Guillotine 分割算法尝试布局给定的正方形列表
 * @param items 包含文件和目标边长的对象数组（已按边长降序）
 * @param resolution 棋盘大小
 * @returns 成功返回位置数组，失败返回 null
 */
function tryLayout(items: itemInterface[], resolution: number): gridSpacePosition[] | null {
  // 空闲矩形列表，每个矩形用 { x, y, width, height } 表示
  interface FreeRect {
    x: number;
    y: number;
    width: number;
    height: number;
  }

  const freeRects: FreeRect[] = [{
    x: 0,
    y: 0,
    width: resolution,
    height: resolution
  }];
  const result: gridSpacePosition[] = [];

  for (const item of items) {
    let a = item.a;
    let placed = false;

    // 查找能容纳 a x a 的矩形
    for (let i = 0; i < freeRects.length; i++) {
      const rect = freeRects[i];
      if (rect.width >= a && rect.height >= a) {
        // 放置正方形
        const x = rect.x;
        const y = rect.y;
        result.push(new gridSpacePosition(item.file, x, y, a));

        // 移除当前矩形
        freeRects.splice(i, 1);

        // 分割剩余空间：右侧矩形和上方矩形
        if (rect.width - a > 0) {
          freeRects.push({
            x: rect.x + a,
            y: rect.y,
            width: rect.width - a,
            height: a,
          });
        }
        if (rect.height - a > 0) {
          freeRects.push({
            x: rect.x,
            y: rect.y + a,
            width: rect.width,
            height: rect.height - a,
          });
        }

        placed = true;
        break;
      }
    }

    if (!placed) {
      // 无法放置当前正方形，布局失败
      return null;
    }
  }

  return result;
}

/**
 * 当所有文件大小为零或缩放失败时，将所有文件以边长为 1 的正方形平铺
 * （按从左到右、从上到下的顺序填充，保证不重叠且不超过棋盘）
 */
function layoutAllOnes(files: meowFile[], resolution: number): gridSpacePosition[] {
  const result: gridSpacePosition[] = [];
  const total = files.length;
  const maxPerRow = resolution; // 每行最多放 resolution 个
  for (let i = 0; i < total; i++) {
    const row = Math.floor(i / maxPerRow);
    const col = i % maxPerRow;
    if (row >= resolution) {
      // 棋盘已满，无法放置更多（可根据需求截断或报错，这里简单停止）
      break;
    }
    result.push(new gridSpacePosition(files[i], col, row, 1));
  }
  return result;
}
