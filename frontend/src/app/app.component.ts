import { Component, OnInit } from '@angular/core';
import { registerLocaleData } from '@angular/common';
import localeFr from '@angular/common/locales/fr';
import localeZh from '@angular/common/locales/zh';

import { TranslateService } from '@ngx-translate/core';

import { AuthService } from '@geonature/components/auth/auth.service';
import { ConfigService } from '@geonature/utils/configModule/core';


@Component({
  selector: 'pnx-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css'],
})
export class AppComponent implements OnInit {
  public appConfig;
  constructor(
    private _authService: AuthService,
    private translate: TranslateService,
    private _configService: ConfigService,
  ) {
    this.appConfig = this._configService.getSettings();

    // Register all locales (default 'en') used by GeoNature for Angular Pipes
    registerLocaleData(localeFr, 'fr');
    registerLocaleData(localeZh, 'zh');

    translate.addLangs(['en', 'fr', 'zh']);
    translate.setDefaultLang(this.appConfig.DEFAULT_LANGUAGE);
    translate.use(this.appConfig.DEFAULT_LANGUAGE);
  }

  ngOnInit() {}
}
