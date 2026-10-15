import { Component, OnInit, OnDestroy, QueryList, ViewChildren } from '@angular/core';
import { UntypedFormControl, UntypedFormGroup, Validators } from '@angular/forms';
import { combineLatest, Subscription, Subject } from 'rxjs';
import { map, filter, tap, takeUntil } from 'rxjs/operators';
import { OcctaxFormService } from '../../occtax-form.service';
import { PhytoOccurrenceService } from './occurrence.service';
import { PhytoCountingsService } from '../phyto-counting/countings.service';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { FormService } from '@geonature_common/form/form.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { OcctaxTaxaListService } from '../../taxa-list/taxa-list.service'; // TODO: change this to reference phyto-taxa-list
import { ConfirmationDialog } from '@geonature_common/others/modal-confirmation/confirmation.dialog';
import { MatDialog } from '@angular/material/dialog';
import { ConfigService } from '@geonature/services/config.service';
import { OcctaxConfigService } from '../../../services/occtax-config.service';
import { PhytoCountingComponent } from '../phyto-counting/phyto-counting.component';
import { AdvancedSectionState } from '@geonature_common/form/advanced-section/advanced-section.component';

// As defined in pr_occtax.t_vegetation_stratum
export interface VegetationStratum {
  id_vegetation_stratum: number | null; // primary key
  id_releve_occtax?: number;
  id_nomenclature_vegetation_stratum?: number | null;
  min_height?: number | null;
  max_height?: number | null;
  average_height?: number | null;
  percentage_cover_vegetation_stratum?: number | null;
}

// This is the type of all data from t_nomenclatures table
// TODO: should use the same type for all nomenclature data
export interface Nomenclature {
  id_nomenclature: number;
  label_default: string;
}

export interface StratumRow {
  id: number;
  label: string;
  counting: any;
}

/**
 * TODO: move proof management in modal component
 * move additional fields management not in use here in modal component
 */
@Component({
  selector: 'pnx-phyto-occurrence',
  templateUrl: './phyto-occurrence.component.html',
  styleUrls: ['./phyto-occurrence.component.scss', '../../occurrence/occurrence.component.scss'],
})
export class PhytoOccurrenceComponent implements OnInit, OnDestroy {
  public occurrenceForm: UntypedFormGroup;

  public taxonForm: UntypedFormControl; //control permettant de rechercher un taxon TAXREF
  public taxonFormFocus: boolean = false; //pour mieux gérer l'affichage de l'erreur required

  public advancedSectionState: AdvancedSectionState = AdvancedSectionState.COLLAPSED;
  private _subscriptions: Subscription[] = [];
  public displayProofFromElements: boolean = false;

  public strataRows: StratumRow[] = [];  // Used as dataSource for the mat table
  displayedColumns = ['stratum', 'abundance'];

  @ViewChildren(PhytoCountingComponent)

  phytoCountingComponents: QueryList<PhytoCountingComponent>;

  get taxref(): any {
    return this.phytoOccurrenceService.taxref.getValue();
  }
  get additionalFieldsForm(): any[] {
    return this.phytoOccurrenceService.additionalFieldsForm;
  }

  private destroy$ = new Subject<void>();

  constructor(
    public occtaxFormService: OcctaxFormService,
    private phytoCountingsService: PhytoCountingsService,
    public phytoOccurrenceService: PhytoOccurrenceService,
    private formService: FormService,
    private occtaxTaxaListService: OcctaxTaxaListService,
    private readonly dataFormService: DataFormService,
    public dialog: MatDialog,
    public configService: ConfigService,
    public occtaxConfigService: OcctaxConfigService
  ) { }

