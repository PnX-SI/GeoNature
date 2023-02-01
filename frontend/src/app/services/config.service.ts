import { HttpClient } from '@angular/common/http';
import { mergeMap, map, catchError } from 'rxjs/operators';
import { throwError } from 'rxjs';
import { Injectable } from '@angular/core';
import { ToastrService } from 'ngx-toastr';

class Config {
  [key: string]: any;
}

@Injectable()
export class ConfigService extends Config {
  constructor(private _http: HttpClient, private _toaster: ToastrService) {
    super();
  }

  private _getConfig() {
    return this._http.get('./assets/config.json').pipe(
      catchError((error) => {
        this._toaster.error('Config file is missing. It should be located in assets/config.json');
        return throwError(error);
      }),
      mergeMap((config: any) => {
        if ('API_ENDPOINT' in config) {
          return this._http
            .get(`${config.API_ENDPOINT}/gn_commons/config`, {
              headers: { 'not-to-handle': 'true' },
            })
            .pipe(
              map((fullConfig) => {
                Object.assign(this, fullConfig);
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
