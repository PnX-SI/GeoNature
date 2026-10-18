import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ReactiveFormsModule, UntypedFormControl } from '@angular/forms';
import { NgSelectModule } from '@ng-select/ng-select';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatIconModule } from '@angular/material/icon';
import { AreasSelectComponent } from './areas-select.component';

describe('AreasSelectComponent', () => {
  let fixture: ComponentFixture<AreasSelectComponent>;
  let component: AreasSelectComponent;
  let control: UntypedFormControl;

  const items = [
    { id_area: 1, area_name: 'Alpes' },
    { id_area: 2, area_name: 'Vosges' },
  ];

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [AreasSelectComponent],
      imports: [ReactiveFormsModule, NgSelectModule, MatTooltipModule, MatIconModule],
    });
    fixture = TestBed.createComponent(AreasSelectComponent);
    component = fixture.componentInstance;
    control = new UntypedFormControl(null);
    component.parentFormControl = control;
    fixture.componentRef.setInput('designStyle', 'bootstrap');
    fixture.componentRef.setInput('items', items);
    fixture.componentRef.setInput('label', 'Zones');
  });

  it('displays the label', () => {
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('small').textContent).toBe('Zones');
  });

  it('displays the name of the area matching the control value', async () => {
    control.setValue(2);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('.ng-value-label').textContent.trim()).toBe(
      'Vosges'
    );
  });

  it('emits the term typed by the user', () => {
    fixture.detectChanges();
    const searched = jest.fn();
    component.search.subscribe(searched);
    component.typeahead$.next('alp');
    expect(searched).toHaveBeenCalledWith('alp');
  });

  it('stops emitting searches once destroyed', () => {
    fixture.detectChanges();
    const searched = jest.fn();
    component.search.subscribe(searched);
    fixture.destroy();
    component.typeahead$.next('alp');
    expect(searched).not.toHaveBeenCalled();
  });
});
