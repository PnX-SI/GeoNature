import { Injectable } from '@angular/core';
import {
  CanActivate,
  ActivatedRouteSnapshot,
  RouterStateSnapshot,
  Router,
  ActivatedRoute,
  CanActivateChild,
} from '@angular/router';
import { ConfigService } from '@geonature/services/config.service';
import { Observable } from 'rxjs';
import { TabGeographicOverviewComponent } from './tab-geographic-overview/tab-geographic-overview.component';
import { TabProfileComponent } from './tab-profile/tab-profile.component';

interface Tab {
  label: string;
  path: string;
  configEntry: string;
  component: any;
}

const ROUTE_GEOGRAPHIC_OVERVIEW: Tab = {
  label: 'Synthèse Géographique',
  path: 'geographic_overview',
  configEntry: 'GEOGRAPHIC_OVERVIEW',
  component: TabGeographicOverviewComponent,
};

export const ROUTE_MANDATORY = ROUTE_GEOGRAPHIC_OVERVIEW;

const ROUTE_PROFILE: Tab = {
  label: 'Profil',
  path: 'profile',
  configEntry: 'PROFILE',
  component: TabProfileComponent,
};

export const ALL_TAXON_SHEET_ADVANCED_INFOS_ROUTES: Array<Tab> = [
  ROUTE_GEOGRAPHIC_OVERVIEW,
  ROUTE_PROFILE,
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
    this.TAB_LINKS.push(ROUTE_MANDATORY);
    if (this._config && this._config['SYNTHESE'] && this._config['SYNTHESE']['SPECIES_SHEET']) {
      const config = this._config['SYNTHESE']['SPECIES_SHEET'];
      if (config['PROFILE'] && config['PROFILE']['ENABLED']) {
        this.TAB_LINKS.push(ROUTE_PROFILE);
      }
    }
  }

  canActivateChild(
    childRoute: ActivatedRouteSnapshot,
    state: RouterStateSnapshot
  ): Observable<boolean> | Promise<boolean> | boolean {
    const targetedPath = childRoute.routeConfig.path;
    if (ROUTE_MANDATORY.path == targetedPath) {
      return true;
    }
    const targetedTab = ALL_TAXON_SHEET_ADVANCED_INFOS_ROUTES.find(
      (tab) => tab.path === targetedPath
    );
    if (this._config && this._config['SYNTHESE'] && this._config['SYNTHESE']['SPECIES_SHEET']) {
      const config = this._config['SYNTHESE']['SPECIES_SHEET'];
      if (config[targetedTab.configEntry] && config[targetedTab.configEntry]['ENABLED']) {
        return true;
      }
    }

    this._router.navigate(['/404'], { skipLocationChange: true });
    return false;
  }
}
