import { HttpClient } from '@angular/common/http';
import { Observable, forkJoin, of } from 'rxjs';
import { map } from 'rxjs/operators';

import * as merge from 'lodash/merge';
import { TranslateLoader } from '@ngx-translate/core';

import { AppConfig } from '@geonature_config/app.config';

export class CustomTranslateLoader implements TranslateLoader {
  constructor(private http: HttpClient) {}

  getTranslation(lang: string = AppConfig['DEFAULT_LANGUAGE']): Observable<any> {
    return forkJoin([
      this.http.get('/assets/i18n/' + lang + '.json'),
      this.http.get('/assets/i18n/' + lang + '.override.json').catch((error) => of({})),
    ]).pipe(
      map((data) => {
        const mergedTranslations = {};
        data.forEach((currentTranslations) => {
          merge(mergedTranslations, currentTranslations);
        });
        return mergedTranslations;
      })
    );
  }
}
