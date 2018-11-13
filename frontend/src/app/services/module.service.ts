import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { AppConfig } from '@geonature_config/app.config';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { BehaviorSubject } from 'rxjs';



@Injectable()
export class ModuleService {
  public modules: Array<any>;
  public modulesSubject = new BehaviorSubject<any>(undefined);
  public currentModuleSubject = new BehaviorSubject<any>(undefined);
  public modulesSub = this.modulesSubject.asObservable();
  public currentModuleSub = this.currentModuleSubject.asObservable();
  public currentModule: any;

  constructor(private _api: DataFormService) {


  this._api.getModulesList().subscribe(data => {
      this.modules = data;
      this.setModulesLocalStorage(data);
      this.modulesSubject.next(data);
    });
  }

  setModulesLocalStorage(modules) {
    localStorage.setItem('modules', JSON.stringify(modules));
  }

  /**
   * Get a module from the localstorage
   * @param module_name: name of the module
   */
  getModule(module_name: string) {
    const modules = localStorage.getItem('modules');
    let searchModule = null;
    if (modules) {
      JSON.parse(modules).forEach(mod => {
        if (mod.module_name.toLocaleLowerCase() === module_name.toLocaleLowerCase()) {
          searchModule = mod;
        }
      });
    }
    return searchModule;
  }
}
