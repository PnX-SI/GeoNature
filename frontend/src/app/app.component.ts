import { Component, OnInit } from '@angular/core';
import { registerLocaleData } from '@angular/common';
import localeFr from '@angular/common/locales/fr';
import localeZh from '@angular/common/locales/zh';
import { environment } from '../environments/environment';
import { TranslateService } from '@ngx-translate/core';

import { AuthService } from '@geonature/components/auth/auth.service';
import { AppConfig } from '../conf/app.config';

@Component({
  selector: 'pnx-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss'],
})
export class AppComponent implements OnInit {
  constructor(private _authService: AuthService, private translate: TranslateService) {
    // Register all locales (default 'en') used by GeoNature for Angular Pipes
    registerLocaleData(localeFr, 'fr');
    registerLocaleData(localeZh, 'zh');

    translate.addLangs(['en', 'fr', 'zh']);
    translate.setDefaultLang(AppConfig.DEFAULT_LANGUAGE);
    translate.use(AppConfig.DEFAULT_LANGUAGE);
  }

  ngOnInit() {}
}
