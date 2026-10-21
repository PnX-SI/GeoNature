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
import { UntypedFormControl, UntypedFormGroup, Validators } from '@angular/forms';
import { combineLatest, Subject, timer } from 'rxjs';
import { filter, map, takeUntil, tap } from 'rxjs/operators';
import { OcctaxFormService } from '../../occtax-form.service';
import { PhytoOccurrenceService } from './occurrence.service';
import { PhytoCountingsService } from '../phyto-abundance/countings.service';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { FormService } from '@geonature_common/form/form.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { OcctaxTaxaListService } from '../../taxa-list/taxa-list.service';
import { ConfirmationDialog } from '@geonature_common/others/modal-confirmation/confirmation.dialog';
import { MatDialog } from '@angular/material/dialog';
import { TranslateService } from '@ngx-translate/core';
import { ConfigService } from '@geonature/services/config.service';
import { OcctaxConfigService } from '../../../services/occtax-config.service';
import { PhytoAbundanceComponent } from '../phyto-abundance/phyto-abundance.component';
import { AdvancedSectionState } from '@geonature_common/form/advanced-section/advanced-section.component';

// Mirrors pr_occtax.t_vegetation_stratum
export interface VegetationStratum {
  id_vegetation_stratum: number | null;
  id_releve_occtax?: number;
  id_nomenclature_vegetation_stratum?: number | null;
  min_height?: number | null;
  max_height?: number | null;
  average_height?: number | null;
  percentage_cover_vegetation_stratum?: number | null;
}

interface Nomenclature {
  id_nomenclature: number;
  label_default: string;
  mnemonique: string;
}

interface NomenclatureResponse {
  values: Nomenclature[];
}

interface StratumRow {
  id: number;
  label: string;
  counting: any;
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
 */
@Component({
  selector: 'pnx-phyto-occurrence',
  templateUrl: './phyto-occurrence.component.html',
  styleUrls: ['./phyto-occurrence.component.scss', '../../occurrence/occurrence.component.scss'],
})
export class PhytoOccurrenceComponent implements OnInit, AfterViewInit, OnDestroy {
  public occurrenceForm: UntypedFormGroup;

  public taxonForm!: UntypedFormControl;
  public taxonFormFocus = false;

  public advancedSectionState: AdvancedSectionState = AdvancedSectionState.COLLAPSED;
  public displayProofFromElements = false;

  public strataColumns: StratumRow[] = [];

  @ViewChildren(PhytoAbundanceComponent)
  public phytoCountingComponents!: QueryList<PhytoAbundanceComponent>;

  @ViewChild('saveOccurrenceButton')
  private saveOccurrenceButton?: ElementRef<HTMLButtonElement>;

  get taxref(): any {
    return this.phytoOccurrenceService.taxref.getValue();
  }
  get additionalFieldsForm(): any[] {
    return this.phytoOccurrenceService.additionalFieldsForm;
  }

  private readonly destroy$ = new Subject<void>();

  constructor(
    public occtaxFormService: OcctaxFormService,
    private phytoCountingsService: PhytoCountingsService,
    public phytoOccurrenceService: PhytoOccurrenceService,
    private formService: FormService,
    private occtaxTaxaListService: OcctaxTaxaListService,
    private readonly dataFormService: DataFormService,
    public dialog: MatDialog,
    public configService: ConfigService,
    public occtaxConfigService: OcctaxConfigService,
    private readonly translate: TranslateService
  ) { }

