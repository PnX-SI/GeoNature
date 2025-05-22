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
    const i18nFiles = [this.http.get(`/assets/i18n/${lang}.json`)];
    if (this.options.moduleName !== null) {
      i18nFiles.push(
        this.http
          .get(`/modules/${this.options.moduleName}/assets/i18n/${lang}.json`)
          .catch((error) => of({}))
      );
    }
    i18nFiles.push(this.http.get(`/assets/i18n/override/${lang}.json`).catch((error) => of({})));

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
