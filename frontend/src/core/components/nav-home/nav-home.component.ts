import { Component, NgModule, OnInit, OnDestroy, Inject, ViewChild } from '@angular/core';
import { NavService } from '../../services/nav.service';
import {TranslateService} from '@ngx-translate/core';
import {Router, ActivatedRoute} from '@angular/router';
import { Subscription } from 'rxjs/Subscription';
import * as firebase from 'firebase';
import { AuthService } from '../../components/auth/auth.service';
import {AppConfig} from '../../../conf/app.config';
import 'rxjs/Rx';
import {MdSidenavModule, MdSidenav} from '@angular/material';
import { SideNavService } from '../../components/sidenav-items/sidenav.service';
import { Location } from '@angular/common';



@Component({
  selector: 'pnx-nav-home',
  templateUrl: './nav-home.component.html',
  styleUrls: ['./nav-home.component.scss'],
  providers: [{ provide: AppConfig, useValue: AppConfig }]
})

export class NavHomeComponent implements OnInit, OnDestroy {
  public appName: string;
  private subscription: Subscription;
  @ViewChild('sidenav') public sidenav: MdSidenav;

  // tslint:disable-next-line:max-line-length
  constructor(private _navService: NavService,
          private translate: TranslateService,
          public authService: AuthService,
          private activatedRoute: ActivatedRoute,
          private _sideBarService: SideNavService,
          private _location: Location) {
      _navService.gettingAppName.subscribe(ms => {
        this.appName = ms;

    });

    translate.addLangs(['en', 'fr', 'cn']);
    translate.setDefaultLang(AppConfig.defaultLanguage);
    translate.use(AppConfig.defaultLanguage);
  }


  ngOnInit() {
    // subscribe to router event
    this.subscription = this.activatedRoute.queryParams.subscribe(
      (param: any) => {
        const locale = param['locale'];
        if (locale !== undefined) {
            this.translate.use(locale);
        }
      });
    // init firebase
    // firebase.initializeApp({
    //   apiKey: 'AIzaSyBHvJhaMQdEFI0kM6LNagcFTQQWiDFCsOo',
    //   authDomain: 'geonature-a568d.firebaseapp.com',
    // });

    // init the sidenav instance in sidebar service
    this._sideBarService.setSideNav(this.sidenav);
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
