import { Injectable } from '@angular/core';
import { GlobalSubService } from '@geonature/services/global-sub.service';

@Injectable()
export class AdminStoreService {
  public currentModule: any;
  constructor(private _globalSub: GlobalSubService) {
    console.log('init');

    this._globalSub.currentModuleSub.filter(mod => mod !== undefined).subscribe(mod => {
      this.currentModule = mod;
    });
  }
}
