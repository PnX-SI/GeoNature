import {
  ActivatedRouteSnapshot,
  CanActivate,
  CanActivateChild,
  Router,
  RouterStateSnapshot,
} from '@angular/router';
import { Injectable, Injector } from '@angular/core';
import { AuthService } from '@geonature/components/auth/auth.service';

@Injectable()
export class AuthGuard implements CanActivate, CanActivateChild {
  constructor(private _router: Router, private _injector: Injector) {}

  redirectAuth(route, state) {
    const authService = this._injector.get(AuthService);

    if (authService.getToken() === null) {
      this._router.navigate(['/login'], {
        queryParams: { ...route.queryParams, ...{ route: state.url.split('?')[0] } },
      });
      return false;
    }

    return true;
  }
  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    return this.redirectAuth(route, state);
  }

  canActivateChild(route: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    return this.redirectAuth(route, state);
  }
}
