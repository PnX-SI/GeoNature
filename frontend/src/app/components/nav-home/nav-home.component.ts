import { Component, OnInit, OnDestroy, Inject, ViewChild } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { ActivatedRoute } from '@angular/router';
import { Subscription } from 'rxjs/Subscription';
import { AuthService, User } from '../../components/auth/auth.service';
import { AppConfig } from '../../../conf/app.config';
import { MatSidenav } from '@angular/material/sidenav';
import { SideNavService } from '../sidenav-items/sidenav-service';
import { Location } from '@angular/common';
import { GlobalSubService } from '../../services/global-sub.service';

@Component({
  selector: 'pnx-nav-home',
  templateUrl: './nav-home.component.html',
  styleUrls: ['./nav-home.component.scss'],
  providers: [{ provide: AppConfig, useValue: AppConfig }]
})
export class NavHomeComponent implements OnInit, OnDestroy {
  public moduleName = 'Accueil';
  private subscription: Subscription;
  public currentUser: User;
  public appConfig: any;
  public currentDocUrl: string;
  @ViewChild('sidenav') public sidenav: MatSidenav;

  constructor(
    private translate: TranslateService,
    private _authService: AuthService,
    private activatedRoute: ActivatedRoute,
    private _sideNavService: SideNavService,
    private _location: Location,
    private _globalSub: GlobalSubService
  ) {
    translate.addLangs(['en', 'fr', 'cn']);
    translate.setDefaultLang(AppConfig.DEFAULT_LANGUAGE);
    translate.use(AppConfig.DEFAULT_LANGUAGE);
  }

  ngOnInit() {
    this.appConfig = AppConfig;
    // subscribe to router event
    this.subscription = this.activatedRoute.queryParams.subscribe((param: any) => {
      const locale = param['locale'];
      if (locale !== undefined) {
        this.translate.use(locale);
      }
    });
    // subscribe to currentModuleSub event to set the current module name in the navbar
    this._globalSub.currentModuleSub.subscribe(module => {
      if (module) {
        this.moduleName = module.module_label;
        this.currentDocUrl = module.module_doc_url;
      } else {
        this.moduleName = 'Accueil';
      }
    });
    // init the sidenav instance in sidebar service
    this._sideNavService.setSideNav(this.sidenav);

    // put the user name in navbar
    this.currentUser = this._authService.getCurrentUser();
  }
  changeLanguage(lang) {
    this.translate.use(lang);
  }

  closeSideBar() {
    this._sideNavService.sidenav.toggle();
  }

  backPage() {
    this._location.back();
  }
  forwardPage() {
    this._location.forward();
  }

  ngOnDestroy() {
    // prevent memory leak by unsubscribing
    this.subscription.unsubscribe();
  }
}
