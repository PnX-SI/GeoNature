import { Injectable } from '@angular/core';
import {
  ActivatedRouteSnapshot,
  RouterStateSnapshot,
  Router,
  CanActivateChild,
  CanActivate,
} from '@angular/router';
import { ConfigService } from '@geonature/services/config.service';
import { TabGeographicOverviewComponent } from './tab-geographic-overview/tab-geographic-overview.component';
import { TabProfileComponent } from './tab-profile/tab-profile.component';
import { TabTaxonomyComponent } from './tab-taxonomy/tab-taxonomy.component';
import { TabMediaComponent } from './tab-media/tab-media.component';
import { TabObserversComponent } from './tab-observers/tab-observers.component';

interface Tab {
  label: string;
  path: string;
  configEnabledField?: string;
  component: any;
}

export const ALL_TAXON_SHEET_ADVANCED_INFOS_ROUTES: Array<Tab> = [
  {
    label: 'Synthèse géographique',
    path: 'geographic_overview',
    component: TabGeographicOverviewComponent,
    configEnabledField: null, // make it always available !
  },
  {
    label: 'Taxonomie',
    path: 'taxonomy',
    configEnabledField: 'ENABLE_TAB_TAXONOMY',
    component: TabTaxonomyComponent,
  },
  {
    label: 'Médias',
    path: 'media',
    configEnabledField: 'ENABLE_TAB_MEDIA',
    component: TabMediaComponent,
  },
  {
    label: 'Profil',
    path: 'profile',
    configEnabledField: 'ENABLE_TAB_PROFILE',
    component: TabProfileComponent,
  },
  {
    label: 'Observateurs',
    path: 'observers',
    configEnabledField: 'ENABLE_TAB_OBSERVERS',
    component: TabObserversComponent,
  },
];

@Injectable({
  providedIn: 'root',
})
export class RouteService implements CanActivate, CanActivateChild {
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
  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot): boolean {
    if (!this._config.SYNTHESE.ENABLE_TAXON_SHEETS) {
      this._router.navigate(['/404'], { skipLocationChange: true });
      return false;
    }

    return true;
  }

  canActivateChild(childRoute: ActivatedRouteSnapshot, state: RouterStateSnapshot): boolean {
    const targetedPath = childRoute.routeConfig.path;
    if (this.TAB_LINKS.map((tab) => tab.path).includes(targetedPath)) {
      return true;
    }

    this._router.navigate(['/404'], { skipLocationChange: true });
    return false;
  }
}
