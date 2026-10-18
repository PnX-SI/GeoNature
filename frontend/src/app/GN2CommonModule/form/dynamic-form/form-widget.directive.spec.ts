import { Component, Input } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { UntypedFormControl, UntypedFormGroup } from '@angular/forms';
import { ConfigService } from '@geonature/services/config.service';
import { FormWidgetDirective } from './form-widget.directive';
import { FormDef, WidgetEntry } from './widget-registry';

@Component({ selector: 'fake-widget', template: '' })
class FakeWidgetComponent {
  @Input() label: string;
  @Input() parentFormControl;
  @Input() withDefault = 'default';
  changes = 0;
  destroyed = false;
  ngOnChanges() {
    this.changes++;
  }
  ngOnDestroy() {
    this.destroyed = true;
  }
}

@Component({ selector: 'other-widget', template: '' })
class OtherWidgetComponent {
  @Input() label: string;
}

@Component({
  template: `
    <ng-container
      [pnxFormWidget]="entry"
      [widgetDef]="def"
      [widgetRawDef]="def"
      [widgetForm]="form"
    ></ng-container>
  `,
})
class HostComponent {
  entry: WidgetEntry;
  def: FormDef;
  form: UntypedFormGroup;
}

describe('FormWidgetDirective', () => {
  let fixture: ComponentFixture<HostComponent>;
  let host: HostComponent;
  let inputs: jest.Mock;

  const widget = (): FakeWidgetComponent =>
    fixture.debugElement.query((el) => el.componentInstance instanceof FakeWidgetComponent)
      ?.componentInstance;
  const widgetElement = (): HTMLElement => fixture.nativeElement.querySelector('fake-widget');

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [HostComponent, FormWidgetDirective, FakeWidgetComponent, OtherWidgetComponent],
      providers: [{ provide: ConfigService, useValue: {} }],
    });
    fixture = TestBed.createComponent(HostComponent);
    host = fixture.componentInstance;
    host.form = new UntypedFormGroup({ field: new UntypedFormControl('v') });
    host.def = { type_widget: 'fake', attribut_name: 'field', attribut_label: 'Field' };
    inputs = jest.fn(({ def, control }) => ({
      label: def.attribut_label,
      parentFormControl: control,
    }));
    host.entry = {
      component: FakeWidgetComponent,
      inputs,
      dataQa: ({ def }) => 'field-fake-' + def.attribut_name,
      hostStyle: { display: 'block' },
    };
  });

  it('renders the component with its inputs, the control of the field included', () => {
    fixture.detectChanges();
    expect(widget().label).toBe('Field');
    expect(widget().parentFormControl).toBe(host.form.get('field'));
  });

  it('gives the definition, the raw definition, the form and the config to the entry', () => {
    fixture.detectChanges();
    expect(inputs).toHaveBeenCalledWith(
      expect.objectContaining({
        def: host.def,
        rawDef: host.def,
        form: host.form,
        control: host.form.get('field'),
        config: expect.anything(),
      })
    );
  });

  it('sets inputs that are undefined, like a template binding does', () => {
    host.entry = { ...host.entry, inputs: () => ({ withDefault: undefined }) };
    fixture.detectChanges();
    expect(widget().withDefault).toBeUndefined();
  });

  it('sets the data-qa attribute and the host style', () => {
    fixture.detectChanges();
    expect(widgetElement().getAttribute('data-qa')).toBe('field-fake-field');
    expect(widgetElement().style.display).toBe('block');
  });

  it('updates the inputs when the definition changes', () => {
    fixture.detectChanges();
    host.def = { ...host.def, attribut_label: 'Other label' };
    fixture.detectChanges();
    expect(widget().label).toBe('Other label');
  });

  it('does not set again an input whose value did not change', () => {
    fixture.detectChanges();
    const changes = widget().changes;
    fixture.detectChanges();
    fixture.detectChanges();
    expect(widget().changes).toBe(changes);
  });

  it('renders nothing without entry', () => {
    host.entry = undefined;
    fixture.detectChanges();
    expect(widget()).toBeUndefined();
  });

  it('replaces the component when the entry changes', () => {
    fixture.detectChanges();
    const first = widget();
    host.entry = { component: OtherWidgetComponent, inputs: () => ({ label: 'x' }) };
    fixture.detectChanges();
    expect(first.destroyed).toBe(true);
    expect(widgetElement()).toBeNull();
    expect(fixture.nativeElement.querySelector('other-widget')).not.toBeNull();
  });

  it('destroys the component with the directive', () => {
    fixture.detectChanges();
    const first = widget();
    fixture.destroy();
    expect(first.destroyed).toBe(true);
  });
});
