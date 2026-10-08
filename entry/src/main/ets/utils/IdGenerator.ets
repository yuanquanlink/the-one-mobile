export class IdGenerator {
  private static sequence: number = 0;

  static next(prefix: string): string {
    IdGenerator.sequence += 1;
    const randomPart: number = Math.floor(Math.random() * 1000000);
    return `${prefix}_${Date.now()}_${IdGenerator.sequence}_${randomPart}`;
  }
}

