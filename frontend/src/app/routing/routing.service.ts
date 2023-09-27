import { Injectable, Injector } from '@angular/core';
import { Router } from '@angular/router';
import { ModuleGuardService } from './module-guard.service';

@Injectable({ providedIn: 'root' })
export class RoutingService {
  constructor(private _injector: Injector) {}

  loadRoutes(modules, url?: string) {
    const router: Router = this._injector.get(Router);
    const routingConfig = router.config;

    modules.forEach((module) => {
      if (module.ng_module) {
        const moduleConfig = {
          path: module.module_path,
          loadChildren: () =>
            import(
              /* webpackInclude: /\/external_modules\/[^/]*\// */
              '../../../external_modules/' + module.ng_module + '/app/gnModule.module'
            ).then((m) => m.GeonatureModule),
          canActivate: [ModuleGuardService],
          data: {
            module_code: module.module_code,
          },
        };
        // insert at the begining otherwise pagenotfound component is first matched
        const basePathIndex = routingConfig.findIndex((route) => {
          return route.path === '';
        });
        routingConfig[basePathIndex].children.unshift(moduleConfig);
      }
    });
    router.resetConfig(routingConfig);
    if (url) {
      router.navigateByUrl(url);
    }
  }
}
