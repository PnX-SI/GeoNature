import { Injectable } from '@angular/core';
import { Router } from '@angular/router';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { Observable, of, BehaviorSubject } from 'rxjs';
import { catchError, tap } from 'rxjs/operators';

@Injectable()
export class ModuleService {
  public shouldLoadModules = true;
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
  get geoNatureModule(): any {
    return this.modules.find((module) => {
      return module.module_code.toLowerCase() == 'geonature';
    });
  }

  constructor(private _api: DataFormService, private _router: Router) {}

  loadModules(): Observable<any[]> {
    return this._api.getModulesList([]).pipe(
      catchError((err) => of([])), // TODO: error MUST be handled in case we are logged! (typically, api down)
      tap((modules) => {
        this.modules = modules;
        this.shouldLoadModules = false;
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
