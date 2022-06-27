import {
  CanActivate,
  CanActivateChild,
  ActivatedRouteSnapshot,
  RouterStateSnapshot,
} from '@angular/router';
import { Inject, Injectable } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '@geonature/components/auth/auth.service';
import { ModuleService } from '@geonature/services/module.service';
import { CommonService } from '@geonature_common/service/common.service';
import { GlobalSubService } from '../services/global-sub.service';
import { APP_CONFIG_TOKEN } from '@geonature_config/app.config';
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
  ) {}

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    if (this._authService.getToken() === null) {
      this._router.navigate(['/login'], {
        queryParams: { route: state.url },
      });
      return false;
    } else {
      return true;
    }
  }

  canActivateChild(route: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    if (this._authService.getToken() === null) {
      this._router.navigate(['/login'], {
        queryParams: { route: state.url },
      });
      return false;
    } else {
      return true;
    }
  }
}

@Injectable()
export class PublicAccessGuard implements CanActivateChild {

  constructor(@Inject(APP_CONFIG_TOKEN) private cfg, private authService: AuthService) {}

  canActivateChild(route: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    let user = this.authService.getCurrentUser();
    if (
      this.cfg.PUBLIC_ACCESS.ENABLE_PUBLIC_ACCESS &&
      user &&
      this.cfg.PUBLIC_ACCESS.PUBLIC_LOGIN === user.user_login
    ) {
      return false;
    } else {
      return true;
    }
  }
}
