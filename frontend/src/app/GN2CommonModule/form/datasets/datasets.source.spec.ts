import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { DataFormService } from '../data-form.service';
import { DatasetsSource } from './datasets.source';

describe('DatasetsSource', () => {
  it('loads the datasets matching the filters', (done) => {
    const dfs = {
      getDatasets: jest.fn().mockReturnValue(of([{ id_dataset: 1, dataset_name: 'a' }])),
    };
    TestBed.configureTestingModule({ providers: [{ provide: DataFormService, useValue: dfs }] });
    TestBed.inject(DatasetsSource)
      .load({ active: true })
      .subscribe((datasets) => {
        expect(dfs.getDatasets).toHaveBeenCalledWith({ active: true });
        expect(datasets).toEqual([{ id_dataset: 1, dataset_name: 'a' }]);
        done();
      });
  });
});
