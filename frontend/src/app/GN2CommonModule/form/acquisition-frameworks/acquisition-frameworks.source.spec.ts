import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { DataFormService } from '../data-form.service';
import { AcquisitionFrameworksSource } from './acquisition-frameworks.source';

describe('AcquisitionFrameworksSource', () => {
  it('loads all the acquisition frameworks, sorted by name', (done) => {
    const dfs = {
      getAcquisitionFrameworksList: jest.fn().mockReturnValue(
        of({
          items: [
            { id_acquisition_framework: 2, acquisition_framework_name: 'b' },
            { id_acquisition_framework: 1, acquisition_framework_name: 'a' },
          ],
        })
      ),
    };
    TestBed.configureTestingModule({ providers: [{ provide: DataFormService, useValue: dfs }] });
    TestBed.inject(AcquisitionFrameworksSource)
      .load()
      .subscribe((items) => {
        expect(dfs.getAcquisitionFrameworksList).toHaveBeenCalledWith({}, {}, 1, -1);
        expect(items.map((af) => af.id_acquisition_framework)).toEqual([1, 2]);
        done();
      });
  });
});
