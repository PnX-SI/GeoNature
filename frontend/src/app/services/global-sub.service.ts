import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

@Injectable()
export class GlobalSubService {
  public currentModuleSubject = new BehaviorSubject<any>(undefined);
  public currentModuleSub = this.currentModuleSubject.asObservable();

  constructor() {}
}
