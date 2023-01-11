import { HttpClient } from '@angular/common/http';
import { mergeMap, map, catchError, filter } from 'rxjs/operators';
import { of, throwError } from 'rxjs';
import { Injectable } from '@angular/core';
import { ModuleService } from './module.service';
import { ToastrService } from 'ngx-toastr';

@Injectable()
export class ConfigService {
  constructor(private _http: HttpClient, private _toaster: ToastrService) {}

  config: any = {};

  private _getConfig() {
    return this._http.get('./assets/config.json').pipe(
      catchError((error) => {
        this._toaster.error('Config file is missing. It should be located in assets/config.json');
        return throwError(error);
      }),
      mergeMap((config: any) => {
        if ('API_ENDPOINT' in config) {
          return this._http.get(`${config.API_ENDPOINT}/gn_commons/config`).pipe(
            map((fullConfig) => {
              this.config = fullConfig;
            }),
            catchError((error) => {
              this._toaster.error(
                'Can not load config from API. Maybe API is down ' + error.error.description
              );
              return throwError(error);
            })
          );
        } else {
          this._toaster.error("Missing 'API_ENDPOINT' in config.json");
          return throwError("Missing 'API_ENDPOINT' in config.json");
        }
      })
    );
  }
}
