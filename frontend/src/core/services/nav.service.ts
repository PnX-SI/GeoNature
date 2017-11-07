import { Injectable, OnInit } from '@angular/core';
import { Subject } from 'rxjs/Subject';

@Injectable()
export class NavService {
    // Observable string sources
    private _app = new Subject<any>();
    public currentApp: any;
    gettingCurrentApp = this._app.asObservable();
    // List of the apps
    private _nav = [{}];
    constructor() {
        this._nav = [{route: '/', appName: 'Accueil', icon: 'home', id:'1'},
            // {route: '/synthese', appName: 'Synthèse', icon: 'device_hub', id:'2'},
            {route: '/occtax', appName: 'OccTax', icon: 'visibility', id: '14'},
            // {route: '/flore-station', appName: 'Flore Station', icon: 'local_florist', id: '15'},
            // {route: '/suivi-flore', appName: 'Suivi Flore', icon: 'filter_vintage', id: '16'},
            // {route: '/suivi-chiro', appName: 'Suivi Chiro', icon: 'youtube_searched_for', id: '17'},
            {route: '/exports', appName: 'Exports', icon: 'cloud_download', id: '18'},
            // {route: '/prospections', appName: 'Prospections', icon: 'feedback', id: '19'},
            // {route: '/parametres', appName: 'Paramètres', icon: 'settings', id: '20'}
            ];
  }

    setCurrentApp(app): any {
      this.currentApp = app;
      this._app.next(app);
    }

    getCurrentApp() {
      return this.currentApp;
    }
    getAppList(): any {
      return this._nav;
    }
}
