import { Injectable } from '@angular/core';
import { ModuleService } from "@geonature/services/module.service";

@Injectable()
export class AdminStoreService {
    public currentModule: any;
    constructor(private _moduleService: ModuleService) {
        console.log('init')

        this._moduleService.currentModuleSub
        .filter(mod => mod !== undefined)
        .subscribe(mod => {
          this.currentModule = mod;
      });
     }
}
