import { Component, OnInit } from '@angular/core';
import { ConfigService } from '@geonature/utils/configModule/core';
import { GlobalSubService } from '../../services/global-sub.service';
import { ModuleService } from '../../services/module.service';
import { SideNavService } from './sidenav-service';

@Component({
  selector: 'pnx-sidenav-items',
  templateUrl: './sidenav-items.component.html',
  styleUrls: ['./sidenav-items.component.css']
})
export class SidenavItemsComponent implements OnInit {
  public nav = [{}];
  public appConfig: any;
  public version: any;
  public home_page: any;
  public exportModule: any;

  constructor(
    public globalSub: GlobalSubService,
    public moduleService: ModuleService,
    public _sidenavService: SideNavService,
    private _configService: ConfigService,
  ) {
    this.appConfig = this._configService.getSettings();
    this.version = this.appConfig.GEONATURE_VERSION;

  }

  ngOnInit() {
    this.home_page = { module_url: '/', module_label: 'Accueil', module_picto: 'fa-home', id: '1' };
  }

  setHome() {
    this.globalSub.currentModuleSubject.next(null);
  }
}
