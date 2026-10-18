import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { DataFormService } from '../data-form.service';
import { ObserversSource } from './observers.source';

describe('ObserversSource', () => {
  let dfs: { getObservers: jest.Mock; getObserversFromCode: jest.Mock };
  let source: ObserversSource;

  beforeEach(() => {
    dfs = {
      getObservers: jest.fn().mockReturnValue(of([{ id_role: 1 }])),
      getObserversFromCode: jest.fn().mockReturnValue(of([{ id_role: 2 }])),
    };
    TestBed.configureTestingModule({ providers: [{ provide: DataFormService, useValue: dfs }] });
    source = TestBed.inject(ObserversSource);
  });

  it('loads all the users by default', () => {
    source.load().subscribe();
    expect(dfs.getObservers).toHaveBeenCalledWith();
  });

  it('loads the users of a list by id', () => {
    source.load({ idMenu: 9 }).subscribe();
    expect(dfs.getObservers).toHaveBeenCalledWith(9);
  });

  it('loads the users of a list by code, when there is no id', () => {
    let result;
    source.load({ codeList: 'obs' }).subscribe((r) => (result = r));
    expect(dfs.getObserversFromCode).toHaveBeenCalledWith('obs');
    expect(result).toEqual([{ id_role: 2 }]);
  });

  it('prefers the id to the code', () => {
    source.load({ idMenu: 9, codeList: 'obs' }).subscribe();
    expect(dfs.getObservers).toHaveBeenCalledWith(9);
    expect(dfs.getObserversFromCode).not.toHaveBeenCalled();
  });
});
