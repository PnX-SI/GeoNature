import { HttpClient } from '@angular/common/http';
import { Observable, forkJoin, of } from 'rxjs';
import { map } from 'rxjs/operators';

import * as merge from 'lodash/merge';
import { TranslateLoader } from '@ngx-translate/core';

import { ConfigService } from '@geonature/services/config.service';

export class CustomTranslateLoader implements TranslateLoader {
  constructor(
    private http: HttpClient,
    private config: ConfigService
  ) {}

  getTranslation(lang: string = this.config.DEFAULT_LANGUAGE): Observable<any> {
    return forkJoin([
      this.http.get(`/assets/i18n/${lang}.json`),
      this.http.get(`/assets/i18n/override/${lang}.json`).catch((error) => of({})),
    ]).pipe(
      map((data) => {
        const mergedTranslations = {};
        data.forEach((currentTranslations) => {
          //Object.assign(translations, obj);
          merge(mergedTranslations, currentTranslations);
        });
        return mergedTranslations;
      })
    );
  }
}
