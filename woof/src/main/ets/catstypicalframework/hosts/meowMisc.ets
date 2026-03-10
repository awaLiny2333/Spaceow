import { meowFile } from '../../hosts/meowFiles';

@ObservedV2
export class meowMisc {
  @Trace debugOutput: string = '';
  @Trace selectedPath: string = '';
  newMeowFileObj: meowFile | undefined = undefined;
}