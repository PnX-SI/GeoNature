import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { ConfigService } from '@geonature/services/config.service';
import { DataFormService } from './data-form.service';

describe('DataFormService', () => {
  let service: DataFormService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [
        DataFormService,
        {
          provide: ConfigService,
          useValue: { API_ENDPOINT: 'http://gn/api', TAXHUB: { API_PREFIX: '/api' } },
        },
      ],
    });
    service = TestBed.inject(DataFormService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => httpMock.verify());

  it('builds the URL of the TaxHub API', () => {
    expect(service.getTaxhubAPI()).toBe('http://gn/api/taxhub/api');
  });

  describe('getNomenclature', () => {
    it('always sends the taxonomic filters, even empty', () => {
      service.getNomenclature('ETA_BIO').subscribe();
      const req = httpMock.expectOne(
        (r) => r.url === 'http://gn/api/nomenclatures/nomenclature/ETA_BIO'
      );
      expect(req.request.params.get('regne')).toBe('');
      expect(req.request.params.get('group2_inpn')).toBe('');
      expect(req.request.params.get('group3_inpn')).toBe('');
      req.flush({});
    });

    it('sends the filters, one param per cd_nomenclature', () => {
      service
        .getNomenclature('ETA_BIO', 'Animalia', 'Mammifères', undefined, {
          orderby: 'label_default',
          cd_nomenclature: ['1', '2'],
        })
        .subscribe();
      const req = httpMock.expectOne((r) => r.url.endsWith('/ETA_BIO'));
      expect(req.request.params.get('regne')).toBe('Animalia');
      expect(req.request.params.get('group2_inpn')).toBe('Mammifères');
      expect(req.request.params.get('orderby')).toBe('label_default');
      expect(req.request.params.getAll('cd_nomenclature')).toEqual(['1', '2']);
      req.flush({});
    });
  });

  describe('getDataList', () => {
    it('calls the GeoNature API with a GET and the params', () => {
      service
        .getDataList('meta/datasets', 'GeoNature', { orderby: 'name', ids: [1, 2] })
        .subscribe();
      const req = httpMock.expectOne((r) => r.url === 'http://gn/api/meta/datasets');
      expect(req.request.method).toBe('GET');
      expect(req.request.params.get('orderby')).toBe('name');
      expect(req.request.params.getAll('ids')).toEqual(['1', '2']);
      req.flush([]);
    });

    it('calls the TaxHub API', () => {
      service.getDataList('bibnoms', 'TaxHub').subscribe();
      httpMock.expectOne('http://gn/api/taxhub/api/bibnoms').flush([]);
    });

    it('calls a raw URL for another application', () => {
      service.getDataList('http://other/list', null).subscribe();
      httpMock.expectOne('http://other/list').flush([]);
    });

    it('sends a POST when data is given', () => {
      service.getDataList('meta/search', 'GeoNature', {}, { a: 1 }).subscribe();
      const req = httpMock.expectOne('http://gn/api/meta/search');
      expect(req.request.method).toBe('POST');
      expect(req.request.body).toEqual({ a: 1 });
      req.flush([]);
    });
  });

  describe('autocompleteTaxon', () => {
    it('sends the search name and the non empty params', () => {
      service
        .autocompleteTaxon('http://th/search', 'canis', {
          regne: 'Animalia',
          group2_inpn: null,
          limit: '10',
        })
        .subscribe();
      const req = httpMock.expectOne((r) => r.url === 'http://th/search');
      expect(req.request.params.get('search_name')).toBe('canis');
      expect(req.request.params.get('regne')).toBe('Animalia');
      expect(req.request.params.get('limit')).toBe('10');
      expect(req.request.params.has('group2_inpn')).toBe(false);
      req.flush([]);
    });
  });
});
