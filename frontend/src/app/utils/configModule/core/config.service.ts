import { Observable, of } from 'rxjs';
import { mergeMap } from 'rxjs/operators';
import { HttpRequest } from '@angular/common/http';
import { Injectable } from '@angular/core';

import { ConfigLoader } from './config.loader';

@Injectable()
export class ConfigService {
  protected settings: any;

  constructor(
    readonly loader: ConfigLoader,
    ) {
    }

    fetchConfig(): Observable<any> {
      return this.loader.loadSettings()
      .pipe(mergeMap((res) => {
          this.settings = res
          return of(res);
        })
      );
    }

  getSettings<T = any>(key?: string | Array<string>, defaultValue?: any): T {
    if (!key || (Array.isArray(key) && !key[0])) {
      return this.settings;
    }

    const paths = !Array.isArray(key) ? key.split('.') : key;

    let result = paths.reduce((acc: any, current: string) => acc && acc[current], this.settings);

    if (result === undefined) {
      result = defaultValue;

      if (result === undefined) {
        throw new Error(`No setting found with the specified key [${paths.join('/')}]!`);
      }
    }

    return result;
  }
}