  public ngOnInit(): void {
    this.occurrenceForm = this.phytoOccurrenceService.form;

    this.occurrenceForm
      .get('id_nomenclature_exist_proof')
      .valueChanges.pipe(
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
      this.occtaxFormService.occtaxData.pipe(filter((data: any) => !!data?.releve?.properties)),
      this.dataFormService.getNomenclature('STRATE_VEGETATION'),
    ])
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: ([data, nomenclature]: [any, NomenclatureResponse]) => {
          const strata = data.releve.properties.t_vegetation_stratum;
          this.setStrataColumns(Array.isArray(strata) ? strata : [], nomenclature.values || []);
        },
        error: (error: unknown) => {
          //TODO: move error string in i18n
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

    // Keep the search ready for the next taxon when the current occurrence changes.
    this.phytoOccurrenceService.occurrence.subscribe(() => taxonInput.focus());

    // Track focus so the required-field error is hidden while the search is active.
    taxonInput.addEventListener('focus', (event) => (this.taxonFormFocus = true));
    taxonInput.addEventListener('blur', (event) => (this.taxonFormFocus = false));
  }

  public ngOnDestroy(): void {
    this.resetOccurrenceForm();
    this.destroy$.next();
    this.destroy$.complete();
  }

  public setExistProofData(data: any): void {
    this.phytoOccurrenceService.existProof_DATA = data;
  }

  private initializeTaxRefSearch(): void {
    this.taxonForm = new UntypedFormControl(null, [
      Validators.required,
      this.formService.taxonValidator,
    ]);

    this.taxonForm.valueChanges
      .pipe(
        tap(() => this.phytoOccurrenceService.taxref.next(null)),
        filter(
          (taxon: any): taxon is Taxon =>
            taxon !== null && typeof taxon !== 'string' && taxon.cd_nom !== undefined
        ),
        tap((taxon: any) => this.phytoOccurrenceService.taxref.next(taxon)),
        map((taxon: Taxon) => ({
          nom_cite: (taxon.search_name || '').replace(/<[^>]*>/g, ''),
          cd_nom: taxon.cd_nom || null,
        })),
        tap(() => this.phytoOccurrenceService.form.markAsDirty()),
        takeUntil(this.destroy$)
      )
      .subscribe((values: { nom_cite: string; cd_nom: number | null; }) => this.handleTaxonSelection(values));

    this.phytoOccurrenceService.occurrence
      .pipe(
        tap(() => this.taxonForm.setValue(null)),
        filter((occurrence: any) => !!occurrence),
        map(
          (occurrence: any): Taxon => ({
            ...(occurrence.taxref || {}),
            search_name: String(occurrence.nom_cite || '').replace(/<[^>]*>/g, ''),
          })
        ),
        takeUntil(this.destroy$)
      )
      .subscribe((taxon: any) => this.taxonForm.setValue(taxon));
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
    this.occurrenceForm.get('nom_cite').setValue(values.nom_cite);
    this.occurrenceForm.get('cd_nom').setValue(values.cd_nom);
  }

  public get countings(): any[] {
    return this.phytoCountingsService.countings || [];
  }

  private setStrataColumns(strata: VegetationStratum[], nomenclatures: Nomenclature[]): void {
    const labelByNomenclatureId = new Map(
      nomenclatures.map((nomenclature) => [
        nomenclature.id_nomenclature,
        nomenclature.label_default,
      ])
    );
    const mnemoByNomenclatureId = new Map(
      nomenclatures.map((nomenclature) => [
        nomenclature.id_nomenclature,
        nomenclature.mnemonique,
      ])
    );
    // const countingByStratumId = new Map(
    //   this.countings.map((counting) => [counting.id_nomenclature_vegetation_stratum, counting])
    // );

    this.strataColumns = strata.map((stratum) => {
      const idNomenclatureVegetationStratum = stratum.id_nomenclature_vegetation_stratum;

      // the only required thing is to have at least 1 counting but try not to create a counting for each stratum
      return {
        id: idNomenclatureVegetationStratum,
        label: labelByNomenclatureId.get(idNomenclatureVegetationStratum) || '',
        mnemonique: mnemoByNomenclatureId.get(idNomenclatureVegetationStratum) || '',
        // counting: countingByStratumId.get(idNomenclatureVegetationStratum) || {},
        counting: {},
      };
    })
      .filter((row) => row.label !== '');
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
