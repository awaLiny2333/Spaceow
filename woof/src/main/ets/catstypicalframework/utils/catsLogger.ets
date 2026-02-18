export enum meowLevel {
  NORMAL = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
}

export function meow(content: string, tag: string = '', level: meowLevel = meowLevel.NORMAL) {
  switch (level) {
    case meowLevel.NORMAL:
      console.log(`[${tag}] ${content}`);
      break;
    case meowLevel.INFO:
      console.log(`[meow][${tag}] ${content}`);
      break;
    case meowLevel.WARN:
      console.warn(`[meow][${tag}] ${content}`);
      break;
    case meowLevel.ERROR:
      console.error(`[meow][${tag}] ${content}`);
      break;
  }
}