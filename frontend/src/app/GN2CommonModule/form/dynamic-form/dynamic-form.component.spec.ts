import { Component, Input, NO_ERRORS_SCHEMA, Pipe, PipeTransform } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ReactiveFormsModule, UntypedFormControl, UntypedFormGroup } from '@angular/forms';
import { ConfigService } from '@geonature/services/config.service';
import { DynamicFormService } from '../dynamic-form-generator/dynamic-form.service';
import { DynamicFormComponent } from './dynamic-form.component';
import { FormWidgetDirective } from './form-widget.directive';
import { WIDGET_REGISTRY, WidgetRegistry } from './widget-registry';

@Pipe({ name: 'safeHTML' })
class SafeHtmlStubPipe implements PipeTransform {
  transform(value: string) {
    return value;
  }
}

@Component({ selector: 'fake-nomenclature', template: '' })
class FakeNomenclatureComponent {
  @Input() label: string;
  @Input() parentFormControl;
}

describe('DynamicFormComponent', () => {
  let fixture: ComponentFixture<DynamicFormComponent>;
  let component: DynamicFormComponent;
  let form: UntypedFormGroup;
  let dynformService: { getFormDefValue: jest.Mock; setControl: jest.Mock };

  const registry: WidgetRegistry = {
    nomenclature: {
      component: FakeNomenclatureComponent,
      dataQa: ({ def }) => 'field-nomenclature-' + def.attribut_name,
      inputs: ({ def, control }) => ({ label: def.attribut_label, parentFormControl: control }),
    },
  };

  const create = (formDef: any) => {
    fixture = TestBed.createComponent(DynamicFormComponent);
    component = fixture.componentInstance;
    form = new UntypedFormGroup({ [formDef.attribut_name]: new UntypedFormControl(null) });
    component.formDef = formDef;
    component.form = form;
    fixture.detectChanges();
  };

  beforeEach(() => {
    dynformService = {
      getFormDefValue: jest.fn((def, key) => def[key]),
      setControl: jest.fn(),
    };
    TestBed.configureTestingModule({
      imports: [ReactiveFormsModule],
      declarations: [
        DynamicFormComponent,
        FormWidgetDirective,
        FakeNomenclatureComponent,
        SafeHtmlStubPipe,
      ],
      providers: [
        { provide: DynamicFormService, useValue: dynformService },
        { provide: ConfigService, useValue: {} },
        { provide: WIDGET_REGISTRY, useValue: registry },
      ],
      schemas: [NO_ERRORS_SCHEMA],
    });
  });

  it('renders a native widget', () => {
    create({ type_widget: 'text', attribut_name: 'field', attribut_label: 'Name' });
    expect(fixture.nativeElement.querySelector('input[type=text]')).not.toBeNull();
    expect(component.widgetEntry).toBeUndefined();
  });

  it('renders the widget of the registry with the control of the field', () => {
    create({ type_widget: 'nomenclature', attribut_name: 'field', attribut_label: 'Etat' });
    const widget = fixture.debugElement.query(
      (el) => el.componentInstance instanceof FakeNomenclatureComponent
    );
    expect(widget.componentInstance.label).toBe('Etat');
    expect(widget.componentInstance.parentFormControl).toBe(form.get('field'));
    expect(widget.nativeElement.getAttribute('data-qa')).toBe('field-nomenclature-field');
  });

  it('renders nothing for an unknown widget', () => {
    create({ type_widget: 'unknown', attribut_name: 'field' });
    expect(component.widgetEntry).toBeUndefined();
    expect(fixture.nativeElement.querySelector('fake-nomenclature')).toBeNull();
  });

  it('hides the field when hidden', () => {
    create({ type_widget: 'text', attribut_name: 'field', hidden: true });
    expect(fixture.nativeElement.firstElementChild.style.display).toBe('none');
  });

  it('applies the constraints of the definition on the control', () => {
    create({ type_widget: 'text', attribut_name: 'field', required: true });
    expect(dynformService.setControl).toHaveBeenCalledWith(
      form.get('field'),
      expect.objectContaining({ required: true })
    );
  });
});
