import {
  CanActivate,
  CanActivateChild,
  ActivatedRouteSnapshot,
  RouterStateSnapshot
} from '@angular/router';
import { Injectable } from '@angular/core';
import { Router } from '@angular/router';
import { SideNavService } from '@geonature/components/sidenav-items/sidenav.service';
import { AuthService } from '@geonature/components/auth/auth.service';

@Injectable()
export class ModuleGuardService implements CanActivate {
  constructor(private _router: Router, private _sideNavService: SideNavService) { }

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    const id_module = route.data['id_module'];
    if (this._sideNavService.getModules(id_module)) {
      return true;
    } else {
      this._router.navigate(['/']);
      return false;
    }
  }
}

@Injectable()
export class AuthGuard implements CanActivate, CanActivateChild {
  constructor(private _authService: AuthService, private _router: Router) { }

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    if (this._authService.getToken() === null) {
      this._router.navigate(['/login']);
      return false;
    } else {
      return true;
    }
  }

  canActivateChild(route: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    if (this._authService.getToken() === null) {
      this._router.navigate(['/login']);
      return false;
    } else {
      return true;
    }
  }
}
