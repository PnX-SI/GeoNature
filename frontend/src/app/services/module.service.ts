import { Injectable } from '@angular/core';
import { Router } from '@angular/router';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { Observable, of, BehaviorSubject } from 'rxjs';
import { catchError, tap } from 'rxjs/operators';
import { ModuleGuardService } from '../routing/routes-guards.service';

@Injectable()
export class ModuleService {
  public _modules: BehaviorSubject<any[]> = new BehaviorSubject([]);
  get modules(): any[] {
    return this._modules.getValue();
  }
  set modules(value: any[]) {
    this._modules.next(value);
  }
  get $_modules(): Observable<any[]> {
    return this._modules.asObservable();
  }
  public currentModule$ = new BehaviorSubject<any>(null);
  get currentModule(): any {
    return this.currentModule$.getValue();
  }

  constructor(private _api: DataFormService, private _router: Router) {}

  fetchModulesAndSetRouting(): Observable<any[]> {
    // see CruvedStoreService.fetchCruved comments about the catchError
    return this._api.getModulesList([]).pipe(
      catchError((err) => of([])), // TODO: error MUST be handled in case we are logged! (typically, api down)
      tap((modules) => {
        const routingConfig = this._router.config;
        modules.forEach((module) => {
          if (module.ng_module) {
            const moduleConfig = {
              path: module.module_path,
              loadChildren: () =>
                import(
                  /* webpackInclude: /\/external_modules\/[^/]*\/frontend\// */
                  `../../../../external_modules/${module.ng_module}/frontend/app/gnModule.module`
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
        this._router.resetConfig(routingConfig);
        this.modules = modules;
      })
    );
  }

  getModules() {
    return this.modules;
  }

  getDisplayedModules() {
    return this.modules.filter((mod) => {
      return (
        mod.module_code.toLowerCase() !== 'geonature' &&
        (mod.active_frontend || mod.module_external_url)
      );
    });
  }

  /**
   * Get a module from the localstorage
   * @param module_code: name of the module
   */
  getModule(module_code: string) {
    for (let mod of this.modules) {
      if (mod.module_code.toLowerCase() === module_code.toLowerCase()) {
        return mod;
      }
    }
    return null; // module with this code not found
  }
}
