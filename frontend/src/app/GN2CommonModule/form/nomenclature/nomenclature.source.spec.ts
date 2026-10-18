import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { DataFormService } from '../data-form.service';
import { NomenclatureSource } from './nomenclature.source';

describe('NomenclatureSource', () => {
  let dfs: { getNomenclature: jest.Mock };

  beforeEach(() => {
    dfs = { getNomenclature: jest.fn().mockReturnValue(of({ values: [{ id_nomenclature: 1 }] })) };
    TestBed.configureTestingModule({ providers: [{ provide: DataFormService, useValue: dfs }] });
  });

  it('loads the items of the type, ordered by label, and unwraps them', (done) => {
    TestBed.inject(NomenclatureSource)
      .load({
        codeNomenclatureType: 'ETA_BIO',
        regne: 'Animalia',
        group2Inpn: 'Mammifères',
        group3Inpn: 'g3',
        cdNomenclatures: ['1', '2'],
      })
      .subscribe((items) => {
        expect(dfs.getNomenclature).toHaveBeenCalledWith(
          'ETA_BIO',
          'Animalia',
          'Mammifères',
          'g3',
          {
            orderby: 'label_default',
            cd_nomenclature: ['1', '2'],
          }
        );
        expect(items).toEqual([{ id_nomenclature: 1 }]);
        done();
      });
  });
});
