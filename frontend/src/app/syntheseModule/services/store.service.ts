import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root',
})
export class SyntheseStoreService {
  public idSyntheseList: Set<number> = new Set();
  private gridData: Object = {};
  private pointData: Object = {};

  constructor() {}

  public hasData(type): boolean {
    let hasData = false;
    if (type == 'grid') {
      hasData = this.gridData && Object.keys(this.gridData).length > 0;
      console.log(`Grid data length: ${this.gridData && Object.keys(this.gridData).length > 0}`);
      console.log(`Grid data: ${this.gridData}`, this.gridData);
    } else if (type == 'point') {
      hasData = this.pointData && Object.keys(this.pointData).length > 0;
      console.log(`Point data length: ${this.pointData && Object.keys(this.pointData).length > 0}`);
      console.log(`Point data: ${this.pointData}`, this.pointData);
    } else {
      throw new Error(`Unknown data type: ${type}`);
    }
    return hasData;
  }

  public getData(type): Object {
    let storedData = {};
    if (type == 'grid') {
      storedData = this.gridData;
    } else if (type == 'point') {
      storedData = this.pointData;
    } else {
      throw new Error(`Unknown data type: ${type}`);
    }
    return storedData;
  }

  public setData(type, data: Object) {
    if (type === 'grid') {
      this.gridData = data;
    } else if (type === 'point') {
      this.pointData = data;
    } else {
      throw new Error(`Unknown data type: ${type}`);
    }
  }

  public clearData() {
    this.idSyntheseList = new Set();
    this.gridData = {};
    this.pointData = {};
  }
}
