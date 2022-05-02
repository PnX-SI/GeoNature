import {
  CanActivate,
  CanActivateChild,
  ActivatedRouteSnapshot,
  RouterStateSnapshot,
} from '@angular/router';
import { Injectable, Injector } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '@geonature/components/auth/auth.service';

@Injectable()
export class AuthGuard implements CanActivate, CanActivateChild {
  constructor(private _router: Router, private _injector: Injector) {}

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    const authService = this._injector.get(AuthService);
    if (authService.getToken() === null) {
      this._router.navigate(['/login'], {
        queryParams: { route: state.url },
      });
      return false;
    } else {
      return true;
    }
  }

  canActivateChild(route: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    const authService = this._injector.get(AuthService);
    if (authService.getToken() === null) {
      this._router.navigate(['/login'], {
        queryParams: { route: state.url },
      });
      return false;
    } else {
      return true;
    }
  }
}
