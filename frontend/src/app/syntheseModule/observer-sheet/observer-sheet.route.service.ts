import { Injectable } from '@angular/core';
import {
  ActivatedRouteSnapshot,
  RouterStateSnapshot,
  Router,
  CanActivateChild,
} from '@angular/router';
import { ConfigService } from '@geonature/services/config.service';
import { TabMediaComponent } from './tab-media/tab-media.component';
import { TabTaxaComponent } from './tab-taxa/tab-taxa.component';
import { ChildRouteDescription } from '@geonature/routing/childRouteDescription';
import { ObservationsComponent } from '../sheets/observations/observations.component';

export function getObserverSheetRoute(observer: string): [string] {
  return [`/synthese/observer/${encodeURIComponent(observer)}`];
}

export const ALL_OBSERVERS_ADVANCED_INFOS_ROUTES: Array<ChildRouteDescription> = [
  {
    label: 'Observations',
    path: 'observations',
    component: ObservationsComponent,
    configEnabledField: null, // make it always available !
  },
  {
    label: 'Taxons',
    path: 'taxa',
    component: TabTaxaComponent,
    configEnabledField: 'ENABLE_TAB_TAXA',
  },
  {
    label: 'Medias',
    path: 'medias',
    component: TabMediaComponent,
    configEnabledField: 'ENABLE_TAB_MEDIA',
  },
];

@Injectable({
  providedIn: 'root',
})
export class ObserverSheetRouteService implements CanActivateChild {
  readonly TAB_LINKS: Array<ChildRouteDescription> = [];
  constructor(
    private _config: ConfigService,
    private _router: Router
  ) {
    if (
      this._config['SYNTHESE']?.['ENABLE_OBSERVER_SHEETS'] &&
      this._config['SYNTHESE']?.['OBSERVER_SHEET']
    ) {
      const config = this._config['SYNTHESE']['OBSERVER_SHEET'];
      this.TAB_LINKS = ALL_OBSERVERS_ADVANCED_INFOS_ROUTES.filter(
        (tab) => !tab.configEnabledField || config[tab.configEnabledField]
      );
    }
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
