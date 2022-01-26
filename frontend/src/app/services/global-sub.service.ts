import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import { filter } from 'rxjs/operators';

@Injectable()
export class GlobalSubService {
  public currentModuleSub = new BehaviorSubject<any>(
    JSON.parse(localStorage.getItem("currentModule"))
  );


  constructor() {}
  
}
