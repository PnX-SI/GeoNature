import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ReactiveFormsModule, UntypedFormControl } from '@angular/forms';
import { NoopAnimationsModule } from '@angular/platform-browser/animations';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatSelectModule } from '@angular/material/select';
import { Directive, Input } from '@angular/core';
import { DumbSelectComponent } from './dumb-select.component';

@Directive({ selector: '[disableControl]' })
class DisableControlStub {
  @Input() disableControl;
}

describe('DumbSelectComponent', () => {
  let fixture: ComponentFixture<DumbSelectComponent>;
  let component: DumbSelectComponent;

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [DumbSelectComponent, DisableControlStub],
      imports: [ReactiveFormsModule, NoopAnimationsModule, MatFormFieldModule, MatSelectModule],
    });
    fixture = TestBed.createComponent(DumbSelectComponent);
    component = fixture.componentInstance;
    component.parentFormControl = new UntypedFormControl(null);
    component.items = [{ id: 1, label: 'One', def: 'first' }] as any;
    component.comparedKey = 'id';
    component.displayedKey = 'label';
    component.titleKey = 'def';
    fixture.detectChanges();
  });

  it('compares the items by their compared key', () => {
    expect(component.compareFn({ id: 1, label: 'a' }, { id: 1, label: 'b' })).toBe(true);
    expect(component.compareFn({ id: 1 }, { id: 2 })).toBe(false);
    expect(component.compareFn(null, null)).toBe(true);
    expect(component.compareFn({ id: 1 }, null)).toBe(false);
  });

  // a function bound in the template on each change detection makes mat-select reinitialise its
  // selection endlessly, which freezes the browser
  it('gives the same compareWith function to the select on every change detection', () => {
    const select = () => fixture.nativeElement.querySelector('mat-select');
    expect(select()).not.toBeNull();
    const first = component.compareFn;
    fixture.detectChanges();
    fixture.detectChanges();
    expect(component.compareFn).toBe(first);
  });
});
