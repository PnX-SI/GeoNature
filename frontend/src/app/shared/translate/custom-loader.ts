import { HttpClient } from '@angular/common/http';
import { Observable, forkJoin, of } from 'rxjs';
import { map } from 'rxjs/operators';

import * as merge from 'lodash/merge';
import { TranslateLoader } from '@ngx-translate/core';

import { ConfigService } from '@geonature/services/config.service';

export interface iCustomTranslateLoaderOptions {
  moduleName?: String | null;
}

export abstract class iCustomTranslateLoader extends TranslateLoader {
  public options: iCustomTranslateLoaderOptions;
}

export class CustomTranslateLoader implements iCustomTranslateLoader {
  constructor(
    private http: HttpClient,
    private config: ConfigService,
    public options: iCustomTranslateLoaderOptions = { moduleName: null }
  ) {}

  getTranslation(lang: string = this.config.DEFAULT_LANGUAGE): Observable<any> {
    const url_application = this.config.URL_APPLICATION;
    const v = this.config.GEONATURE_VERSION;
    const i18nFiles = [this.http.get(`${url_application}/assets/i18n/${lang}.json?v=${v}`)];
    if (this.options.moduleName !== null) {
      i18nFiles.push(
        this.http
          .get(
            `${url_application}/modules/${this.options.moduleName}/assets/i18n/${lang}.json?v=${v}`
          )
          .catch((error) => of({}))
      );
    }
    i18nFiles.push(
      this.http
        .get(`${url_application}/assets/i18n/override/${lang}.json?v=${v}`)
        .catch((error) => of({}))
    );

    return forkJoin(i18nFiles).pipe(
      map((data) => {
        let mergedTranslations = {};
        data.forEach((currentTranslations) => {
          mergedTranslations = merge(mergedTranslations, currentTranslations);
        });
        return mergedTranslations;
      })
    );
  }
}
