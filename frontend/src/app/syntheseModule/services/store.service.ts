import { Injectable } from '@angular/core';
import { EventDisplayCriteria } from '../synthese-results/synthese-carte/synthese-carte.component';

@Injectable({
  providedIn: 'root',
})
export class SyntheseStoreService {
  public idSyntheseList: Array<number>;
  public data: {
    [key: string]: Array<any>
  } = {};
  public criteria: EventDisplayCriteria = { type: 'point', name: 'default' };
  constructor() {}
}
