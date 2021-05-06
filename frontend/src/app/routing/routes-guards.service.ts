import {
  CanActivate,
  CanActivateChild,
  ActivatedRouteSnapshot,
  RouterStateSnapshot
} from '@angular/router';
import { Injectable } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '@geonature/components/auth/auth.service';
import { ModuleService } from '@geonature/services/module.service';
import { CommonService } from '@geonature_common/service/common.service';
import { GlobalSubService } from '../services/global-sub.service';
import { AppConfig } from '@geonature_config/app.config';

@Injectable()
export class ModuleGuardService implements CanActivate {
  constructor(
    private _router: Router,
    private _moduleService: ModuleService,
    private _globalSubService: GlobalSubService,
    private _commonService: CommonService
  ) {}

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    const moduleName = route.data['module_code'];

    const askedModule = this._moduleService.getModule(moduleName);
    if (askedModule) {
      this._globalSubService.currentModuleSubject.next(askedModule);
      return true;
    } else {
      this._router.navigate(['/']);
      this._commonService.regularToaster(
        'error',
        "Vous n'avez pas les droits d'accès au module " + moduleName
      );
      return false;
    }
  }
}

@Injectable()
export class AuthGuard implements CanActivate, CanActivateChild {
  constructor(
    private _authService: AuthService,
    private _router: Router,
    private _moduleService: ModuleService
  ) {}

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    if (this._authService.getToken() === null) {
      this._router.navigate(['/login'], {
          queryParams: { route: state.url, }
      });
      return false;
    } else {
      return true;
    }
  }

  canActivateChild(route: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    if (this._authService.getToken() === null) {
      this._router.navigate(['/login'], {
          queryParams: { route: state.url, }
      });
      return false;
    } else {
      return true;
    }
  }
}

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
