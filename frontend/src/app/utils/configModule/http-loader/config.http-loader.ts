import { HttpClient } from '@angular/common/http';
import { forwardRef, Inject, resolveForwardRef } from '@angular/core';
import { ConfigLoader } from '../core';
import { Observable, of, Subject } from '@librairies/rxjs';
import { mergeMap } from '@librairies/rxjs/operators';

export class ConfigHttpLoader implements ConfigLoader {
  private _pending: Subject<any>;
  private _config: any;

  constructor(
    @Inject(forwardRef(() => HttpClient)) private readonly http: HttpClient,
    private readonly endpoint: string = '/api.config.json'
  ) {}

  loadSettings(): Observable<any> {
    return new Observable(observer => {
      if (this._config) {
        observer.next(this._config);
        return observer.complete();
      }

      if (!this._pending) {
        const http = resolveForwardRef(this.http);
        this._pending = new Subject();
        of(true)
          .pipe(
            mergeMap(() => {
              return http.get(this.endpoint);
            }),
            mergeMap(apiEndpoint => {
              return http.get(`${apiEndpoint}/gn_commons/frontend_config`);
            })
          )
          .subscribe(config => {
            this._config = config;
            this._pending.next(config);
            this._pending.complete();
            observer.next(config);
            return observer.complete();
          });
      } else {
        this._pending.asObservable().subscribe(config => {
          observer.next(config);
          return observer.complete();
        });
      }
    });
  }
}
