import { ErrorEvent, MessageEvents, ThreadWorkerGlobalScope, worker } from '@kit.ArkTS';
import { meow, meowLevel } from '../catstypicalframework/utils/catsLogger';
import { meowFile } from '../hosts/meowFiles';

const workerPort: ThreadWorkerGlobalScope = worker.workerPort;

/**
 * Defines the event handler to be called when the worker thread receives a message sent by the host thread.
 * The event handler is executed in the worker thread.
 *
 * @param event message data
 */
workerPort.onmessage = (event: MessageEvents) => {
  if (typeof event.data == "string") {
    let msg = event.data as string;
    // msg is the path
    console.log('[Scanner] Received path: ' + msg);
    let fileObject: meowFile = new meowFile(true, msg);
    fileObject.scanBuild(0, workerPort);
    try {
      workerPort.postMessageWithSharedSendable(fileObject);
    } catch (e) {
      meow(`workerPort.postMessageWithSharedSendable(fileObject); Failed! ${e}`, 'ScannerWorker', meowLevel.ERROR);
    }
  }
};

/**
 * Defines the event handler to be called when the worker receives a message that cannot be deserialized.
 * The event handler is executed in the worker thread.
 *
 * @param event message data
 */
workerPort.onmessageerror = (event: MessageEvents) => {
};

/**
 * Defines the event handler to be called when an exception occurs during worker execution.
 * The event handler is executed in the worker thread.
 *
 * @param event error message
 */
workerPort.onerror = (event: ErrorEvent) => {
};