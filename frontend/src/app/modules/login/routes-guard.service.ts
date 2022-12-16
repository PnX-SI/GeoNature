import { Injectable } from '@angular/core';
import { ActivatedRouteSnapshot, CanActivate, Router, RouterStateSnapshot } from '@angular/router';

import { AppConfig } from '../../../conf/app.config';
import { AuthService, User } from '@geonature/components/auth/auth.service';

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

@Injectable()
export class UserPublicGuard implements CanActivate {
  /*
  A guard used to prevent public user from accessing certain routes :
  - Used to prevent public user from accessing the "/user" route in which the user can see and change its own information
  */

  constructor(private _router: Router, public authService: AuthService) {}

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    if (
      AppConfig['PUBLIC_ACCESS_USERNAME'] &&
      AppConfig['PUBLIC_ACCESS_USERNAME'] == this.authService.getCurrentUser().user_login
    ) {
      this._router.navigate(['/']);
      return false;
    }
    return true;
  }
}
