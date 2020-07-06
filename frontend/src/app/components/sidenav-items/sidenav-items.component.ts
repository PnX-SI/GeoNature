import { Component, OnInit } from '@angular/core';
import { AppConfig } from '@geonature_config/app.config';
import { GlobalSubService } from '../../services/global-sub.service';
import { ModuleService } from '../../services/module.service';
import { SideNavService } from './sidenav-service';

@Component({
  selector: 'pnx-sidenav-items',
  templateUrl: './sidenav-items.component.html',
  styleUrls: ['./sidenav-items.component.scss'],
})
export class SidenavItemsComponent implements OnInit {
  public nav = [{}];
  public appConfig: any;
  public version = AppConfig.GEONATURE_VERSION;
  public home_page: any;
  public exportModule: any;

  constructor(
    public globalSub: GlobalSubService,
    public moduleService: ModuleService,
    public _sidenavService: SideNavService
  ) { }

  ngOnInit() {
    this.home_page = { module_url: '/', module_label: 'Accueil', module_picto: 'fa-home', id: '1' };
    if (!this.moduleService.modules) {
      this.moduleService.fetchModules();
    }
  }

  setHome() {
    this.globalSub.currentModuleSubject.next(null);
  }
}
