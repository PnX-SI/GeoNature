import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import {
  ActivatedRouteSnapshot,
  CanActivate,
  CanActivateChild,
  Router,
  RouterStateSnapshot,
  UrlTree,
} from '@angular/router';

import { AuthService } from '@geonature/components/auth/auth.service';
import { ConfigService } from '@geonature/services/config.service';
import { Observable } from 'rxjs';

@Injectable()
export class SignUpGuard implements CanActivate {
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
export class UserManagementGuard implements CanActivate {
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
export class UserPublicGuard implements CanActivate {
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

@Injectable()
export class UserCasGuard implements CanActivate, CanActivateChild {
  /*
  A guard used to prevent public user from accessing certain routes :
  - Used to prevent public user from accessing the "/user" route in which the user can see and change its own information
  */

  constructor(
    private _router: Router,
    public authService: AuthService,
    public _configService: ConfigService,
    private _httpclient: HttpClient
  ) {}
  canActivateChild(
    childRoute: ActivatedRouteSnapshot,
    state: RouterStateSnapshot
  ): boolean | UrlTree | Observable<boolean | UrlTree> | Promise<boolean | UrlTree> {
    return this.canActivate();
  }

  async canActivate(): Promise<boolean> {
    let res: boolean = false;
    if (this._configService.CAS_PUBLIC.CAS_AUTHENTIFICATION) {
      let data = await this._httpclient
        .get(`${this._configService.API_ENDPOINT}/auth/get_current_user`)
        .toPromise();
      data = { ...data };
      this.authService.manageUser(data);
      res = this.authService.isLoggedIn();
      return res;
    }
    return true;
  }
}
