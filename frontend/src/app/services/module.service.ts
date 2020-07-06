import { Injectable } from '@angular/core';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { BehaviorSubject } from 'rxjs';

@Injectable()
export class ModuleService {
  // all active modules
  // all modules exepted GEONATURE, for sidebar display
  public displayedModules: Array<any>;
  private $module: BehaviorSubject<Array<any>> = new BehaviorSubject(null);
  constructor(private _api: DataFormService) {
    this.fetchModules();
  }

  get modules(): Array<any> {
    return this.$module.getValue()
  }

  fetchModules() {
    this._api.getModulesList([]).subscribe(data => {
      this.$module.next(data);
      this.displayedModules = data.filter(mod => {
        return (mod.module_code.toLowerCase() !== 'geonature') && (mod.active_frontend || mod.module_external_url);
      });
      this.setModulesLocalStorage(data);
    });
  }

  setModulesLocalStorage(modules) {
    localStorage.setItem('modules', JSON.stringify(modules));
  }

  getModules() {
    return localStorage.getItem('modules')
  }

  /**
   * Get a module from the localstorage
   * @param module_code: name of the module
   */
  getModule(module_code: string) {
    const modules = localStorage.getItem('modules');
    let searchModule = null;
    if (modules) {
      JSON.parse(modules).forEach(mod => {
        if (mod.module_code.toLowerCase() === module_code.toLowerCase()) {
          searchModule = mod;
        }
      });
    }
    return searchModule;
  }
}
