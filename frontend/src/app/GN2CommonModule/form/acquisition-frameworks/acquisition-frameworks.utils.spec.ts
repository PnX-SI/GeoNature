import { sortAcquisitionFrameworks } from './acquisition-frameworks.utils';

describe('sortAcquisitionFrameworks', () => {
  it('sorts by name', () => {
    const sorted = sortAcquisitionFrameworks([
      { acquisition_framework_name: 'Charlie' },
      { acquisition_framework_name: 'alpha' },
      { acquisition_framework_name: 'Bravo' },
    ]);
    expect(sorted.map((af) => af.acquisition_framework_name)).toEqual([
      'alpha',
      'Bravo',
      'Charlie',
    ]);
  });
});
