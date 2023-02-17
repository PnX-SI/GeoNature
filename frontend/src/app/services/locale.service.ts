import { Injectable, OnDestroy } from '@angular/core';
import { ActivatedRoute, ActivatedRouteSnapshot, Router } from '@angular/router';
import { registerLocaleData } from '@angular/common';
import localeFr from '@angular/common/locales/fr';
import localeFrExtra from '@angular/common/locales/extra/fr';
import localeZh from '@angular/common/locales/zh';
import localeZhExtra from '@angular/common/locales/extra/zh';

import { TranslateService } from '@ngx-translate/core';
import { noop, Subscription } from 'rxjs';

import { ConfigService } from './config.service';

type ShouldReuseRoute = (future: ActivatedRouteSnapshot, curr: ActivatedRouteSnapshot) => boolean;

@Injectable({
  providedIn: 'root'
})
export class LocaleService implements OnDestroy {
  private initialized = false;
  private subscriptions: Subscription;

  get currentLocale(): string {
    return this.translate.currentLang;
  }

  constructor(
    public config: ConfigService,
    private router: Router,
    private translate: TranslateService,
    private activatedRoute: ActivatedRoute,
  ) {
    const locale =
      'locale' in this.activatedRoute.snapshot.queryParams
        ? this.activatedRoute.snapshot.queryParams.locale
        : this.config.DEFAULT_LANGUAGE;
    this.initializeLocale(locale);
  }

  private initializeLocale(localeId: string, defaultLocaleId = localeId) {
    if (this.initialized) return;

    this.registerLocales();
    this.setDefaultLocale(defaultLocaleId);
    this.setLocale(localeId);
    this.subscribeToLangChange();
    this.extractLocale();

    this.initialized = true;
  }

  private registerLocales() {
    // Register all locales (default 'en') used by GeoNature for Angular Pipes
    registerLocaleData(localeFr, 'fr', localeFrExtra);
    registerLocaleData(localeZh, 'zh', localeZhExtra);

    this.translate.addLangs(['en', 'fr', 'zh']);
  }

  private extractLocale() {
    this.subscriptions = this.activatedRoute.queryParams.subscribe((param: any) => {
      const locale = param['locale'];
      if (locale !== undefined) {
        this.setLocale(locale);
      }
    });
  }

  private subscribeToLangChange() {
    this.translate.onLangChange.subscribe(async () => {
      const { shouldReuseRoute } = this.router.routeReuseStrategy;

      this.setRouteReuse(() => false);
      this.router.navigated = false;

      await this.router.navigateByUrl(this.router.url).catch(noop);
      this.setRouteReuse(shouldReuseRoute);
    });
  }

  private setRouteReuse(reuse: ShouldReuseRoute) {
   this.router.routeReuseStrategy.shouldReuseRoute = reuse;
  }

  setDefaultLocale(localeId: string) {
    this.translate.setDefaultLang(localeId);
  }

  setLocale(localeId: string) {
    this.translate.use(localeId);
  }

  ngOnDestroy() {
    // Prevent memory leak by unsubscribing
    this.subscriptions.unsubscribe();
  }
}
