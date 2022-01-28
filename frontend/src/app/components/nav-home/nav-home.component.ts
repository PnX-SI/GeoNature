
import { ActivatedRoute, Router } from '@angular/router';
import { Component, OnInit, OnDestroy, ViewChild } from '@angular/core';
import { MatSidenav } from '@angular/material/sidenav';

import { Subscription } from 'rxjs';
import { TranslateService } from '@ngx-translate/core';

import { AuthService, User } from '../../components/auth/auth.service';
import { AppConfig } from '../../../conf/app.config';
import { SideNavService } from '../sidenav-items/sidenav-service';
import { NavHomeService } from './nav-home.service';


@Component({
  selector: 'pnx-nav-home',
  templateUrl: './nav-home.component.html',
  styleUrls: ['./nav-home.component.scss']
})
export class NavHomeComponent implements OnInit, OnDestroy {

  public moduleName = 'Accueil';
  private subscription: Array<Subscription> = [];
  public currentUser: User;
  public appConfig: any;
  public currentDocUrl: string;
  public locale: string;
  @ViewChild('sidenav', {static: true}) public sidenav: MatSidenav;

  constructor(
    private translateService: TranslateService,
    public authService: AuthService,
    private activatedRoute: ActivatedRoute,
    public sideNavService: SideNavService,
    private router: Router,
    public navHomeService: NavHomeService,
  ) {}

  ngOnInit() {
      // Inject App config to use in the template
    this.appConfig = AppConfig;

    // Subscribe to router event
    this.extractLocaleFromUrl();

    // Init the sidenav instance in sidebar service
    this.sideNavService.setSideNav(this.sidenav);

    // Put the user name in navbar
    this.currentUser = this.authService.getCurrentUser();
  }


  private extractLocaleFromUrl() {
    this.subscription.push(
      this.activatedRoute.queryParams.subscribe((param: any) => {
        const locale = param['locale'];
        if (locale !== undefined) {
          this.defineLanguage(locale);
        } else {
          this.locale = this.translateService.getDefaultLang();
        }
      })
    )
  }

  changeLanguage(lang) {
    this.defineLanguage(lang);
    const prev = this.router.url;
    this.router.navigate(['/']).then(data => {
      this.router.navigate([prev]);
    });
  }

  private defineLanguage(lang) {
    this.locale = lang;
    this.translateService.use(lang);
    this.translateService.setDefaultLang(lang);
  }

  closeSideBar() {
    this.sideNavService.sidenav.toggle();
  }

  ngOnDestroy() {    
    // Prevent memory leak by unsubscribing
    this.subscription.forEach(s => {
      s.unsubscribe();
    })
  }
}
