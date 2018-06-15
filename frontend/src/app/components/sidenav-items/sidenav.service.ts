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
  public home_page;
  public export_module;

  constructor(private _api: HttpClient) {
    this.opened = false;
    this.home_page = { module_url: '/', module_label: 'Accueil', module_picto: 'home', id: '1' };

<<<<<<< HEAD
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
=======
    this.export_module = {
      module_url: '/exports',
      module_label: 'Export',
      module_picto: 'file_download',
      id: '2'
    };
  }

  fetchModules() {
    return this._api.get<any>(`${AppConfig.API_ENDPOINT}/gn_commons/modules`);
  }

  setModulesLocalStorage(modules) {
    localStorage.setItem('modules', JSON.stringify(modules));
  }

  getModules(id_module) {
    const modules = localStorage.getItem('modules');
    let searchModule = null;
    if (modules) {
      JSON.parse(modules).forEach(mod => {
        if (mod.id_module === id_module) {
          searchModule = mod;
        }
      });
    }
    return searchModule;
>>>>>>> origin/develop
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
