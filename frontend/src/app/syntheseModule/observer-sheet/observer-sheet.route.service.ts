import { Injectable } from '@angular/core';
import {
  ActivatedRouteSnapshot,
  RouterStateSnapshot,
  Router,
  CanActivateChild,
  CanActivate,
} from '@angular/router';
import { Observable, of, throwError } from 'rxjs';
import { catchError, map, tap } from 'rxjs/operators';
import { ConfigService } from '@geonature/services/config.service';
import { TabMediaComponent } from './tab-media/tab-media.component';
import { TabTaxaComponent } from './tab-taxa/tab-taxa.component';
import { ChildRouteDescription } from '@geonature/routing/childRouteDescription';
import { ObservationsComponent } from '../sheets/observations/observations.component';
import { ObserverSheetService } from './observer-sheet.service';
import { Observer } from './observer';
import { AuthService } from '@geonature/components/auth/auth.service';

export function getObserverSheetRoute(observer: string): [string] {
  return [`/synthese/observer/${encodeURIComponent(observer)}`];
}

export const ALL_OBSERVERS_ADVANCED_INFOS_ROUTES: Array<ChildRouteDescription> = [
  {
    label: 'Observations',
    path: 'observations',
    component: ObservationsComponent,
    configEnabledField: 'ENABLE_TAB_OBSERVATIONS',
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
export class ObserverSheetRouteService implements CanActivate, CanActivateChild {
  readonly TAB_LINKS: Array<ChildRouteDescription> = [];
  constructor(
    private _config: ConfigService,
    private _router: Router,
    private _oss: ObserverSheetService,
    private _authService: AuthService
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

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot): Observable<boolean> {
    if (!this._config['SYNTHESE']?.['ENABLE_OBSERVER_SHEETS']) {
      this._router.navigate(['/404'], { skipLocationChange: true });
      return of(false);
    }

    const currentUserId = this._authService.getCurrentUser()?.id_role;
    if (Number(route.paramMap.get('observer')) !== Number(currentUserId)) {
      if (currentUserId) {
        this._router.navigate(getObserverSheetRoute(String(currentUserId)));
      } else {
        this._router.navigate(['/404'], { skipLocationChange: true });
      }
      return of(false);
    }

    return this._loadObserver(route).pipe(
      tap((observer) => this._oss.setObserver(observer)),
      map(() => true),
      catchError(() => {
        this._router.navigate(['/404'], { skipLocationChange: true });
        return of(false);
      })
    );
  }

  canActivateChild(childRoute: ActivatedRouteSnapshot, state: RouterStateSnapshot): boolean {
    const targetedPath = childRoute.routeConfig.path;
    if (this.TAB_LINKS.map((tab) => tab.path).includes(targetedPath)) {
      return true;
    }

    this._router.navigate(['/404'], { skipLocationChange: true });
    return false;
  }

  private _loadObserver(route: ActivatedRouteSnapshot): Observable<Observer> {
    const observerParam = route.paramMap.get('observer');

    if (!observerParam) {
      return throwError(() => new Error('Missing observer param'));
    }

    const observerId = Number(observerParam);

    if (Number.isNaN(observerId)) {
      return throwError(() => new Error('Observer is a not a valid id'));
    }

    // canActivate guarantees that the observer is the authenticated user
    const currentUser = this._authService.getCurrentUser();
    return of({
      id_role: observerId,
      nom_complet: currentUser.nom_complet,
    } as Observer);
  }
}
