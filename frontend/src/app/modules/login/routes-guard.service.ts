import { Injectable } from '@angular/core';
import { Router } from '@angular/router';

import { AuthService } from '@geonature/components/auth/auth.service';
import { ConfigService } from '@geonature/services/config.service';

@Injectable()
export class SignUpGuard  {
  constructor(
    private _router: Router,
    public config: ConfigService
  ) {}

  canActivate() {
    if (this.config['ACCOUNT_MANAGEMENT']['ENABLE_SIGN_UP'] || false) {
      return true;
    } else {
      this._router.navigate(['/login']);
      return false;
    }
  }
}

@Injectable()
export class UserManagementGuard  {
  constructor(
    private _router: Router,
    public config: ConfigService
  ) {}

  canActivate() {
    if (this.config['ACCOUNT_MANAGEMENT']['ENABLE_USER_MANAGEMENT'] || false) {
      return true;
    } else {
      this._router.navigate(['/login']);
      return false;
    }
  }
}

@Injectable()
export class UserPublicGuard  {
  /*
  A guard used to prevent public user from accessing certain routes :
  - Used to prevent public user from accessing the "/user" route in which the user can see and change its own information
  */

  constructor(
    private _router: Router,
    public authService: AuthService,
    public config: ConfigService
  ) {}

  canActivate() {
    if (
      this.config['PUBLIC_ACCESS_USERNAME'] &&
      this.config['PUBLIC_ACCESS_USERNAME'] == this.authService.getCurrentUser().user_login
    ) {
      this._router.navigate(['/']);
      return false;
    }
    return true;
  }
}
