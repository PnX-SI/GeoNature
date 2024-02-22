import { HttpClient } from '@angular/common/http';
import { Observable, forkJoin, of } from 'rxjs';
import { map } from 'rxjs/operators';

import { TranslateLoader } from '@ngx-translate/core';
import * as merge from 'lodash/merge';


export class CustomLoader implements TranslateLoader {

  constructor(private http: HttpClient) { }

  getTranslation(lang: string): Observable<any> {
    return forkJoin([
      this.http.get('/assets/i18n/' + lang + '.json'),
      this.http.get('/assets/i18n/' + lang + '.override.json')
        .catch(error => of({})),
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
