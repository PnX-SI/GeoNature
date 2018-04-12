import { Injectable } from '@angular/core';
import { Subject } from 'rxjs/Subject';
import { MatSidenavModule, MatSidenav } from '@angular/material/sidenav';
import { HttpClient } from '@angular/common/http';
import { AppConfig } from '@geonature_config/app.config';

@Injectable()
export class SideNavService {
  sidenav: MatSidenav;
  opened: boolean;
  private _module = new Subject<any>();
  public currentModule: any;
  gettingCurrentModule = this._module.asObservable();
  // List of the apps
  public modules: Array<any>;
  public home;

  constructor(private _api: HttpClient) {
    this.opened = false;
    this.home = { module_url: '/', module_name: 'Accueil', module_picto: 'home', id: '1' };
  }

  getModules() {
    return this._api.get<any>(`${AppConfig.API_ENDPOINT}/gn_commons/modules`);
  }

  setSideNav(sidenav) {
    this.sidenav = sidenav;
  }
  setModule(sidenav: MatSidenav) {
    sidenav.close();
  }
  setHome(sidenav: MatSidenav) {
    sidenav.open();
  }

  setCurrentApp(app): any {
    this.currentModule = app;
    this._module.next(app);
  }

  getCurrentApp() {
    return this.currentModule;
  }
  getAppList(): any {
    return this.modules;
  }
}
