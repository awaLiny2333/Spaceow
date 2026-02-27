import collections from '@arkts.collections';
import { meow, meowLevel } from '../catstypicalframework/utils/catsLogger';
import { fileIo } from '@kit.CoreFileKit';
import { ThreadWorkerGlobalScope } from '@kit.ArkTS';

@Sendable
export class meowFile {
  isFolder: boolean;
  path: string;
  size: number = -1;
  contents: collections.Array<meowFile> | undefined;

  constructor(isFolder: boolean, path: string) {
    this.isFolder = isFolder;
    this.path = path;
  }

  scanBuild(depth: number = 0, workerPort?: ThreadWorkerGlobalScope) {
    if (!this.isFolder) {
      meow(`Cannot scan build a file!`, 'scanBuild', meowLevel.WARN);
      return this.size;
    }

    this.contents = new collections.Array<meowFile>();

    let fileContents: string[] = [];
    try {
      fileContents = fileIo.listFileSync(this.path);
    } catch (e) {
      meow(`fileContents fileIo.listFileSync(${this.path}) Failed! ${e}`, 'scanBuild', meowLevel.ERROR);
    }

    let totalSize = 0;

    for (let index = 0; index < fileContents.length; index++) {
      const fileName = fileContents[index];
      const filePath = this.path + '/' + fileName;
      try {
        const ft = fileIo.statSync(filePath);
        if (ft.isDirectory()) {
          let f = new meowFile(true, filePath);
          totalSize += f.scanBuild(depth + 1, workerPort);
          this.contents.push(f);
          // meow('  '.repeat(depth) + `[Dire][${filePath}][${addUnitsToSize(f.size)}]`, 'scanBuild', meowLevel.INFO);
        } else if (ft.isFile()) {
          let f = new meowFile(false, filePath);
          f.size = ft.size;
          totalSize += f.size;
          this.contents.push(f);
          // meow('  '.repeat(depth) + `[File][${filePath}][${addUnitsToSize(f.size)}]`, 'scanBuild', meowLevel.INFO);
          if (workerPort && (f.size > 1000)) {
            // console.log('[FileObject] New file: ' + this.size.toString());
            try {
              workerPort.postMessage(f.size);
              // meow(`workerPort.postMessage(${f.size});`, 'scanBuildSync', meowLevel.INFO);
            } catch (e) {
              meow(`workerPort.postMessage(${f.size}); Failed! ${e}`, 'scanBuildSync', meowLevel.ERROR);
            }
          }
        }
      } catch (e) {
        meow(`const ft = fileIo.statSync(${filePath}); Failed! ${e}`, 'scanBuild', meowLevel.ERROR);
      }
    }

    this.size = totalSize;
    return totalSize;
  }
}