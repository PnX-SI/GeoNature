import { Injectable, Injector } from '@angular/core';
import { Router } from '@angular/router';
import { ModuleGuardService } from './module.guard.service';

@Injectable({ providedIn: 'root' })
export class RoutingService {
  constructor(private _injector: Injector) {}

  loadRoutes(modules) {
    const router: Router = this._injector.get(Router);
    const routingConfig = router.config;
    modules.forEach((module) => {
      if (module.ng_module) {
        const moduleConfig = {
          path: module.module_path,
          loadChildren: () =>
            import(
              '../../../../external_modules/' + module.ng_module + '/frontend/app/gnModule.module'
            ).then((m) => m.GeonatureModule),
          canActivate: [ModuleGuardService],
          data: {
            module_code: module.module_code,
          },
        };
        routingConfig[3].children.unshift(moduleConfig);
      }
    });
    router.resetConfig(routingConfig);
  }
}
