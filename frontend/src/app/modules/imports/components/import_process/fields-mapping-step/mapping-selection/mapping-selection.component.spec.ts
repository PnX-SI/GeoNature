import { FormControl } from '@angular/forms';
import { BehaviorSubject } from 'rxjs';
import { MappingSelectionComponent } from './mapping-selection.component';

// The component is instantiated directly: its standalone template imports the whole common module,
// only the logic is tested here.
describe('MappingSelectionComponent', () => {
  let fieldMappingService: any;
  let common: { translateToaster: jest.Mock };

  const create = (importData: any = { fieldmapping: null }) => {
    const component = new MappingSelectionComponent(
      fieldMappingService,
      {} as any,
      { getImportData: () => importData } as any,
      {} as any,
      {
        cruved: {
          IMPORT: {
            module_objects: { MAPPING: { cruved: { C: 1, R: 1, U: 0, V: 0, E: 0, D: 0 } } },
          },
        },
      } as any,
      { open: jest.fn() } as any,
      common as any
    );
    component.ngOnInit();
    return component;
  };

  beforeEach(() => {
    fieldMappingService = {
      data: new BehaviorSubject<any>({ fieldMappings: null }),
      currentFieldMapping: new BehaviorSubject<any>('previous'),
      mappingSelectionFormControl: new FormControl(null),
    };
    common = { translateToaster: jest.fn() };
  });

  it('computes the rights of the user on mappings', () => {
    const component = create();
    expect(component.cruved.C).toBe(true);
    expect(component.cruved.U).toBe(false);
  });

  it('lists the mappings of the user once loaded', () => {
    const component = create();
    fieldMappingService.data.next({ fieldMappings: [{ label: 'm1' }] });
    expect(component.userFieldMappings).toEqual([{ label: 'm1' }]);
  });

  it('starts without selected mapping', () => {
    const component = create();
    expect(component.isMappingSelected()).toBe(false);
    expect(fieldMappingService.currentFieldMapping.value).toBeNull();
  });

  it('publishes the mapping the user selects', () => {
    const component = create();
    component.fieldMappingForm.setValue({ label: 'm1' });
    expect(fieldMappingService.currentFieldMapping.value).toEqual({ label: 'm1' });
    expect(component.isMappingSelected()).toBe(true);
  });

  it('asks to select a mapping before renaming', () => {
    const component = create();
    component.toggleRenameMappingForm();
    expect(common.translateToaster).toHaveBeenCalledWith(
      'error',
      'Import.FieldMapping.Actions.SelectMapping'
    );
    expect(component.renameMappingFormVisible).toBe(false);
  });

  it('shows the rename form prefilled with the label of the selected mapping', () => {
    const component = create();
    component.fieldMappingForm.setValue({ label: 'm1' });
    component.toggleRenameMappingForm();
    expect(component.renameMappingFormVisible).toBe(true);
    expect(component.createOrRenameMappingForm.value).toBe('m1');
  });

  it('stops listening to the selection when destroyed', () => {
    const component = create();
    component.ngOnDestroy();
    component.fieldMappingForm.setValue({ label: 'm2' });
    expect(fieldMappingService.currentFieldMapping.value).toBeNull();
  });
});
