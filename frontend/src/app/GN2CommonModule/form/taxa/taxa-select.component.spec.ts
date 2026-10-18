import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Pipe, PipeTransform } from '@angular/core';
import { ReactiveFormsModule, UntypedFormControl } from '@angular/forms';
import { NgSelectModule } from '@ng-select/ng-select';
import { MatIconModule } from '@angular/material/icon';
import { TaxaSelectComponent } from './taxa-select.component';

@Pipe({ name: 'safeHTML' })
class SafeHtmlStubPipe implements PipeTransform {
  transform(value: string) {
    return value;
  }
}

describe('TaxaSelectComponent', () => {
  let fixture: ComponentFixture<TaxaSelectComponent>;
  let component: TaxaSelectComponent;
  let control: UntypedFormControl;

  const items = [
    { cd_nom: 1, displayName: 'Canis lupus' },
    { cd_nom: 2, displayName: 'Ursus arctos' },
  ];

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [TaxaSelectComponent, SafeHtmlStubPipe],
      imports: [ReactiveFormsModule, NgSelectModule, MatIconModule],
    });
    fixture = TestBed.createComponent(TaxaSelectComponent);
    component = fixture.componentInstance;
    control = new UntypedFormControl([]);
    component.parentFormControl = control;
    fixture.componentRef.setInput('items', items);
    fixture.componentRef.setInput('label', 'Taxons');
  });

  it('displays the names of the selected taxa', async () => {
    control.setValue([2]);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('.ng-value-label').textContent).toBe('Ursus arctos');
  });

  it('emits the term typed by the user', () => {
    fixture.detectChanges();
    const searched = jest.fn();
    component.search.subscribe(searched);
    component.typeahead$.next('can');
    expect(searched).toHaveBeenCalledWith('can');
  });
});
