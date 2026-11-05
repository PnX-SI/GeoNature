import {
  AfterViewInit,
  Component,
  ElementRef,
  OnDestroy,
  OnInit,
  QueryList,
  ViewChild,
  ViewChildren,
} from '@angular/core';
import { FormControl, Validators } from '@angular/forms';
import { TaxonomyComponent } from '@geonature_common/form/taxonomy/taxonomy.component';
import { MatDialog } from '@angular/material/dialog';
import { TranslateService } from '@ngx-translate/core';
import { combineLatest, Subject, timer } from 'rxjs';
import { filter, map, takeUntil, tap } from 'rxjs/operators';
import { ConfigService } from '@geonature/services/config.service';
import { AdvancedSectionState } from '@geonature_common/form/advanced-section/advanced-section.component';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { FormService } from '@geonature_common/form/form.service';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { Nomenclature } from '@geonature_common/interfaces';
import { ConfirmationDialog } from '@geonature_common/others/modal-confirmation/confirmation.dialog';
import { OcctaxConfigService } from '../../../services/occtax-config.service';
import { OcctaxFormService } from '../../occtax-form.service';
import { OcctaxTaxaListService } from '../../taxa-list/taxa-list.service';
import {
  AdditionalFieldDefinition,
  Counting,
  NomenclatureResponse,
  Occurrence,
  OccurrenceForm,
  PhytoData,
  PhytoDataWithProperties,
  TaxonReference,
} from '../utils/interfaces';
import { PhytoAbundanceComponent } from '../phyto-abundance/phyto-abundance.component';
import { PhytoCountingStateService } from '../services/counting-state.service';
import { PhytoOccurrenceService } from '../services/occurrence.service';
import {
  getEligibleVegetationStratumRows,
  VegetationStratumRow,
} from '../utils/vegetation-strata.utils';

interface StratumRow extends VegetationStratumRow {
  counting: Counting;
}

/**
 * Coordinates phyto occurrence entry, including taxon selection, proof fields,
 * and vegetation-stratum rows linked to their abundance countings.
 *
 * The form and occurrence state are provided by `PhytoOccurrenceService`.
 * `PhytoModalComponent` extends this component, so keep shared behavior and
 * constructor dependencies compatible with the modal.
 *
 * TODO: Move proof and additional-field management into the modal.
 * TODO: [Angular Material v15 / Architecture] Consider refactoring into a Standalone Component
 */
@Component({
  selector: 'pnx-phyto-occurrence',
  templateUrl: './phyto-occurrence.component.html',
  styleUrls: ['./phyto-occurrence.component.scss', '../../occurrence/occurrence.component.scss'],
})
export class PhytoOccurrenceComponent implements OnInit, AfterViewInit, OnDestroy {
  public occurrenceForm: OccurrenceForm;

  public isCardExpanded = true;
  public taxonForm!: FormControl<Taxon | string | null>;
  public taxonFormFocus = false;

  public advancedSectionState: AdvancedSectionState = AdvancedSectionState.COLLAPSED;
  public displayProofFromElements = false;

  public strataColumns: StratumRow[] = [];

  @ViewChildren(PhytoAbundanceComponent)
  public phytoCountingComponents!: QueryList<PhytoAbundanceComponent>;

  @ViewChild(TaxonomyComponent)
  private taxonSearch?: TaxonomyComponent;

  @ViewChild('saveOccurrenceButton')
  private saveOccurrenceButton?: ElementRef<HTMLButtonElement>;

  get taxref(): TaxonReference | null {
    return this.phytoOccurrenceService.taxref.getValue();
  }
  get additionalFieldsForm(): AdditionalFieldDefinition[] {
    return this.phytoOccurrenceService.additionalFieldsForm;
  }

  private readonly destroy$ = new Subject<void>();

  constructor(
    public occtaxFormService: OcctaxFormService,
    private countingStateService: PhytoCountingStateService,
    public phytoOccurrenceService: PhytoOccurrenceService,
    private formService: FormService,
    private occtaxTaxaListService: OcctaxTaxaListService,
    private readonly dataFormService: DataFormService,
    public dialog: MatDialog,
    public configService: ConfigService,
    public occtaxConfigService: OcctaxConfigService,
    private readonly translate: TranslateService
  ) {}

