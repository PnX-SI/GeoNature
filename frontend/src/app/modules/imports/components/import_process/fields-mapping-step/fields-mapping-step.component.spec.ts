import { TestBed } from '@angular/core/testing';
import { ActivatedRoute } from '@angular/router';
import { BehaviorSubject } from 'rxjs';
import { FieldsMappingStepComponent } from './fields-mapping-step.component';
import { FieldMappingService } from '@geonature/modules/imports/services/mappings/field-mapping.service';
import { ImportProcessService } from '../import-process.service';
import { ImportDataService } from '../../../services/data.service';
import { CruvedStoreService } from '@geonature_common/service/cruved-store.service';
import { ConfigService } from '@geonature/services/config.service';
import { AuthService } from '@geonature/components/auth/auth.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';

describe('FieldsMappingStepComponent', () => {
  let fieldMappingService: any;

  const create = (importData: any = {}) => {
    TestBed.overrideProvider(ImportProcessService, {
      useValue: { getImportData: () => importData },
    });
    const fixture = TestBed.createComponent(FieldsMappingStepComponent);
    fixture.detectChanges();
    return fixture.componentInstance;
  };

  beforeEach(() => {
    fieldMappingService = {
      // the first value is the one of the last import: the component skips it
      data: new BehaviorSubject<any>(null),
      retrieveData: jest.fn(),
      parseData: jest.fn(),
      getTargetFieldsData: jest.fn().mockReturnValue(['target']),
      getSourceFieldsData: jest.fn().mockReturnValue(['source']),
      initForm: jest.fn(),
      populateMappingForm: jest.fn(),
      fillFormWithMapping: jest.fn(),
      destroySubscription: jest.fn(),
    };
    TestBed.configureTestingModule({
      declarations: [FieldsMappingStepComponent],
      providers: [
        { provide: FieldMappingService, useValue: fieldMappingService },
        { provide: ActivatedRoute, useValue: { snapshot: { data: { step: 'FIELDMAPPING' } } } },
        { provide: ImportProcessService, useValue: {} },
        { provide: ImportDataService, useValue: {} },
        { provide: ConfigService, useValue: {} },
        { provide: AuthService, useValue: {} },
        { provide: NgbModal, useValue: {} },
        {
          provide: CruvedStoreService,
          useValue: {
            cruved: {
              IMPORT: {
                module_objects: { MAPPING: { cruved: { C: 1, R: 1, U: 1, V: 0, E: 0, D: 0 } } },
              },
            },
          },
        },
      ],
    });
    // the template needs many components and modals, only the logic is tested here
    TestBed.overrideComponent(FieldsMappingStepComponent, { set: { template: '' } });
  });

  it('loads the mapping data and is loading until they arrive', () => {
    const component = create();
    expect(fieldMappingService.retrieveData).toHaveBeenCalled();
    expect(component.isLoading).toBe(true);
    expect(component.step).toBe('FIELDMAPPING');
    expect(component.cruved.C).toBe(true);
  });

  it('builds the form once the data arrive', () => {
    const component = create();
    const data = { fieldMappings: [], targetFields: [], sourceFields: [] };
    fieldMappingService.data.next(data);
    expect(fieldMappingService.parseData).toHaveBeenCalledWith(data);
    expect(fieldMappingService.initForm).toHaveBeenCalled();
    expect(component.targetFields).toEqual(['target']);
    expect(component.sourceFields).toEqual(['source']);
    expect(component.isLoading).toBe(false);
    expect(fieldMappingService.fillFormWithMapping).not.toHaveBeenCalled();
  });

  it('fills the form with the mapping of the import', () => {
    create({ fieldmapping: { a: 'b' } });
    fieldMappingService.data.next({ fieldMappings: [], targetFields: [], sourceFields: [] });
    expect(fieldMappingService.fillFormWithMapping).toHaveBeenCalledWith({ a: 'b' }, false);
  });

  it('does nothing while there are no field mappings', () => {
    const component = create();
    fieldMappingService.data.next({ fieldMappings: null });
    expect(fieldMappingService.parseData).not.toHaveBeenCalled();
    expect(component.isLoading).toBe(true);
  });

  it('releases the subscriptions of the service when destroyed', () => {
    const component = create();
    component.ngOnDestroy();
    expect(fieldMappingService.destroySubscription).toHaveBeenCalled();
  });
});
