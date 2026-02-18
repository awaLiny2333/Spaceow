import { meowFile } from '../../hosts/meowFiles';

@ObservedV2
export class meowMisc {
  @Trace debugOutput: string = '';
  newMeowFileObj: meowFile | undefined = undefined;
}