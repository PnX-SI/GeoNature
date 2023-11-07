import { Component, OnInit } from '@angular/core';
import { registerLocaleData } from '@angular/common';
import localeFr from '@angular/common/locales/fr';
import localeZh from '@angular/common/locales/zh';
import { TranslateService } from '@ngx-translate/core';

import { ConfigService } from './services/config.service';

@Component({
  selector: 'pnx-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss'],
})
export class AppComponent implements OnInit {
  constructor(
    private translate: TranslateService,
    public config: ConfigService
  ) {
    // Register all locales (default 'en') used by GeoNature for Angular Pipes
    registerLocaleData(localeFr, 'fr');
    registerLocaleData(localeZh, 'zh');

    this.translate.addLangs(['en', 'fr', 'zh']);
    this.translate.setDefaultLang(this.config.DEFAULT_LANGUAGE);
    this.translate.use(this.config.DEFAULT_LANGUAGE);
  }

  ngOnInit() {}
}
