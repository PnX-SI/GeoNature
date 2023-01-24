import { Component, OnInit } from '@angular/core';
import { ConfigService } from '@geonature/services/config.service';
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
  public version = null;
  public home_page: any;
  public exportModule: any;

  constructor(
    public moduleService: ModuleService,
    public _sidenavService: SideNavService,
    public cs: ConfigService
  ) {
    this.version = this.cs.GEONATURE_VERSION;
  }

  ngOnInit() {
    this.home_page = this._sidenavService.getHomeItem();
  }

  setHome() {
    this.moduleService.currentModule$.next(null);
  }
}
