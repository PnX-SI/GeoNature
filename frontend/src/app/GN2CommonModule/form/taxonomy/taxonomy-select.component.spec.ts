import { ComponentFixture, fakeAsync, TestBed, tick } from '@angular/core/testing';
import { NO_ERRORS_SCHEMA, Pipe, PipeTransform } from '@angular/core';
import { ReactiveFormsModule, UntypedFormControl } from '@angular/forms';
import { of, throwError } from 'rxjs';
import { TaxonomySelectComponent } from './taxonomy-select.component';

@Pipe({ name: 'translate' })
class TranslateStubPipe implements PipeTransform {
  transform(key: string) {
    return key;
  }
}

describe('TaxonomySelectComponent', () => {
  let fixture: ComponentFixture<TaxonomySelectComponent>;
  let component: TaxonomySelectComponent;
  let searchFn: jest.Mock;

  const search = (term: string) => {
    let result;
    component.searchTaxon(of(term)).subscribe((r) => (result = r));
    tick(400);
    return result;
  };

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [ReactiveFormsModule],
      declarations: [TaxonomySelectComponent, TranslateStubPipe],
      schemas: [NO_ERRORS_SCHEMA],
    });
    fixture = TestBed.createComponent(TaxonomySelectComponent);
    component = fixture.componentInstance;
    component.parentFormControl = new UntypedFormControl(null);
    searchFn = jest.fn().mockReturnValue(of([{ cd_nom: 1 }]));
    component.searchFn = searchFn;
    component.charNumber = 3;
    fixture.detectChanges();
  });

  it('searches taxa with the term and the filters once enough characters are typed', fakeAsync(() => {
    component.regneControl.setValue('Animalia');
    component.groupControl.setValue('Mammifères');
    expect(search('can')).toEqual([{ cd_nom: 1 }]);
    expect(searchFn).toHaveBeenCalledWith('can', { regne: 'Animalia', group2_inpn: 'Mammifères' });
    expect(component.noResult).toBe(false);
    expect(component.isLoading).toBe(false);
  }));

  it('does not search before charNumber characters', fakeAsync(() => {
    expect(search('ca')).toEqual([]);
    expect(searchFn).not.toHaveBeenCalled();
  }));

  it('flags when nothing was found', fakeAsync(() => {
    searchFn.mockReturnValue(of([]));
    search('canis');
    expect(component.noResult).toBe(true);
  }));

  it('gives an empty list when the search fails', fakeAsync(() => {
    searchFn.mockReturnValue(throwError(() => new Error('boom')));
    expect(search('canis')).toEqual([]);
    expect(component.noResult).toBe(true);
  }));

  it('formats the selected taxon without HTML tags', () => {
    component.displayedLabel = 'nom_valide';
    expect(component.formatter({ nom_valide: '<i>Canis</i> lupus' })).toBe('Canis lupus');
    expect(component.formatter(null)).toBe('');
  });

  it('emits the selected taxon', () => {
    const selected = jest.fn();
    component.onChange.subscribe(selected);
    component.taxonSelected({ item: { cd_nom: 1 } } as any);
    expect(selected).toHaveBeenCalledWith({ item: { cd_nom: 1 } });
  });

  it('emits onDelete when the control is emptied', () => {
    const deleted = jest.fn();
    component.onDelete.subscribe(deleted);
    component.parentFormControl.setValue('');
    expect(deleted).toHaveBeenCalled();
    deleted.mockClear();
    component.parentFormControl.setValue('can');
    expect(deleted).not.toHaveBeenCalled();
  });

  it('lists the regnes of the filters', () => {
    component.regnesAndGroup = { Animalia: ['Mammifères'], Plantae: ['Fougères'] };
    expect(component.regnes).toEqual(['Animalia', 'Plantae']);
    component.regnesAndGroup = undefined;
    expect(component.regnes).toEqual([]);
  });

  it('empties the group when the regne is emptied', () => {
    component.groupControl.setValue('Mammifères');
    component.regneControl.setValue('');
    expect(component.groupControl.value).toBeNull();
  });

  it('resets the input and the filters', () => {
    component.parentFormControl.setValue('can');
    component.regneControl.setValue('Animalia');
    component.refreshAllInput();
    expect(component.parentFormControl.value).toBeNull();
    expect(component.regneControl.value).toBeNull();
  });
});
