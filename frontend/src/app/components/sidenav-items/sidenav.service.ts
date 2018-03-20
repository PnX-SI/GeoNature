import { Injectable } from '@angular/core';
import { Subject } from 'rxjs/Subject';
import { MatSidenavModule, MatSidenav } from '@angular/material/sidenav';

@Injectable()
export class SideNavService {
  sidenav: MatSidenav;
  opened: boolean;
  private _module = new Subject<any>();
  public currentModule: any;
  gettingCurrentModule = this._module.asObservable();
  // List of the apps
  private _nav = [{}];

  constructor() {
    this.opened = false;

    this._nav = [
      { route: '/', moduleName: 'Accueil', icon: 'home', id: '1' },
      {route: '/synthese', moduleName: 'Synthèse', icon: 'device_hub', id:'2'},
      { route: '/occtax', moduleName: 'OccTax', icon: 'visibility', id: '14' },
      // {route: '/flore-station', moduleName: 'Flore Station', icon: 'local_florist', id: '15'},
      // {route: '/suivi-flore', moduleName: 'Suivi Flore', icon: 'filter_vintage', id: '16'},
      // {route: '/suivi-chiro', moduleName: 'Suivi Chiro', icon: 'youtube_searched_for', id: '17'},
      { route: '/exports', moduleName: 'Exports', icon: 'cloud_download', id: '18' },
      { route: '/validation', moduleName: 'validation', icon: 'cloud_download', id: '22' }
      // {route: '/prospections', moduleName: 'Prospections', icon: 'feedback', id: '19'},
      // {route: '/parametres', moduleName: 'Paramètres', icon: 'settings', id: '20'}
    ];
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
    return this._nav;
  }
}
