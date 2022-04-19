import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

/**
 * @deprecated The globalSub Service is deprecated, please use ModuleService instead
 */
@Injectable()
export class GlobalSubService {
  public currentModuleSubject = new BehaviorSubject<any>(undefined);
  public currentModuleSub = this.currentModuleSubject.asObservable();

  constructor() {}
}
