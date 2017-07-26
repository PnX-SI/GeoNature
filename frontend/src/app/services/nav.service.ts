import { Injectable, OnInit } from '@angular/core';
import { Subject } from 'rxjs/Subject';

@Injectable()
export class NavService {
    // Observable string sources
    private _appName = new Subject<string>();
    gettingAppName = this._appName.asObservable();
    // List of the apps
    private _nav = [{}];
    constructor() {
        this._nav = [{route: '/accueil', appName: 'Accueil', icon: 'home'},
            {route: '/synthese', appName: 'Synthèse', icon: 'assessment'},
            {route: '/contact-faune', appName: 'Contact Faune', icon: 'pets'},
            {route: '/contact-flore', appName: 'Contact Flore', icon: 'filter_vintage'},
            {route: '/flore-station', appName: 'Flore Station', icon: 'local_florist'},
            {route: '/suivi-flore', appName: 'Suivi Flore', icon: 'visibility'},
            {route: '/parametres', appName: 'Paramètres', icon: 'settings'},
            {route: '/suivi-chiro', appName: 'Suivi Chiro', icon: 'youtube_searched_for'},
            {route: '/exports', appName: 'Exports', icon: 'cloud_download'},
            {route: '/prospections', appName: 'Prospections', icon: 'feedback'}
            ];
  }

    setAppName(appName: string): any {
      this._appName.next(appName);
    }

    getAppList(): any {
      return this._nav;
    }
}
