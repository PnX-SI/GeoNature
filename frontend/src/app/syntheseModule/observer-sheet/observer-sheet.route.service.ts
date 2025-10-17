import { Injectable } from '@angular/core';
import {
  ActivatedRouteSnapshot,
  RouterStateSnapshot,
  Router,
  CanActivate,
  CanActivateChild,
} from '@angular/router';
import { ConfigService } from '@geonature/services/config.service';
import { TabMediaComponent } from './tab-media/tab-media.component';
import { TabOverviewComponent } from './tab-overview/tab-overview.component';
import { Observable, of, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { HttpErrorResponse } from '@angular/common/http';
import { ChildRouteDescription } from '@geonature/routing/childRouteDescription';
import { ObservationsComponent } from '../sheets/observations/observations.component';
import { UserDataService } from '@geonature/userModule/services';

export const ALL_OBSERVERS_ADVANCED_INFOS_ROUTES: Array<ChildRouteDescription> = [
  {
    label: 'Observations',
    path: 'observations',
    component: ObservationsComponent,
    configEnabledField: null, // make it always available !
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
    configEnabledField: 'ENABLE_TAB_MEDIA',
  },
];

export const ID_ROLE_PARAM_NAME = 'id_role';

@Injectable({
  providedIn: 'root',
})
export class ObserverSheetRouteService implements CanActivate, CanActivateChild {
  readonly TAB_LINKS: Array<ChildRouteDescription> = [];
  constructor(
    private _config: ConfigService,
    private _router: Router,
    private _userDataService: UserDataService
  ) {
    if (this._config['SYNTHESE']?.['OBSERVER_SHEET']) {
      const config = this._config['SYNTHESE']['OBSERVER_SHEET'];
      this.TAB_LINKS = ALL_OBSERVERS_ADVANCED_INFOS_ROUTES.filter(
        (tab) => !tab.configEnabledField || config[tab.configEnabledField]
      );
    }
  }

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot): Observable<boolean> {
    if (!this._config.SYNTHESE.ENABLE_OBSERVER_SHEETS) {
      this._router.navigate(['/404'], { skipLocationChange: true });
      return of(false);
    }
    const id_role = route.params[ID_ROLE_PARAM_NAME] ?? -1;
    this._userDataService
      .getRole(id_role)
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
