import { Injectable } from '@angular/core';
import { MatSidenav } from '@angular/material/sidenav';
import { Module } from '@geonature/models/module.model';
import { Subject } from 'rxjs';

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
  public exportModule;

  constructor() {
    this.opened = false;
  }

  setSideNav(sidenav: MatSidenav) {
    this.sidenav = sidenav;
  }

  setHome(sidenav: MatSidenav) {
    sidenav.open();
  }

  getCurrentApp() {
    return this.currentModule;
  }

  getHomeItem(): Module {
    let abs_path = '/';
    if (window.location.pathname) {
      // for GeoNature URL like https://demo.geonature.fr/geonature/
      abs_path = window.location.pathname;
    }
    return {
      module_url: abs_path,
      module_label: 'Accueil',
      module_picto: 'fa-home',
      id_module: 1,
      module_path: '/geonature',
    };
  }

  toggleSideNav() {
    this.sidenav.toggle();
  }
}
