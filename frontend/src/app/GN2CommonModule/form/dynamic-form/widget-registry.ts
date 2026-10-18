import { InjectionToken, Type } from '@angular/core';
import { AbstractControl, UntypedFormGroup } from '@angular/forms';
import { ConfigService } from '@geonature/services/config.service';
import { MediasComponent } from '../media/medias.component';
import { NomenclatureComponent } from '../nomenclature/nomenclature.component';
import { TaxonomyComponent } from '../taxonomy/taxonomy.component';
import { DatasetsComponent } from '../datasets/datasets.component';
import { ObserversComponent } from '../observers/observers.component';
import { ObserversTextComponent } from '../observers-text/observers-text.component';
import { DateComponent } from '../date/date.component';
import { AreasComponent } from '../areas/areas.component';
import { MunicipalitiesComponent } from '../municipalities/municipalities.component';
import { MultiSelectComponent } from '../multiselect/multiselect.component';
import { DatalistComponent } from '../datalist/datalist.component';
import { IndividualsComponent } from '../individuals/individuals.component';

/** Widgets rendered by plain HTML in the template of ``pnx-dynamic-form`` */
export type NativeWidgetType =
  | 'text'
  | 'time'
  | 'number'
  | 'textarea'
  | 'select'
  | 'file'
  | 'checkbox'
  | 'bool_checkbox'
  | 'radio'
  | 'bool_radio'
  | 'html';

/** Widgets rendered by a component of the widget registry */
export type RegistryWidgetType =
  | 'medias'
  | 'nomenclature'
  | 'taxonomy'
  | 'dataset'
  | 'observers'
  | 'observers-text'
  | 'date'
  | 'areas'
  | 'municipalities'
  | 'multiselect'
  | 'datalist'
  | 'individuals';

export type WidgetType = NativeWidgetType | RegistryWidgetType;

/**
 * Definition of a field of a dynamic form. Any attribute can also be a function of the
 * form value (see ``DynamicFormService.getFormDefValue``).
 */
export interface FormDef {
  type_widget: WidgetType | string;
  attribut_name: string;
  attribut_label?: string;
  required?: boolean;
  hidden?: boolean;
  definition?: string;
  link_definition?: string;
  help?: string;
  values?: Array<any>;
  default?: any;
  [key: string]: any;
}

/** What a widget needs to compute its inputs */
export interface WidgetContext {
  /** Definition of the field, attributes evaluated against the current form value */
  def: FormDef;
  /** Definition of the field as given to the dynamic form */
  rawDef: FormDef;
  form: UntypedFormGroup;
  /** Control of the field, ``undefined`` if the form has no such control */
  control: AbstractControl | null;
  config: ConfigService;
}

export interface WidgetEntry {
  component: Type<any>;
  /** Inputs of the component. Must return the same reference for unchanged values */
  inputs: (ctx: WidgetContext) => Record<string, any>;
  /** Value of the ``data-qa`` attribute of the component */
  dataQa?: (ctx: WidgetContext) => string;
  /** Style applied on the host element of the component */
  hostStyle?: Record<string, string>;
}

export type WidgetRegistry = Record<string, WidgetEntry>;

const EMPTY_OBJECT = {};

