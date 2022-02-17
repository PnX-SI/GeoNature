import { HttpClient } from "@angular/common/http";
import { catchError, concatMap, mergeMap } from "rxjs/operators";
import { of, forkJoin } from "rxjs"
import { Injectable } from '@angular/core';
import { ModuleService } from './module.service'

@Injectable()
export class ConfigService {
  constructor(
    private _hhtp: HttpClient,
    private _modules: ModuleService,
  ) {}

  _config: any = {};
  isInitialized = false;
  msgError: any;

  init() {
    return this._hhtp.get('./assets/config.json')
      .pipe(
        catchError((error) => {
          console.log('assets/config.json', error);
          this.msgError= `Le fichier de configuration 'assets/config.json' n'est pas présent.`
          return of(false);
        }),
        mergeMap((config:any) => {
          if (!config) {
            return of(false);
          }

          this._config = config;

          if (!this._config.URL_APPLICATION) {
            this.msgError = {
              message: `Le fichier de configuration 'assets/config.json' est mal renseigné : il manque une valeur pour 'URL_APPLICATION'`,
              config: config
            }
            console.error(this.msgError)
            return of(false)
          }

          const apiConfig = `${this._config.URL_APPLICATION}/gn_commons/config`;

          // on initialise ici la configuration ET les modules
          return forkJoin([
            this._hhtp.get(apiConfig),
            this._modules.fetchModules()
          ])
        }),
        catchError((error) => {
          console.error('api config modules', error);
          this.msgError = {
            error: error.message,
            url: error.url,
            config: this._config,
            hints: `Veuillez vérifier si l'url de l'application est bien ${this._config.URL_APPLICATION} et si l'application est en bon état de marche`
          }
          return of(false);
        }),
        mergeMap((results: any) => {
          if (!results[0]) {
            return of(false)
          }
          this._config = {
            ...this._config,
            ...results[0]
          };
          this.isInitialized = true;
          return of(this._config)
        })
      )
  }

  getConfig() {
    return this._config
  }

}
