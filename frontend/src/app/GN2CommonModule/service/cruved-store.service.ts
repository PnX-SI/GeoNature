import { Injectable } from '@angular/core';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { Observable, of, BehaviorSubject } from 'rxjs';
import { tap, map, distinctUntilChanged } from 'rxjs/operators';

import { ModuleService } from '@geonature/services/module.service';

@Injectable()
export class CruvedStoreService {
  private _cruved: BehaviorSubject<any> = new BehaviorSubject({});
  get cruved(): any {
    return this._cruved.getValue();
  }
  set cruved(value: any) {
    this._cruved.next(value);
  }
  get $_cruved(): Observable<any> {
    return this._cruved.asObservable();
  }

  constructor(private _moduleService: ModuleService) {
    this.getCruved();
  }

  private getCruved() {
    this._moduleService.$_modules
      .pipe(
        distinctUntilChanged(),
        map((modules: any[]): any => {
          const cruved = [];
          modules.forEach((mod) => {
            cruved[mod.module_code] = mod;
          });
          return cruved;
        })
      )
      .subscribe((cruved: any) => (this.cruved = cruved));
  }

  clearCruved(): void {
    this.cruved = null;
  }
}
