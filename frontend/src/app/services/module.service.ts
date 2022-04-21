import { Injectable } from '@angular/core';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { Observable, of, BehaviorSubject } from 'rxjs';
import { catchError, tap } from 'rxjs/operators';

@Injectable()
export class ModuleService {
  private _modules: BehaviorSubject<any[]> = new BehaviorSubject([]);
  get modules(): any[] {
    return this._modules.getValue();
  }
  set modules(value: any[]) {
    this._modules.next(value);
  }
  get $_modules(): Observable<any[]> {
    return this._modules.asObservable();
  }

  constructor(private _api: DataFormService) {}

  fetchModules(): Observable<any[]> {
    // see CruvedStoreService.fetchCruved comments about the catchError
    return this._api.getModulesList([]).pipe(
      catchError((err) => of([])), // TODO: error MUST be handled in case we are logged! (typically, api down)
      tap((modules) => (this.modules = modules))
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
