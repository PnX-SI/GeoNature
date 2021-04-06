import { HttpClient } from '@angular/common/http';
import { forwardRef, Inject, resolveForwardRef } from '@angular/core';
import { ConfigLoader } from '../core';
import { Observable, of, forkJoin } from "@librairies/rxjs";
import { mergeMap, concatMap } from "@librairies/rxjs/operators";

export class ConfigHttpLoader implements ConfigLoader {
  constructor(
    @Inject(forwardRef(() => HttpClient)) private readonly http: HttpClient,
    private readonly endpoint: string = '/api.config.json'
  ) {}

  loadSettings(): Observable<any> {
      const http = resolveForwardRef(this.http);
      return of(true)
      .pipe(
        mergeMap(() => { return http.get(this.endpoint) }),
        mergeMap((apiEndpoint) => { return http.get(`${apiEndpoint}/gn_commons/frontend_config`)})
      )
  }
}
