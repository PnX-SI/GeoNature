import { async, TestBed, getTestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';

import { DataFormService } from './data-form.service';

describe('DataFormService', () => {
  let service: DataFormService;
  let injector: TestBed;
  let httpMock: HttpTestingController;

  beforeEach(() =>
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [DataFormService],
    })
  );

  beforeEach(() => {
    injector = getTestBed();
    httpMock = injector.get(HttpTestingController);
    service = TestBed.get(DataFormService);
  });

  it('should return an Observable<Array<Taxon>>', async(() => {
    const dummyTaxon = {
      id_liste: 1001,
      search_name: 'Ablette = <i>Alburnus alburnus</i> (Linnaeus, 1758)',
      nom_valide: 'Alburnus alburnus (Linnaeus, 1758)',
      group2_inpn: 'Poissons',
      regne: 'Animalia',
      lb_nom: 'Alburnus alburnus',
      cd_nom: 67111,
    };
    service.searchTaxonomy('ablette', '1001').subscribe((taxons) => {
      expect(taxons.length).toBe(1);
      expect(taxons[0]).toEqual(dummyTaxon);
    });
  }));

  // afterEach(() => {
  //   httpMock.verify();
  // });
});
