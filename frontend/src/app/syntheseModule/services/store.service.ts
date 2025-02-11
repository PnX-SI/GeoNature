import { Injectable } from '@angular/core';

// TODO: rename this service to SyntheseCacheService
@Injectable({
  providedIn: 'root',
})
export class SyntheseStoreService {
  public idSyntheseList: Set<number> = new Set();
  public data: Object = {};

  constructor() {}

  public hasData(type): boolean {
    let hasData = false;
    if (this.data[type] && Object.keys(this.data[type]).length > 0) {
      hasData = true;
    }
    return hasData;
  }

  public getData(type): Object {
    let storedData = [];
    if (this.data[type] && Object.keys(this.data[type]).length > 0) {
      storedData = this.data[type];
    }
    return storedData;
  }

  public setData(type: string, dataToStore: Object) {
    this.data[type] = dataToStore;
  }

  public clearData() {
    this.idSyntheseList = new Set();
    this.data = {};
  }
}
