import { readFileSync } from 'fs';
import { join } from 'path';

// The synthese, occtax and occhab forms only use Angular Material controls (for the fields that
// are not provided by a shared component with its own design).
const CONTRIB = join(__dirname, '../../../../../contrib');
const FORMS: Array<[string, string]> = [
  ['synthese search form', join(__dirname, 'synthese-form/synthese-form.component.html')],
  [
    'synthese advanced form',
    join(__dirname, 'synthese-form/advanced-form/synthese-advanced-form.component.html'),
  ],
  [
    'synthese columns',
    join(
      __dirname,
      '../../syntheseModule/synthese-results/synthese-list/synthese-list.component.html'
    ),
  ],
  ['dumb select', join(__dirname, 'dumb-select/dumb-select.component.html')],
  ['date', join(__dirname, 'date/date.component.html')],
  ['observers text', join(__dirname, 'observers-text/observers-text.component.html')],
  ['multiselect', join(__dirname, 'multiselect/multiselect.component.html')],
  ['occtax releve', join(CONTRIB, 'occtax/frontend/app/occtax-form/releve/releve.component.html')],
  [
    'occtax occurrence',
    join(CONTRIB, 'occtax/frontend/app/occtax-form/occurrence/occurrence.component.html'),
  ],
  [
    'occtax counting',
    join(CONTRIB, 'occtax/frontend/app/occtax-form/counting/counting.component.html'),
  ],
  [
    'occtax default values',
    join(CONTRIB, 'occtax/frontend/app/occtax-form/form-param/form-param.dialog.html'),
  ],
  [
    'occtax columns',
    join(CONTRIB, 'occtax/frontend/app/occtax-map-list/occtax-map-list.component.html'),
  ],
  [
    'occhab station form',
    join(
      CONTRIB,
      'gn_module_occhab/frontend/app/components/occhab-map-form/occhab-form.component.html'
    ),
  ],
  [
    'occhab filter',
    join(
      CONTRIB,
      'gn_module_occhab/frontend/app/components/occhab-map-list/occhab-map-list-filter.component.html'
    ),
  ],
];

describe.each(FORMS)('%s template', (_name, file) => {
  // comments are not rendered
  const template = readFileSync(file, 'utf8').replace(/<!--[\s\S]*?-->/g, '');

  it('has no native select, checkbox or ng-select', () => {
    expect(template).not.toMatch(/<select\b/);
    expect(template).not.toMatch(/type="checkbox"/);
    expect(template).not.toMatch(/<ng-select\b/);
  });

  it('has no input or textarea without matInput', () => {
    const fields = template.match(/<(input|textarea)\b[^>]*>/g) ?? [];
    fields.forEach((field) => expect(field).toMatch(/\bmatInput\b/));
  });

  it('has no Bootstrap form control on an input', () => {
    const fields = template.match(/<(input|textarea|select)\b[^>]*>/g) ?? [];
    fields.forEach((field) => expect(field).not.toMatch(/form-control/));
  });
});
