import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Component, Input, Pipe, PipeTransform } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { of, Subject } from 'rxjs';
import { Nomenclature } from '../../interfaces';
import { NomenclatureComponent } from './nomenclature.component';
import { NomenclatureSource } from './nomenclature.source';

@Pipe({ name: 'translate' })
class TranslateStubPipe implements PipeTransform {
  transform(key: string) {
    return key;
  }
}

@Component({ selector: 'pnx-items-select', template: '' })
class ItemsSelectStub {
  @Input() items;
  @Input() parentFormControl;
  @Input() label;
  @Input() class;
  @Input() multiSelect;
  @Input() clearable;
  @Input() loading;
  @Input() bindLabel;
  @Input() bindValue;
  @Input() placeholder;
  @Input() compareWith;
  @Input() appendTo;
  @Input() clearAllText;
  @Input() dataQa;
  @Input() qaTest;
  @Input() optionTemplate;
  @Input() autoSelectKey;
}

describe('NomenclatureComponent (connected)', () => {
  let fixture: ComponentFixture<NomenclatureComponent>;
  let component: NomenclatureComponent;
  let source: { load: jest.Mock };
  let translate: { currentLang: string; onLangChange: Subject<{ lang: string }> };

  const values = [
    { id_nomenclature: 10, cd_nomenclature: 'A' },
    { id_nomenclature: 20, cd_nomenclature: 'B' },
  ] as Nomenclature[];
  const select = () => fixture.debugElement.children[0].componentInstance as ItemsSelectStub;

  beforeEach(() => {
    source = { load: jest.fn().mockReturnValue(of(values)) };
    translate = { currentLang: 'fr', onLangChange: new Subject() };
    TestBed.configureTestingModule({
      declarations: [NomenclatureComponent, ItemsSelectStub, TranslateStubPipe],
      providers: [
        { provide: NomenclatureSource, useValue: source },
        { provide: TranslateService, useValue: translate },
      ],
    });
    fixture = TestBed.createComponent(NomenclatureComponent);
    component = fixture.componentInstance;
    component.parentFormControl = new UntypedFormControl(null);
    component.codeNomenclatureType = 'ETA_BIO';
  });

  it('loads the nomenclature type and gives items and language attributes to the select', () => {
    component.regne = 'Animalia';
    component.cdNomenclatures = ['1'];
    fixture.detectChanges();
    expect(source.load).toHaveBeenCalledWith({
      codeNomenclatureType: 'ETA_BIO',
      regne: 'Animalia',
      group2Inpn: undefined,
      group3Inpn: undefined,
      cdNomenclatures: ['1'],
    });
    expect(select().items).toEqual(values);
    expect(select().bindLabel).toBe('label_fr');
    expect(component.definitionLang).toBe('definition_fr');
    expect(select().appendTo).toBe('body');
  });

  it('emits labelsLoaded with the items', () => {
    const loaded = jest.fn();
    component.labelsLoaded.subscribe(loaded);
    fixture.detectChanges();
    expect(loaded).toHaveBeenCalledWith(values);
  });

  it('emits the cd_nomenclature of the current value once loaded and on value change', () => {
    const emitted = jest.fn();
    component.$currentCdNomenclature.subscribe(emitted);
    component.parentFormControl.setValue(10);
    fixture.detectChanges();
    expect(emitted).toHaveBeenLastCalledWith('A');
    component.parentFormControl.setValue(20);
    expect(emitted).toHaveBeenLastCalledWith('B');
    component.parentFormControl.setValue(99);
    expect(emitted).toHaveBeenLastCalledWith(null);
  });

  it('updates the language attributes when the language changes', () => {
    fixture.detectChanges();
    translate.currentLang = 'en';
    translate.onLangChange.next({ lang: 'en' });
    fixture.detectChanges();
    expect(select().bindLabel).toBe('label_en');
    expect(component.definitionLang).toBe('definition_en');
  });

  it('reloads the items when the regne changes', () => {
    fixture.detectChanges();
    source.load.mockClear();
    component.regne = 'Plantae';
    component.ngOnChanges({ regne: { currentValue: 'Plantae', firstChange: false } } as any);
    expect(source.load).toHaveBeenCalledWith(expect.objectContaining({ regne: 'Plantae' }));
  });
});
