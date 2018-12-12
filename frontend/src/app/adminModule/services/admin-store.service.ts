import { Injectable } from '@angular/core';
import { GlobalSubService } from '@geonature/services/global-sub.service';
import { DataFormService } from '@geonature_common/form/data-form.service';

@Injectable()
export class AdminStoreService {
  public currentModule: any;
  public moduleCruved: any;

  constructor(private _globalSub: GlobalSubService, private _dataService: DataFormService) {
    this._globalSub.currentModuleSub.filter(mod => mod !== undefined).subscribe(mod => {
      this.currentModule = mod;
    });

    this._dataService.getCruved(['ADMIN']).subscribe(data => {
      this.moduleCruved = data[0];
    });
  }
}
