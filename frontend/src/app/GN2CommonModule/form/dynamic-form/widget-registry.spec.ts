import { UntypedFormControl, UntypedFormGroup } from '@angular/forms';
import { DEFAULT_WIDGETS, WidgetContext } from './widget-registry';

describe('DEFAULT_WIDGETS', () => {
  const control = new UntypedFormControl(null);
  const form = new UntypedFormGroup({ field: control });
  const config: any = { MEDIAS: { MEDIAS_SIZE_MAX: 5 } };

  const ctx = (def: any, rawDef: any = def): WidgetContext => ({
    def,
    rawDef,
    form,
    control: form.get('field'),
    config,
  });

  it('has an entry for each widget of the dynamic form', () => {
    expect(Object.keys(DEFAULT_WIDGETS).sort()).toEqual(
      [
        'areas',
        'date',
        'dataset',
        'datalist',
        'individuals',
        'medias',
        'multiselect',
        'municipalities',
        'nomenclature',
        'observers',
        'observers-text',
        'taxonomy',
      ].sort()
    );
  });

  it('maps a nomenclature definition', () => {
    const def = {
      type_widget: 'nomenclature',
      attribut_name: 'field',
      attribut_label: 'Etat',
      code_nomenclature_type: 'ETA_BIO',
      multi_select: true,
      key_value: 'cd_nomenclature',
      cd_nomenclatures: ['1'],
      regne: 'Animalia',
      group2Inpn: 'Mammifères',
      bind_all_item: false,
    };
    const entry = DEFAULT_WIDGETS['nomenclature'];
    expect(entry.inputs(ctx(def))).toEqual({
      label: 'Etat',
      parentFormControl: control,
      codeNomenclatureType: 'ETA_BIO',
      multiSelect: true,
      keyValue: 'cd_nomenclature',
      cdNomenclatures: ['1'],
      regne: 'Animalia',
      group2Inpn: 'Mammifères',
      bindAllItem: false,
    });
    expect(entry.dataQa(ctx(def))).toBe('field-nomenclature-field');
  });

  it('maps a dataset definition from the raw definition, with id_dataset as default bindValue', () => {
    const rawDef = {
      type_widget: 'dataset',
      attribut_name: 'field',
      attribut_label: 'JDD',
      module_code: 'OCCTAX',
      creatable_in_module: 'OCCHAB',
    };
    const evaluated = { ...rawDef, attribut_label: 'evaluated' };
    expect(DEFAULT_WIDGETS['dataset'].inputs(ctx(evaluated, rawDef))).toEqual({
      label: 'JDD',
      parentFormControl: control,
      multiSelect: undefined,
      moduleCode: 'OCCTAX',
      creatableInModule: 'OCCHAB',
      bindValue: 'id_dataset',
    });
    expect(
      DEFAULT_WIDGETS['dataset'].inputs(ctx(rawDef, { ...rawDef, bind_value: 'uuid' }))['bindValue']
    ).toBe('uuid');
  });

  it('maps a datalist definition with defaults for keyValue and keyLabel', () => {
    const inputs = DEFAULT_WIDGETS['datalist'].inputs(
      ctx({ type_widget: 'datalist', attribut_name: 'field', api: 'a/b', data_path: 'data' })
    );
    expect(inputs).toEqual(
      expect.objectContaining({
        keyValue: 'value',
        keyLabel: 'label',
        api: 'a/b',
        dataPath: 'data',
      })
    );
    expect(
      DEFAULT_WIDGETS['datalist'].dataQa(
        ctx({ type_widget: 'datalist', attribut_name: 'field', attribut_label: 'L' })
      )
    ).toBe('field-datalist-L-field');
  });

  it('maps a medias definition with the max size from the config and a stable default', () => {
    const def = { type_widget: 'medias', attribut_name: 'field', schema_dot_table: 'gn.t' };
    const first = DEFAULT_WIDGETS['medias'].inputs(ctx(def));
    expect(first['sizeMax']).toBe(5);
    expect(first['schemaDotTable']).toBe('gn.t');
    expect(DEFAULT_WIDGETS['medias'].inputs(ctx(def))['default']).toBe(first['default']);
    expect(DEFAULT_WIDGETS['medias'].hostStyle).toEqual({ display: 'block' });
  });

  it('gives the disabled state of the control to the multiselect', () => {
    const def = { type_widget: 'multiselect', attribut_name: 'field', values: [] };
    control.disable();
    expect(DEFAULT_WIDGETS['multiselect'].inputs(ctx(def))['disabled']).toBe(true);
    control.enable();
    expect(DEFAULT_WIDGETS['multiselect'].inputs(ctx(def))['disabled']).toBe(false);
  });
});