export const DEFAULT_WIDGETS: WidgetRegistry = {
  medias: {
    component: MediasComponent,
    hostStyle: { display: 'block' },
    inputs: ({ def, control, config }) => ({
      schemaDotTable: def['schema_dot_table'],
      parentFormControl: control,
      sizeMax: config.MEDIAS.MEDIAS_SIZE_MAX,
      default: def['default'] || EMPTY_OBJECT,
      details: def['details'],
      hideDetailsFields: def['hide_details_fields'],
    }),
  },
  nomenclature: {
    component: NomenclatureComponent,
    dataQa: ({ def }) => 'field-nomenclature-' + def['attribut_name'],
    inputs: ({ def, control }) => ({
      label: def['attribut_label'],
      parentFormControl: control,
      codeNomenclatureType: def['code_nomenclature_type'],
      multiSelect: def['multi_select'],
      keyValue: def['key_value'],
      cdNomenclatures: def['cd_nomenclatures'],
      regne: def['regne'],
      group2Inpn: def['group2Inpn'],
      bindAllItem: def['bind_all_item'],
    }),
  },
  taxonomy: {
    component: TaxonomyComponent,
    dataQa: ({ def }) => 'field-taxonomy-' + def['attribut_name'],
    inputs: ({ def, control }) => ({
      label: def['attribut_label'],
      parentFormControl: control,
      idList: def['id_list'],
      charNumber: 3,
      listLength: 20,
    }),
  },
  dataset: {
    component: DatasetsComponent,
    dataQa: ({ def }) => 'field-dataset-' + def['attribut_name'],
    // these inputs are read from the definition as given, not evaluated against the form value
    inputs: ({ rawDef, form }) => ({
      label: rawDef.attribut_label,
      parentFormControl: form.get(rawDef.attribut_name),
      multiSelect: rawDef['multi_select'],
      moduleCode: rawDef['module_code'],
      creatableInModule: rawDef['creatable_in_module'],
      bindValue: rawDef['bind_value'] ?? 'id_dataset',
    }),
  },
  observers: {
    component: ObserversComponent,
    dataQa: ({ def }) => 'field-observers-' + def['attribut_name'],
    inputs: ({ def, control }) => ({
      label: def['attribut_label'],
      parentFormControl: control,
      idMenu: def['id_menu'],
      idList: def['id_list'],
      codeList: def['code_list'],
      multiSelect: def['multi_select'],
    }),
  },
  'observers-text': {
    component: ObserversTextComponent,
    dataQa: ({ def }) => 'field-observers-txt-' + def['attribut_name'],
    inputs: ({ def, control }) => ({
      label: def['attribut_label'],
      parentFormControl: control,
    }),
  },
  date: {
    component: DateComponent,
    dataQa: ({ def }) => 'field-date-' + def['attribut_name'],
    inputs: ({ def, control }) => ({
      label: def['attribut_label'],
      parentFormControl: control,
    }),
  },
  areas: {
    component: AreasComponent,
    dataQa: ({ def }) => 'field-areas-' + def['attribut_name'],
    inputs: ({ def, control }) => ({
      label: def['attribut_label'],
      parentFormControl: control,
      valueFieldName: def['value_field_name'],
      typeCodes: def['type_codes'],
      multiSelect: def['multi_select'],
    }),
  },
  municipalities: {
    component: MunicipalitiesComponent,
    dataQa: ({ def }) => 'field-municipalities-' + def['attribut_name'],
    inputs: ({ def, control }) => ({
      label: def['attribut_label'],
      parentFormControl: control,
      valueFieldName: def['value_field_name'],
      multiSelect: def['multi_select'],
    }),
  },
  multiselect: {
    component: MultiSelectComponent,
    dataQa: ({ def }) => 'field-multiselect-' + def['attribut_name'],
    inputs: ({ def, control }) => ({
      values: def['values'],
      parentFormControl: control,
      keyLabel: 'label',
      keyValue: 'value',
      label: def['attribut_label'],
      searchBar: false,
      disabled: control?.disabled,
    }),
  },
  datalist: {
    component: DatalistComponent,
    dataQa: ({ def }) => 'field-datalist-' + def['attribut_label'] + '-' + def['attribut_name'],
    inputs: ({ def, control }) => ({
      designStyle: def['designStyle'],
      parentFormControl: control,
      application: def['application'],
      values: def['values'],
      api: def['api'],
      keyValue: def['keyValue'] || 'value',
      keyLabel: def['keyLabel'] || 'label',
      keyTitle: def['keyTitle'],
      multiple: def['multiple'],
      dataPath: def['data_path'],
      label: def['attribut_label'],
      required: def['required'],
      params: def['params'],
      data: def['data'],
      definition: def['definition'],
      filters: def['filters'],
      default: def['default'],
      nullDefault: def['nullDefault'],
      orderBy: def['orderBy'],
    }),
  },
  individuals: {
    component: IndividualsComponent,
    inputs: ({ def, control }) => ({
      parentFormControl: control,
      label: def['attribut_label'],
      moduleCode: def['module_code'],
      idList: def['id_list'],
      cdNom: def['cd_nom'],
    }),
  },
};

/**
 * Widgets available in ``pnx-dynamic-form``, by ``type_widget``. Provide another value to add
 * or replace widgets.
 */
export const WIDGET_REGISTRY = new InjectionToken<WidgetRegistry>('WIDGET_REGISTRY', {
  providedIn: 'root',
  factory: () => DEFAULT_WIDGETS,
});
