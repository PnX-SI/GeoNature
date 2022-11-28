import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root',
})
export class SyntheseStoreService {
  public idSyntheseList: Array<number>;
  public gridData: Array<any>;
  public pointData: Array<any>;
  constructor() {}
}
