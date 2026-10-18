import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { DataFormService } from '../data-form.service';
import { AreasSource } from './areas.source';

describe('AreasSource', () => {
  const load = (areas: any[]) => {
    const dfs = { getAreas: jest.fn().mockReturnValue(of(areas)) };
    TestBed.configureTestingModule({ providers: [{ provide: DataFormService, useValue: dfs }] });
    let result;
    TestBed.inject(AreasSource)
      .load({ type_code: ['COM'] })
      .subscribe((r) => (result = r));
    expect(dfs.getAreas).toHaveBeenCalledWith({ type_code: ['COM'] });
    return result;
  };

  it('adds the department to the name of municipalities', () => {
    const result = load([
      { id_area: 1, area_name: 'Paris', area_code: '75056', area_type: { type_code: 'COM' } },
    ]);
    expect(result[0].area_name).toBe('Paris (75) ');
  });

  it('leaves other areas as they are', () => {
    const result = load([
      { id_area: 1, area_name: 'Paris', area_code: '75', area_type: { type_code: 'DEP' } },
    ]);
    expect(result[0].area_name).toBe('Paris');
  });
});
