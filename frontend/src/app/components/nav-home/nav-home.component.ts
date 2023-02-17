
import { ActivatedRoute, Router } from '@angular/router';
import { Component, OnInit, ViewChild, Inject } from '@angular/core';

import { MatSidenav } from '@angular/material/sidenav';

import { AuthService, User } from '../../components/auth/auth.service';
import { SideNavService } from '../sidenav-items/sidenav-service';
import { ModuleService } from '../../services/module.service';
import { NotificationDataService } from '@geonature/components/notification/notification-data.service';
import { ConfigService } from '@geonature/services/config.service';
import { LocaleService } from '../../services/locale.service';

@Component({
  selector: 'pnx-nav-home',
  templateUrl: './nav-home.component.html',
  styleUrls: ['./nav-home.component.scss'],
})
export class NavHomeComponent implements OnInit {
  public moduleName = 'Accueil';
  public currentUser: User;
  public currentDocUrl: string;
  public locale: string;
  public moduleUrl: string;
  public notificationNumber: number;

  @ViewChild('sidenav', { static: true }) public sidenav: MatSidenav;

  constructor(
    public authService: AuthService,
    public sideNavService: SideNavService,
    private _moduleService: ModuleService,
    private notificationDataService: NotificationDataService,
    public config: ConfigService,
    private router: Router,
    private localeService: LocaleService
  ) {}

  ngOnInit() {
    // Subscribe to router event
    this.loadLocale();

    // Set the current module name in the navbar
    this.onModuleChange();

    // Init the sidenav instance in sidebar service
    this.sideNavService.setSideNav(this.sidenav);

    // Put the user name in navbar
    this.currentUser = this.authService.getCurrentUser();
  }

  private loadLocale() {
    this.locale = this.localeService.currentLocale;
  }

  changeLanguage(lang) {
    this.localeService.setLocale(lang);
    this.locale = lang;
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