  public ngOnInit(): void {
    this.occurrenceForm = this.phytoOccurrenceService.form;

    this.occurrenceForm.controls.id_nomenclature_exist_proof.valueChanges
      .pipe(
        map((id_nomenclature: number): boolean => {
          const cdNomenclature = this.phytoOccurrenceService.getCdNomenclatureById(
            id_nomenclature,
            this.phytoOccurrenceService.existProof_DATA
          );
          return cdNomenclature === '1';
        }),
        takeUntil(this.destroy$)
      )
      .subscribe((display: boolean) => (this.displayProofFromElements = display));

    this.advancedSectionState = this.occtaxConfigService.moduleConf.EXPANDED_TAXON_ADVANCED_DETAILS
      ? AdvancedSectionState.EXPANDED
      : AdvancedSectionState.COLLAPSED;

    this.initializeTaxRefSearch();

    combineLatest([
      this.occtaxFormService.occtaxData.pipe(
        filter((data: PhytoData): data is PhytoDataWithProperties => !!data?.releve?.properties)
      ),
      this.dataFormService.getNomenclature('STRATE_VEGETATION'),
    ])
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: ([data, nomenclature]: [PhytoDataWithProperties, NomenclatureResponse]) => {
          const strata = data.releve.properties.t_vegetation_stratum;
          this.strataColumns = getEligibleVegetationStratumRows(
            Array.isArray(strata) ? strata : [],
            nomenclature.values || []
          ).map((row) => ({ ...row, counting: {} }));
        },
        error: (error: unknown) => {
          console.error('Error loading vegetation strata for countings:', error);
        },
      });
  }

  ngAfterViewInit() {
    const taxonInput = document.getElementById('taxonInput');
    if (!taxonInput) {
      return;
    }
    taxonInput.focus();

    this.phytoOccurrenceService.occurrence
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => taxonInput.focus());

    taxonInput.addEventListener('focus', (event) => (this.taxonFormFocus = true));
    taxonInput.addEventListener('blur', (event) => (this.taxonFormFocus = false));
  }

  public ngOnDestroy(): void {
    this.resetOccurrenceForm();
    this.destroy$.next();
    this.destroy$.complete();
  }

  public setExistProofData(data: Nomenclature[]): void {
    this.phytoOccurrenceService.existProof_DATA = data;
  }

  public toggleCard(): void {
    this.isCardExpanded = !this.isCardExpanded;
  }

  private initializeTaxRefSearch(): void {
    this.taxonForm = new FormControl(null, [Validators.required, this.formService.taxonValidator]);

    this.taxonForm.valueChanges
      .pipe(
        tap((taxon) => {
          this.phytoOccurrenceService.taxref.next(null);
          if (taxon === '') {
            this.occurrenceForm.controls.nom_cite.setValue(null);
            this.occurrenceForm.controls.cd_nom.setValue(null);
            this.phytoOccurrenceService.form.markAsDirty();
          }
        }),
        filter(
          (taxon): taxon is Taxon =>
            taxon !== null && typeof taxon !== 'string' && taxon.cd_nom !== undefined
        ),
        tap((taxon) => this.phytoOccurrenceService.taxref.next(taxon)),
        map((taxon: Taxon) => ({
          nom_cite: (taxon.search_name || '').replace(/<[^>]*>/g, ''),
          cd_nom: taxon.cd_nom || null,
        })),
        tap(() => this.phytoOccurrenceService.form.markAsDirty()),
        takeUntil(this.destroy$)
      )
      .subscribe((values: { nom_cite: string; cd_nom: number | null }) =>
        this.handleTaxonSelection(values)
      );

    this.phytoOccurrenceService.occurrence
      .pipe(
        tap(() => this.taxonForm.setValue(null)),
        filter((occurrence): occurrence is Occurrence => !!occurrence),
        map(
          (occurrence): Taxon => ({
            ...(occurrence.taxref || {}),
            search_name: String(occurrence.nom_cite || '').replace(/<[^>]*>/g, ''),
          })
        ),
        takeUntil(this.destroy$)
      )
      .subscribe((taxon) => this.taxonForm.setValue(taxon));
  }

  private handleTaxonSelection(values: { nom_cite: string; cd_nom: number | null }): void {
    const currentOccurrence = this.phytoOccurrenceService.occurrence.getValue();
    if (currentOccurrence?.id_releve_occtax) {
      this.setOccurrenceTaxon(values);
      return;
    }

    const alreadyExists = this.occtaxTaxaListService.occurrences$
      .getValue()
      .some((taxon: Taxon) => taxon.cd_nom === values.cd_nom);
    if (!alreadyExists) {
      this.setOccurrenceTaxon(values);
      return;
    }

    const message = this.translate.instant('Occtax.Taxon.Messages.DuplicateTaxonConfirmation');
    this.dialog
      .open(ConfirmationDialog, {
        width: 'auto',
        position: { top: '5%' },
        data: { message, yesColor: 'basic', noColor: 'warn' },
      })
      .afterClosed()
      .pipe(takeUntil(this.destroy$))
      .subscribe((confirmed: boolean) => {
        if (confirmed) {
          this.setOccurrenceTaxon(values);
        } else {
          this.taxonForm.reset();
        }
      });
  }

  private setOccurrenceTaxon(values: { nom_cite: string; cd_nom: number | null }): void {
    this.occurrenceForm.controls.nom_cite.setValue(values.nom_cite);
    this.occurrenceForm.controls.cd_nom.setValue(values.cd_nom);
  }

  public get countings(): Counting[] {
    return this.countingStateService.countings || [];
  }

  public submitOccurrenceForm(): void {
    document.getElementById('taxonInput')?.focus();
    if (this.phytoOccurrenceService.form.valid) {
      this.phytoOccurrenceService.submitOccurrence();
    }
  }

  public resetOccurrenceForm(): void {
    this.phytoOccurrenceService.reset();
  }

  public selectAddOcc(): void {
    timer(50)
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => this.saveOccurrenceButton?.nativeElement.focus());
  }
}
