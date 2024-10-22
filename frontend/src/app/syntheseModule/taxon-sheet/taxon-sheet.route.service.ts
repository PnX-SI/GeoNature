import { Injectable } from '@angular/core';
import {
  ActivatedRouteSnapshot,
  RouterStateSnapshot,
  Router,
  CanActivateChild,
} from '@angular/router';
import { ConfigService } from '@geonature/services/config.service';
import { Observable } from 'rxjs';
import { TabGeographicOverviewComponent } from './tab-geographic-overview/tab-geographic-overview.component';
import { TabProfileComponent } from './tab-profile/tab-profile.component';

interface Tab {
  label: string;
  path: string;
  configEnabledField?: string;
  component: any;
}

export const ALL_TAXON_SHEET_ADVANCED_INFOS_ROUTES: Array<Tab> = [
  {
    label: 'Synthèse Géographique',
    path: 'geographic_overview',
    component: TabGeographicOverviewComponent,
    configEnabledField: null, // make it always available !
  },
  {
    label: 'Profil',
    path: 'profile',
    configEnabledField: 'ENABLE_PROFILE',
    component: TabProfileComponent,
  },
];

@Injectable({
  providedIn: 'root',
})
export class RouteService implements CanActivateChild {
  readonly TAB_LINKS = [];
  constructor(
    private _config: ConfigService,
    private _router: Router
  ) {
    if (this._config['SYNTHESE']?.['TAXON_SHEET']) {
      const config = this._config['SYNTHESE']['TAXON_SHEET'];
      this.TAB_LINKS = ALL_TAXON_SHEET_ADVANCED_INFOS_ROUTES.filter(
        (tab) => !tab.configEnabledField || config[tab.configEnabledField]
      );
    }
  }

  canActivateChild(
    childRoute: ActivatedRouteSnapshot,
    state: RouterStateSnapshot
  ): Observable<boolean> | Promise<boolean> | boolean {
    const targetedPath = childRoute.routeConfig.path;
    if (this.TAB_LINKS.map((tab) => tab.path).includes(targetedPath)) {
      return true;
    }

    this._router.navigate(['/404'], { skipLocationChange: true });
    return false;
  }
}
