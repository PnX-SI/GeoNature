import { Injectable } from '@angular/core';
import { CanActivate, Router } from '@angular/router';

import { AuthService } from '@geonature/components/auth/auth.service';
import { ConfigService } from '@geonature/services/config.service';

@Injectable()
export class SignUpGuard implements CanActivate {
  constructor(private _router: Router, public cs: ConfigService) {}

  canActivate() {
    if (this.cs['ACCOUNT_MANAGEMENT']['ENABLE_SIGN_UP'] || false) {
      return true;
    } else {
      this._router.navigate(['/login']);
      return false;
    }
  }
}

@Injectable()
export class UserManagementGuard implements CanActivate {
  constructor(private _router: Router, public cs: ConfigService) {}

  canActivate() {
    if (this.cs['ACCOUNT_MANAGEMENT']['ENABLE_USER_MANAGEMENT'] || false) {
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

  constructor(private _router: Router, public authService: AuthService, public cs: ConfigService) {}

  canActivate() {
    if (
      this.cs['PUBLIC_ACCESS_USERNAME'] &&
      this.cs['PUBLIC_ACCESS_USERNAME'] == this.authService.getCurrentUser().user_login
    ) {
      this._router.navigate(['/']);
      return false;
    }
    return true;
  }
}
