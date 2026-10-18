import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { DataFormService } from '../data-form.service';
import { TaxaSource } from './taxa.source';

describe('TaxaSource', () => {
  it('searches the names above a rank', (done) => {
    const dfs = {
      getHigherTaxa: jest.fn().mockReturnValue(of([{ cd_nom: 1, displayName: 'Canis' }])),
    };
    TestBed.configureTestingModule({ providers: [{ provide: DataFormService, useValue: dfs }] });
    TestBed.inject(TaxaSource)
      .load({ rank: 'FM', term: 'can' })
      .subscribe((taxa) => {
        expect(dfs.getHigherTaxa).toHaveBeenCalledWith('FM', 'can');
        expect(taxa).toEqual([{ cd_nom: 1, displayName: 'Canis' }]);
        done();
      });
  });
});
