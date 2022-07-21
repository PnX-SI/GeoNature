import { Injectable } from '@angular/core';
import { DataFormService } from '../data-form.service';

@Injectable({ providedIn: 'root' })
export class DatasetStoreService {
  public filteredDataSets: Array<any>;
  public datasets: Array<any>;
  constructor() {}
}
