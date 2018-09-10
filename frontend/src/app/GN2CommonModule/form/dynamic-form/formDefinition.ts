export class FormBase<T> {
  value: T;
  key: string;
  label: string;
  required: boolean;
  order: number;
  controlType: string;

  constructor(
    options: {
      value?: T;
      key?: string;
      label?: string;
      required?: boolean;
      order?: number;
      controlType?: string;
    } = {}
  ) {
    this.value = options.value;
    this.key = options.key || '';
    this.label = options.label || '';
    this.required = !!options.required;
    this.order = options.order === undefined ? 1 : options.order;
    this.controlType = options.controlType || '';
  }
}

export class TextboxQuestion extends FormBase<string> {
  controlType = 'textbox';
  type: string;

  constructor(options: {} = {}) {
    super(options);
    this.type = options['type'] || '';
  }
}

export class DropdownQuestion extends FormBase<string> {
  controlType = 'dropdown';
  options: { key: string; value: string }[] = [];

  constructor(options: {} = {}) {
    super(options);
    this.options = options['options'] || [];
  }
}

export class NomenclatureForm extends FormBase<string> {
  controlType = 'nomenclature';
  idNomenclatureType: number;

  constructor(options: {} = {}) {
    super(options);
    this.idNomenclatureType = options['idNomenclatureType'];
  }
}
