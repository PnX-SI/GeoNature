import { ActivatedRoute, Router } from '@angular/router';
import { Component, OnInit, OnDestroy, ViewChild } from '@angular/core';
import { MatSidenav } from '@angular/material/sidenav';

import { Subscription } from 'rxjs';
import { TranslateService } from '@ngx-translate/core';

import { AuthService, User } from '../../components/auth/auth.service';
import { SideNavService } from '../sidenav-items/sidenav-service';
import { ModuleService } from '../../services/module.service';
import { NotificationDataService } from '@geonature/components/notification/notification-data.service';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'pnx-nav-home',
  templateUrl: './nav-home.component.html',
  styleUrls: ['./nav-home.component.scss'],
})
export class NavHomeComponent implements OnInit, OnDestroy {
  public moduleName = 'Accueil';
  private subscription: Subscription;
  public currentUser: User;
  public currentDocUrl: string;
  public locale: string;
  public moduleUrl: string;
  public notificationNumber: number;
  public useLocalProvider: boolean; // Indicate if the user is logged in using a non local provider

  @ViewChild('sidenav', { static: true }) public sidenav: MatSidenav;

  constructor(
    private translateService: TranslateService,
    public authService: AuthService,
    private activatedRoute: ActivatedRoute,
    public sideNavService: SideNavService,
    private _moduleService: ModuleService,
    private notificationDataService: NotificationDataService,
    private router: Router,
    public config: ConfigService
  ) {}

  ngOnInit() {
    // Subscribe to router event
    this.extractLocaleFromUrl();

    // Set the current module name in the navbar
    this.onModuleChange();

    // Init the sidenav instance in sidebar service
    this.sideNavService.setSideNav(this.sidenav);

    // Put the user name in navbar
    this.currentUser = this.authService.getCurrentUser();
    this.useLocalProvider = this.authService.canBeLoggedWithLocalProvider();
  }

  private extractLocaleFromUrl() {
    this.subscription = this.activatedRoute.queryParams.subscribe((param: any) => {
      const locale = param['locale'];
      if (locale !== undefined) {
        this.defineLanguage(locale);
      } else {
        this.locale = this.translateService.getDefaultLang();
      }
    });
  }

  changeLanguage(lang) {
    this.defineLanguage(lang);
    const prev = this.router.url;
    this.router.navigate(['/']).then((data) => {
      this.router.navigate([prev]);
    });
  }

  private defineLanguage(lang) {
    this.locale = lang;
    this.translateService.use(lang);
    this.translateService.setDefaultLang(lang);
  }

  private onModuleChange() {
    this._moduleService.currentModule$.subscribe((module) => {
      if (!module) {
        // If in Home Page
        module = this.sideNavService.getHomeItem();
        module.module_doc_url = this._moduleService.geoNatureModule.module_doc_url;
      }
      this.moduleName = module.module_label;
      this.moduleUrl = module.module_url;
      if (module.module_doc_url) {
        this.currentDocUrl = module.module_doc_url;
      }
    });
    if (this.config.NOTIFICATIONS_ENABLED == true) {
      // Update notification count to display in badge
      this.updateNotificationCount();
    }
  }

  closeSideBar() {
    this.sideNavService.sidenav.toggle();
    if (this.config.NOTIFICATIONS_ENABLED == true) {
      // Update notification count to display in badge
      this.updateNotificationCount();
    }
  }

  private updateNotificationCount() {
    this.notificationDataService.getNotificationsNumber().subscribe((count) => {
      this.notificationNumber = count;
    });
  }

  openNotification() {
    this.updateNotificationCount();
    this.router.navigate(['/notification']);
  }

  ngOnDestroy() {
    // Prevent memory leak by unsubscribing
    this.subscription.unsubscribe();
  }
}
