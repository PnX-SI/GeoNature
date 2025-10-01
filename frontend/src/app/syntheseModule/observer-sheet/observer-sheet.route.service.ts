import { Injectable } from '@angular/core';
import {
  ActivatedRouteSnapshot,
  RouterStateSnapshot,
  Router,
  CanActivate,
  CanActivateChild,
} from '@angular/router';
import { ConfigService } from '@geonature/services/config.service';
import { TabGeographicOverviewComponent } from './tab-geographic-overview/tab-geographic-overview.component';
import { TabMediaComponent } from './tab-media/tab-media.component';
import { TabDescription } from '@geonature_common/layouts/tabs-layout/tabs-layout.component';
import { TabLAstObservationsComponent } from './tab-last-observations/tab-last-observations.component';

export const ALL_OBSERVERS_ADVANCED_INFOS_ROUTES: Array<TabDescription> = [
  {
    label: 'Synthèse géographique',
    path: 'geographic_overview',
    component: TabGeographicOverviewComponent,
    configEnabledField: null, // make it always available !
  },
  {
    label: 'Dernières observations',
    path: 'last_observations',
    component: TabLAstObservationsComponent,
    configEnabledField: null, // make it always available !
  },
  {
    label: 'Medias',
    path: 'medias',
    component: TabMediaComponent,
    configEnabledField: 'ENABLE_TAB_MEDIA', // make it always available !
  },
];

@Injectable({
  providedIn: 'root',
})
export class ObserverSheetRouteService implements CanActivate, CanActivateChild {
  readonly TAB_LINKS = [];
  constructor(
    private _config: ConfigService,
    private _router: Router
  ) {
    if (this._config['SYNTHESE']?.['OBSERVER_SHEET']) {
      const config = this._config['SYNTHESE']['OBSERVER_SHEET'];
      this.TAB_LINKS = ALL_OBSERVERS_ADVANCED_INFOS_ROUTES.filter(
        (tab) => !tab.configEnabledField || config[tab.configEnabledField]
      );
    }
  }
  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot): boolean {
    if (!this._config.SYNTHESE.ENABLE_OBSERVER_SHEETS) {
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
