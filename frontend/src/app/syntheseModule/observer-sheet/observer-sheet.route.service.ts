import { Injectable } from '@angular/core';
import {
  ActivatedRouteSnapshot,
  RouterStateSnapshot,
  Router,
  CanActivate,
  CanActivateChild,
} from '@angular/router';
import { ConfigService } from '@geonature/services/config.service';
import { TabObservationsComponent } from './tab-observations/tab-observations.component';
import { TabMediaComponent } from './tab-media/tab-media.component';
import { TabOverviewComponent } from './tab-overview/tab-overview.component';
import { ObserverSheetService } from './observer-sheet.service';
import { Observable, of, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { HttpErrorResponse } from '@angular/common/http';
import { ChildRouteDescription, navigateToFirstAvailableChild } from '@geonature/routing/childRouteDescription';

export const ALL_OBSERVERS_ADVANCED_INFOS_ROUTES: Array<ChildRouteDescription> = [
  {
    label: 'Observations',
    path: 'observations',
    component: TabObservationsComponent,
    configEnabledField: 'ENABLE_TAB_OBSERVATIONS',
  },
  {
    label: 'Overview',
    path: 'overview',
    component: TabOverviewComponent,
    configEnabledField: 'ENABLE_TAB_OVERVIEW',
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
    private _router: Router,
    private _observerSheetService: ObserverSheetService
  ) {
    if (this._config['SYNTHESE']?.['OBSERVER_SHEET']) {
      const config = this._config['SYNTHESE']['OBSERVER_SHEET'];
      this.TAB_LINKS = ALL_OBSERVERS_ADVANCED_INFOS_ROUTES.filter(
        (tab) => !tab.configEnabledField || config[tab.configEnabledField]
      );
    }
  }

  _isRootLevelRoute(route: ActivatedRouteSnapshot, state: RouterStateSnapshot): boolean {
    return state.url.endsWith(route.params.id_role);
  }

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot): Observable<boolean> {
    if (!this._config.SYNTHESE.ENABLE_OBSERVER_SHEETS) {
      this._router.navigate(['/404'], { skipLocationChange: true });
      return of(false);
    }
    const id_role = route.params.id_role ?? -1;
    this._observerSheetService
      .fetchObserver(id_role)
      .pipe(
        catchError((error: HttpErrorResponse) => {
          this._router.navigate(['/404'], { skipLocationChange: true });
          return throwError(error);
        })
      )
      .subscribe((observer) => {
        // Verify that observer is valid (i.e: not a group)
        const isValidObserver = !observer['groupe'];
        // invalid -- 404
        if (!isValidObserver) {
          this._router.navigate(['/404'], { skipLocationChange: true });
          return false;
        }
        // valid
        else {
          if (this._isRootLevelRoute(route, state)) {
            return !navigateToFirstAvailableChild(route, state, this._router, this.TAB_LINKS);
          }
        }
        return true;
      });
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
