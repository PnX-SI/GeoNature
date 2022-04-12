import { Injectable } from '@angular/core';
import { ActivatedRouteSnapshot, CanActivate, Router, RouterStateSnapshot } from '@angular/router';

import { AppConfig } from '../../../conf/app.config';

@Injectable()
export class SignUpGuard implements CanActivate {
  constructor(private _router: Router) {}

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    if (AppConfig['ACCOUNT_MANAGEMENT']['ENABLE_SIGN_UP'] || false) {
      return true;
    } else {
      this._router.navigate(['/login']);
      return false;
    }
  }
}

@Injectable()
export class UserManagementGuard implements CanActivate {
  constructor(private _router: Router) {}

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    if (AppConfig['ACCOUNT_MANAGEMENT']['ENABLE_USER_MANAGEMENT'] || false) {
      return true;
    } else {
      this._router.navigate(['/login']);
      return false;
    }
  }
}
