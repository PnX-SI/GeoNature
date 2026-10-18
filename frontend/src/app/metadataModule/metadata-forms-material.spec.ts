import { readFileSync } from 'fs';
import { join } from 'path';

// The acquisition framework and dataset forms only use Angular Material controls (for the fields
// that are not provided by a shared component with its own design).
describe.each([
  ['dataset form', 'datasets/dataset-form.component.html'],
  ['acquisition framework form', 'af/af-form.component.html'],
])('%s template', (_name, file) => {
  // comments are not rendered
  const template = readFileSync(join(__dirname, file), 'utf8').replace(/<!--[\s\S]*?-->/g, '');

  it('has no Bootstrap form control', () => {
    expect(template).not.toMatch(/form-control/);
  });

  it('has no native select, checkbox or ng-select', () => {
    expect(template).not.toMatch(/<select\b/);
    expect(template).not.toMatch(/type="checkbox"/);
    expect(template).not.toMatch(/<ng-select\b/);
  });

  it('has no input or textarea without matInput', () => {
    const fields = template.match(/<(input|textarea)\b[^>]*>/g) ?? [];
    expect(fields.length).toBeGreaterThan(0);
    fields.forEach((field) => expect(field).toMatch(/\bmatInput\b/));
  });
});
