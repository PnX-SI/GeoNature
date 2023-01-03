import { CanActivate, ActivatedRouteSnapshot, RouterStateSnapshot } from '@angular/router';
import { Injectable, Injector } from '@angular/core';
import { Router } from '@angular/router';
import { ModuleService } from '../services/module.service';
import { CommonService } from '@geonature_common/service/common.service';

@Injectable()
export class ModuleGuardService implements CanActivate {
  constructor(
    private _router: Router,
    private _commonService: CommonService,
    private _injector: Injector
  ) {}

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot) {
    const moduleService = this._injector.get(ModuleService);
    const moduleName = route.data['module_code'];
    const askedModule = moduleService.getModule(moduleName);
    if (askedModule) {
      moduleService.currentModule$.next(askedModule);
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
