import { Component, NgModule, OnInit, OnDestroy, Inject, ViewChild } from '@angular/core';
import { NavService } from '../../services/nav.service';
import {TranslateService} from '@ngx-translate/core';
import {Router, ActivatedRoute} from '@angular/router';
import { Subscription } from 'rxjs/Subscription';
import { AuthService, User } from '../../components/auth/auth.service';
import {AppConfig} from '../../../conf/app.config';
import 'rxjs/Rx';
import {MatSidenav} from '@angular/material/sidenav';
import { SideNavService } from '../../components/sidenav-items/sidenav.service';
import { Location } from '@angular/common';



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
  @ViewChild('sidenav') public sidenav: MatSidenav;

  constructor(private _navService: NavService,
          private translate: TranslateService,
          private _authService: AuthService,
          private activatedRoute: ActivatedRoute,
          private _sideBarService: SideNavService,
          private _location: Location) {

    translate.addLangs(['en', 'fr', 'cn']);
    translate.setDefaultLang(AppConfig.defaultLanguage);
    translate.use(AppConfig.defaultLanguage);
  }


  ngOnInit() {
    this.appConfig = AppConfig;
    // subscribe to router event
    this.subscription = this.activatedRoute.queryParams.subscribe(
      (param: any) => {
        const locale = param['locale'];
        if (locale !== undefined) {
            this.translate.use(locale);
        }
      });
      // subscribe to the app name
      this._navService.gettingCurrentModule.subscribe(module => {
        this.moduleName = module.moduleName;
    });
    // init the sidenav instance in sidebar service
    this._sideBarService.setSideNav(this.sidenav);

    // put the user name in navbar    
    this.currentUser = this._authService.getCurrentUser();
  }
  changeLanguage(lang) {
    this.translate.use(lang);
}

  closeSideBar() {
    this._sideBarService.sidenav.toggle();
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
