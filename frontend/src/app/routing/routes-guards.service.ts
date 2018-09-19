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
  constructor(private _router: Router, private _sideNavService: SideNavService) {}

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    const module_name = route.data['module_name'];
    if (this._sideNavService.getModule(module_name)) {
      return true;
    } else {
      this._router.navigate(['/']);
      return false;
    }
  }
}

@Injectable()
export class AuthGuard implements CanActivate, CanActivateChild {
  constructor(private _authService: AuthService, private _router: Router) {}

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
