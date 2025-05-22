import { Injectable } from '@angular/core';
import { ActivatedRoute } from '@angular/router';

import { Observable, Subject } from '@librairies/rxjs';
import { TranslateService } from '@ngx-translate/core';

export interface I18nChangeEvent {
  lang: string;
}

@Injectable()
export class I18nService {
  private _onLangChange: Subject<I18nChangeEvent> = new Subject<I18nChangeEvent>();
  currentLang: string;

  constructor(
    private translateService: TranslateService,
    private activatedRoute: ActivatedRoute
  ) {
    this.currentLang = this.translateService.getDefaultLang();

    this.extractLocaleFromUrl();

    this.subscribeToRootLangChange();
  }

  private extractLocaleFromUrl() {
    this.activatedRoute.queryParams.subscribe((param: any) => {
      const locale = param['locale'];
      if (locale !== undefined) {
        this.translateService.setDefaultLang(locale);
        this.translateService.use(locale);
      }
    });
  }

  private subscribeToRootLangChange() {
    this.translateService.onLangChange.subscribe((event) => {
      this.currentLang = event.lang;
      this._onLangChange.next({ lang: event.lang });
    });
  }

  public initializeModuleTranslateService(moduleTranslateService: TranslateService) {
    moduleTranslateService.use(this.currentLang);
    this.onLangChange.subscribe((event) => {
      moduleTranslateService.use(event.lang);
    });
  }

  /**
   * An Observable to listen to lang change events inside lazy module
   * when `isolate: true` used with Ngx-Translate.
   * onLangChange.subscribe((params: I18nChangeEvent) => {
   *     // do something
   * });
   */
  get onLangChange(): Observable<I18nChangeEvent> {
    return this._onLangChange.asObservable();
  }
}
