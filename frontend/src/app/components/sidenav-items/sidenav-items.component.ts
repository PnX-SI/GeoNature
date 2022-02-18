import { Component, OnInit } from '@angular/core';
import { GlobalSubService } from '../../services/global-sub.service';
import { ModuleService } from '../../services/module.service';
import { SideNavService } from './sidenav-service';
import { ConfigService } from '@geonature/services/config.service';
@Component({
  selector: 'pnx-sidenav-items',
  templateUrl: './sidenav-items.component.html',
  styleUrls: ['./sidenav-items.component.scss']
})
export class SidenavItemsComponent implements OnInit {
  public nav = [{}];
  public appConfig: any;
  public version;
  public home_page: any;
  public exportModule: any;

  constructor(
    public globalSub: GlobalSubService,
    public moduleService: ModuleService,
    public _sidenavService: SideNavService,
    public configService: ConfigService
  ) {
    this.appConfig = this.configService.config;
    this.version = this.appConfig.GEONATURE_VERSION
  }

  ngOnInit() {
    this.home_page = { module_url: '/', module_label: 'Accueil', module_picto: 'fa-home', id: '1' };
  }

  setHome() {
    this.globalSub.currentModuleSubject.next(null);
  }
}