  ngOnInit() {
    this.occurrenceForm = this.phytoOccurrenceService.form;
    
    //gestion de l'affichage des preuves d'existence selon si Preuve = 'Oui' ou non.   
    this.occurrenceForm
      .get('id_nomenclature_exist_proof')
      .valueChanges.pipe(
        map((id_nomenclature: number): boolean => {
          let cd_nomenclature = this.phytoOccurrenceService.getCdNomenclatureById(
            id_nomenclature,
            this.phytoOccurrenceService.existProof_DATA
          );
          return cd_nomenclature == '1';
        })
      )
      .pipe(takeUntil(this.destroy$))
      .subscribe((display: boolean) => (this.displayProofFromElements = display))

    this.advancedSectionState = this.occtaxConfigService.moduleConf.EXPANDED_TAXON_ADVANCED_DETAILS
      ? AdvancedSectionState.EXPANDED
      : AdvancedSectionState.COLLAPSED;

    this.initTaxrefSearch();

    combineLatest([
      this.occtaxFormService.occtaxData.pipe(
        filter((data: any) => !!data?.releve?.properties),
      ),
      this.dataFormService.getNomenclature('STRATE_VEGETATION'),
    ])
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: ([data, nomenclature]: [any, { values: Nomenclature[] }]) => {
          this.setStrataRows(
            data.releve.properties.t_vegetation_stratum as VegetationStratum[] || [], // should check if it is empty before typing it 
            nomenclature.values || [],
          );
        },
        error: (error: any) => {
          console.error('Error loading vegetation strata for countings:', error);
        },
      });

  }

  ngAfterViewInit() {
    //a chaque reinitialisation du formulaire on place le focus sur la zone de saisie du taxon
    const taxonInput = document.getElementById('taxonInput');
    taxonInput.focus();

    this.phytoOccurrenceService.occurrence.subscribe(() => taxonInput.focus());

    //Pour gérer l'affichage de l'erreur required quand le focus est présent dans l'input
    taxonInput.addEventListener('focus', (event) => (this.taxonFormFocus = true));
    taxonInput.addEventListener('blur', (event) => (this.taxonFormFocus = false));
  }

  ngOnDestroy() {
    this.resetOccurrenceForm();
    this.destroy$.next();
    this.destroy$.complete();
  }

  setExistProofData(data) {
    this.phytoOccurrenceService.existProof_DATA = data;
  }

  initTaxrefSearch() {
    this.taxonForm = new UntypedFormControl(null, [
      Validators.required,
      this.formService.taxonValidator,
    ]);

    //attribut le cd_nom au formulaire si un taxon est selectionné
    //gère le taxon en cours pour filtrer les valeurs des differents select
    this._subscriptions.push(
      this.taxonForm.valueChanges
        .pipe(
          tap(() => this.phytoOccurrenceService.taxref.next(null)),
          filter((taxon) => taxon !== null && taxon.cd_nom !== undefined),
          tap((taxon) => this.phytoOccurrenceService.taxref.next(taxon)),
          map((taxon) => {
            // mark the occform as dirty
            this.phytoOccurrenceService.form.markAsDirty();
            let nom_cite = null;
            let cd_nom = null;
            if (typeof taxon === 'string') {
              nom_cite = taxon.length ? taxon : null;
            } else {
              nom_cite = taxon.search_name.replace(/<[^>]*>/g, '');
              cd_nom = taxon.cd_nom ? taxon.cd_nom : null;
            }
            return {
              nom_cite: nom_cite,
              cd_nom: cd_nom,
            };
          })
        )
        .subscribe((values: any) => {
          const currentOccForm = this.phytoOccurrenceService.occurrence.getValue();
          // Si édition d'une occurrence, on ne vérifie pas si déjà dans la liste
          if (currentOccForm && currentOccForm.id_releve_occtax) {
            this.occurrenceForm.get('nom_cite').setValue(values.nom_cite);
            this.occurrenceForm.get('cd_nom').setValue(values.cd_nom);
          } else {
            // check si taxon pas déjà dans la liste
            const currentTaxaList = this.occtaxTaxaListService.occurrences$.getValue();
            const alreadyExistingTax = currentTaxaList.find(
              (tax) => tax.cd_nom === this.taxonForm.value.cd_nom
            );
            if (alreadyExistingTax) {
              const message =
                "Le taxon saisi est déjà dans la liste des taxons enregistrés. <br/>\
                 <small> Privilegiez d'ajouter plusieurs dénombrements sur le même taxon. </small> <br/> \
                 Voulez-vous continuer ? \
                 ";
              const dialogRef = this.dialog.open(ConfirmationDialog, {
                width: 'auto',
                position: { top: '5%' },
                data: { message: message, yesColor: 'basic', noColor: 'warn' },
              });
              dialogRef.afterClosed().subscribe((result) => {
                if (!result) {
                  this.taxonForm.reset();
                } else {
                  this.occurrenceForm.get('nom_cite').setValue(values.nom_cite);
                  this.occurrenceForm.get('cd_nom').setValue(values.cd_nom);
                }
              });
            } else {
              this.occurrenceForm.get('nom_cite').setValue(values.nom_cite);
              this.occurrenceForm.get('cd_nom').setValue(values.cd_nom);
            }
          }
        })
    );

    // set taxon form value from occurrence data observable
    this._subscriptions.push(
      this.phytoOccurrenceService.occurrence
        .pipe(
          tap(() => this.taxonForm.setValue(null)),
          filter((occurrence) => occurrence),
          map((occurrence: any): Taxon => {
            let taxon: Taxon = occurrence.taxref ? <Taxon>occurrence.taxref : <Taxon>{};
            taxon.search_name = occurrence.nom_cite.replace(/<[^>]*>/g, '');
            return taxon;
          })
        )
        .subscribe((taxref: Taxon) => this.taxonForm.setValue(taxref))
    );
  }

  get countings() {
    return this.phytoCountingsService.countings || [];
  }

  private setStrataRows(strata: VegetationStratum[], nomenclatures: Nomenclature[]): void {
    this.strataRows = strata
      .filter(
        (stratum): stratum is VegetationStratum & {
          id_nomenclature_vegetation_stratum: number;
        } =>
          stratum.id_nomenclature_vegetation_stratum != null &&
          (stratum.percentage_cover_vegetation_stratum != null ||
            stratum.average_height != null ||
            stratum.min_height != null ||
            stratum.max_height != null),
      )
      .map((stratum) => {
        const idNomenclatureVegetationStratum = stratum.id_nomenclature_vegetation_stratum;
        const nomenclature = nomenclatures.find(
          (item: any) => item.id_nomenclature === idNomenclatureVegetationStratum,
        );
        const counting = this.countings.find(
          (item) => item.id_nomenclature_vegetation_stratum === idNomenclatureVegetationStratum,
        );

        return {
          id: idNomenclatureVegetationStratum,
          label: nomenclature?.label_default || '',
          counting: counting || {},
        };
      })
      .filter((row) => row.label !== '');
  }

  submitOccurrenceForm() {
    document.getElementById('taxonInput')?.focus();
    if (this.phytoOccurrenceService.form.valid) {
      this.phytoOccurrenceService.submitOccurrence();
      this.phytoCountingComponents.forEach((component) =>
        component.validateMediasDeletions(),
      );
    }
  }

  resetOccurrenceForm() {
    this.phytoOccurrenceService.reset();
  }

  /** A la selection d'un taxon, focus sur le bouton ajouter */
  selectAddOcc(event) {
    setTimeout(() => {
      document.getElementById('add-occ').focus();
    }, 50);
  }
}
