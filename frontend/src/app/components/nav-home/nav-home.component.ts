import { Router } from '@angular/router';
import { Component, OnInit, ViewChild } from '@angular/core';
import { MatSidenav } from '@angular/material/sidenav';

import { TranslateService } from '@ngx-translate/core';

import { AuthService, User } from '../../components/auth/auth.service';
import { SideNavService } from '../sidenav-items/sidenav-service';
import { ModuleService } from '../../services/module.service';
import { NotificationDataService } from '@geonature/components/notification/notification-data.service';
import { ConfigService } from '@geonature/services/config.service';
import { I18nService } from '@geonature/shared/translate/i18n-service';

@Component({
  selector: 'pnx-nav-home',
  templateUrl: './nav-home.component.html',
  styleUrls: ['./nav-home.component.scss'],
})
export class NavHomeComponent implements OnInit {
  public moduleName = 'Accueil';
  public currentUser: User;
  public currentDocUrl: string;
  public moduleUrl: string;
  public notificationNumber: number;
  public useLocalProvider: boolean; // Indicate if the user is logged in using a non local provider

  @ViewChild('sidenav', { static: true }) public sidenav: MatSidenav;

  constructor(
    private translateService: TranslateService,
    public authService: AuthService,
    public sideNavService: SideNavService,
    private _moduleService: ModuleService,
    private notificationDataService: NotificationDataService,
    private router: Router,
    public config: ConfigService,
    public i18nService: I18nService
  ) {}

  get locale(): string {
    return this.i18nService.currentLang;
  }

  ngOnInit() {
    // Set the current module name in the navbar
    this.onModuleChange();

    // Init the sidenav instance in sidebar service
    this.sideNavService.setSideNav(this.sidenav);

    // Put the user name in navbar
    this.currentUser = this.authService.getCurrentUser();
    this.useLocalProvider = this.authService.canBeLoggedWithLocalProvider();
  }

  changeLanguage(lang) {
    this.translateService.use(lang);
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
}
