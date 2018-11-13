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

@Injectable()
export class ModuleGuardService implements CanActivate {
  constructor(private _router: Router, private _moduleService: ModuleService) {}

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    const moduleName = route.data['module_name'];
    const askedModule = this._moduleService.getModule(moduleName);
    if (askedModule) {
      this._moduleService.currentModuleSubject.next(askedModule);
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
