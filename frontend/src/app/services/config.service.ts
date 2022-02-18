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

  config: any = {};
  isInitialized = false;
  msgError: any;

  init() {
    return this._hhtp.get('./assets/config.json')
      .pipe(
        catchError((error) => {
          console.error('assets/config.json', error);
          this.msgError= `Le fichier de configuration 'assets/config.json' n'est pas présent.`
          return of(false);
        }),
        mergeMap((config:any) => {
          if (!config) {
            return of(false);
          }

          this.config = config;

          if (!this.config.API_ENDPOINT) {
            this.msgError = {
              message: `Le fichier de configuration 'assets/config.json' est mal renseigné : il manque une valeur pour 'API_ENDPOINT'`,
              config: config
            }
            console.error(this.msgError)
            return of(false)
          }

          const apiConfig = `${this.config.API_ENDPOINT}/gn_commons/modules_and_config`;

          // on initialise ici la configuration ET les modules
          return this._hhtp.get(apiConfig);
        }),
        catchError((error) => {
          console.error('api config modules', error);
          this.msgError = {
            error: error.message,
            url: error.url,
            config: this.config,
            hints: `Veuillez vérifier si l'url de l'application est bien ${this.config.URL_APPLICATION} et si l'application est en bon état de marche`
          }
          return of(false);
        }),
        mergeMap((results: any) => {
          if (!results) {
            return of(false)
          }
          this._modules.setModules(results.modules)
          this.config = {
            ...this.config,
            ...results.config
          };
          this.isInitialized = true;
          return of(this.config)
        })
      )
  }

}
