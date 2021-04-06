import { mergeMap, tap } from 'rxjs/operators';

import { Observable, of, forkJoin } from "@librairies/rxjs";export abstract class ConfigLoader {
  abstract loadSettings(): Observable<any>;
}

export class ConfigStaticLoader implements ConfigLoader {
  constructor(private readonly providedSettings?: any) {
  }

  loadSettings(): Observable<any> {
    return this.providedSettings;
  }
}
