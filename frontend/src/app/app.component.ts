import { Component, OnInit } from '@angular/core';
import { registerLocaleData } from '@angular/common';
import localeFr from '@angular/common/locales/fr';
import localeZh from '@angular/common/locales/zh';
import { TranslateService } from '@ngx-translate/core';

import { ConfigService } from './services/config.service';
import {ActivatedRoute, Router, NavigationEnd} from "@angular/router";
import {Title} from "@librairies/@angular/platform-browser";
import { filter, map, mergeMap } from 'rxjs/operators';

@Component({
  selector: 'pnx-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss'],
})
export class AppComponent implements OnInit {
  constructor(
    private translate: TranslateService,
    public config: ConfigService,
    private router: Router,
    private activatedRoute: ActivatedRoute,
    private titleService: Title
  ) {
    // Register all locales (default 'en') used by GeoNature for Angular Pipes
    registerLocaleData(localeFr, 'fr');
    registerLocaleData(localeZh, 'zh');

    this.translate.addLangs(['en', 'fr', 'zh']);
    this.translate.setDefaultLang(this.config.DEFAULT_LANGUAGE);
    this.translate.use(this.config.DEFAULT_LANGUAGE);
    this.router.events
      .pipe(
        filter(event => event instanceof NavigationEnd),
         map(() => this.getDeepestChild(this.activatedRoute)),
        mergeMap(route => route.data)
      )
      .subscribe((data: { module_label?: string; module_code?: string })  => {
        let title = config.appName;
        let complement = data['module_label'] || data['module_code']
        if (complement){
          title = `${title} - ${complement}`
        }
        this.titleService.setTitle(title);
      });

  }
  private getDeepestChild(route: ActivatedRoute): ActivatedRoute {
    while (route.firstChild) {
      route = route.firstChild;
    }
    return route;
  }

  ngOnInit() {}
}
