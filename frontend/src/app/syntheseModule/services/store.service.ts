import { Injectable } from '@angular/core';

@Injectable()
export class SyntheseStoreService {
  public idSyntheseList: Array<number>;
  public data: {
    [key: string]: Array<any>
  } = {};
  constructor() {}
}
