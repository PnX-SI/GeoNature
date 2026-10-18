import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Pipe, PipeTransform } from '@angular/core';
import { ReactiveFormsModule, UntypedFormControl } from '@angular/forms';
import { HarnessLoader } from '@angular/cdk/testing';
import { TestbedHarnessEnvironment } from '@angular/cdk/testing/testbed';
import { NoopAnimationsModule } from '@angular/platform-browser/animations';
import { NgbCollapseModule } from '@ng-bootstrap/ng-bootstrap';
import { MatAutocompleteModule } from '@angular/material/autocomplete';
import { MatAutocompleteHarness } from '@angular/material/autocomplete/testing';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSelectModule } from '@angular/material/select';
import { MatSelectHarness } from '@angular/material/select/testing';
import { MatTooltipModule } from '@angular/material/tooltip';
import { of } from 'rxjs';
import { TaxonomySelectComponent } from './taxonomy-select.component';

@Pipe({ name: 'translate' })
class TranslateStubPipe implements PipeTransform {
  transform(key: string) {
    return key;
  }
}

describe('TaxonomySelectComponent (material design)', () => {
  let fixture: ComponentFixture<TaxonomySelectComponent>;
  let component: TaxonomySelectComponent;
  let loader: HarnessLoader;
  let control: UntypedFormControl;
  let searchFn: jest.Mock;

  const taxa = [
    { cd_nom: 1, search_name: '<i>Canis lupus</i>', nom_valide: '<i>Canis lupus</i> Linnaeus' },
    { cd_nom: 2, search_name: 'Ursus arctos', nom_valide: 'Ursus arctos Linnaeus' },
  ];
  const autocomplete = () => loader.getHarness(MatAutocompleteHarness);

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [TaxonomySelectComponent, TranslateStubPipe],
      imports: [
        ReactiveFormsModule,
        NoopAnimationsModule,
        NgbCollapseModule,
        MatAutocompleteModule,
        MatButtonModule,
        MatFormFieldModule,
        MatIconModule,
        MatInputModule,
        MatProgressSpinnerModule,
        MatSelectModule,
        MatTooltipModule,
      ],
    });
    fixture = TestBed.createComponent(TaxonomySelectComponent);
    component = fixture.componentInstance;
    control = new UntypedFormControl(null);
    component.parentFormControl = control;
    component.charNumber = 3;
    component.label = 'Taxon';
    searchFn = jest.fn().mockReturnValue(of(taxa));
    component.searchFn = searchFn;
    fixture.detectChanges();
    loader = TestbedHarnessEnvironment.loader(fixture);
  });

  it('is the default design: a material autocomplete, with the attributes of the e2e tests', () => {
    const input: HTMLInputElement = fixture.nativeElement.querySelector('input[matInput]');
    expect(input).not.toBeNull();
    expect(input.id).toBe('taxonInput');
    expect(input.getAttribute('data-qa')).toBe('taxonomy-form-input');
    expect(fixture.nativeElement.querySelector('input[ngbTypeahead]')).toBeNull();
    expect(input.closest('mat-form-field').querySelector('mat-label').textContent).toBe('Taxon');
  });

  it('lists the taxa of the search with their search name', async () => {
    const auto = await autocomplete();
    await auto.enterText('can');
    expect(searchFn).toHaveBeenCalledWith('can', { regne: null, group2_inpn: null });
    const options = await auto.getOptions();
    expect(await options[1].getText()).toBe('Ursus arctos');
    expect(fixture.nativeElement.ownerDocument.querySelector('mat-option i')?.textContent).toBe(
      'Canis lupus'
    );
  });

  it('does not search before charNumber characters', async () => {
    await (await autocomplete()).enterText('ca');
    expect(searchFn).not.toHaveBeenCalled();
  });

  it('writes the taxon in the control and displays it without HTML tags', async () => {
    const picked = jest.fn();
    component.onChange.subscribe(picked);
    const auto = await autocomplete();
    await auto.enterText('can');
    await auto.selectOption({ text: 'Ursus arctos' });
    expect(control.value).toEqual(taxa[1]);
    expect(await auto.getValue()).toBe('Ursus arctos Linnaeus');
    expect(picked.mock.calls[0][0].item).toEqual(taxa[1]);
  });

  it('displays the label of a taxon without HTML tags', () => {
    expect(component.formatter(taxa[0])).toBe('Canis lupus Linnaeus');
  });

  it('shows a message when no taxon was found', async () => {
    searchFn.mockReturnValue(of([]));
    await (await autocomplete()).enterText('zzzz');
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('mat-hint').textContent.trim()).toBe(
      'TaxonSearch.Messages.NoTaxonFound'
    );
  });

  describe('advanced filters', () => {
    const filterButton = () => fixture.nativeElement.querySelector('button[mat-icon-button]');

    it('have no button by default', () => {
      expect(filterButton()).toBeNull();
    });

    it('are shown with the button, and give the regne and group to the search', async () => {
      fixture.componentRef.setInput('displayAdvancedFilters', true);
      fixture.componentRef.setInput('regnesAndGroup', {
        Animalia: ['Mammifères'],
        Plantae: ['Fougères'],
      });
      fixture.detectChanges();
      expect(component.isCollapseTaxonomy).toBe(true);
      filterButton().click();
      fixture.detectChanges();
      expect(component.isCollapseTaxonomy).toBe(false);

      const regne = (await loader.getAllHarnesses(MatSelectHarness))[0];
      await regne.clickOptions({ text: 'Animalia' });
      const group = (await loader.getAllHarnesses(MatSelectHarness))[1];
      await group.clickOptions({ text: 'Mammifères' });
      await (await autocomplete()).enterText('can');
      expect(searchFn).toHaveBeenCalledWith('can', {
        regne: 'Animalia',
        group2_inpn: 'Mammifères',
      });
    });

    it('empties the group when the regne is unset', async () => {
      fixture.componentRef.setInput('displayAdvancedFilters', true);
      fixture.componentRef.setInput('regnesAndGroup', { Animalia: ['Mammifères'] });
      component.regneControl.setValue('Animalia');
      component.groupControl.setValue('Mammifères');
      component.regneControl.setValue(null);
      expect(component.groupControl.value).toBeNull();
    });
  });
});
