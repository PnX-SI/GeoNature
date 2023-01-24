import { Component, OnInit, OnDestroy } from '@angular/core';
import { animate, state, style, transition, trigger } from '@angular/animations';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { Subscription } from 'rxjs';
import { map, filter, tap } from 'rxjs/operators';
import { OcctaxFormService } from '../occtax-form.service';
import { ModuleConfig } from '../../module.config';
import { OcctaxFormOccurrenceService } from './occurrence.service';
import { OcctaxFormCountingsService } from '../counting/countings.service';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { FormService } from '@geonature_common/form/form.service';
import { OcctaxTaxaListService } from '../taxa-list/taxa-list.service';
import { ConfirmationDialog } from '@geonature_common/others/modal-confirmation/confirmation.dialog';
import { MatDialog } from '@angular/material/dialog';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'pnx-occtax-form-occurrence',
  templateUrl: './occurrence.component.html',
  styleUrls: ['./occurrence.component.scss'],
  animations: [
    trigger('detailExpand', [
      state(
        'collapsed',
        style({
          height: '0px',
          minHeight: '0',
          margin: '-1px',
          overflow: 'hidden',
          padding: '0',
          display: 'none',
        })
      ),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('250ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class OcctaxFormOccurrenceComponent implements OnInit, OnDestroy {
  public occtaxConfig = ModuleConfig;
  public occurrenceForm: FormGroup;
  public taxonForm: FormControl; //control permettant de rechercher un taxon TAXREF
  public taxonFormFocus: boolean = false; //pour mieux gérer l'affichage de l'erreur required
  public advanced: string = 'collapsed';
  private _subscriptions: Subscription[] = [];
  public displayProofFromElements: boolean = false;

  get taxref(): any {
    return this.occtaxFormOccurrenceService.taxref.getValue();
  }
  get additionalFieldsForm(): any[] {
    return this.occtaxFormOccurrenceService.additionalFieldsForm;
  }

  constructor(
    public fs: OcctaxFormService,
    private occtaxFormCountingsService: OcctaxFormCountingsService,
    public occtaxFormOccurrenceService: OcctaxFormOccurrenceService,
    private _coreFormService: FormService,
    private _occtaxTaxaListService: OcctaxTaxaListService,
    public dialog: MatDialog,
    public cs: ConfigService
  ) {}

  ngOnInit() {
    this.occurrenceForm = this.occtaxFormOccurrenceService.form;
    //gestion de l'affichage des preuves d'existence selon si Preuve = 'Oui' ou non.
    this._subscriptions.push(
      this.occurrenceForm
        .get('id_nomenclature_exist_proof')
        .valueChanges.pipe(
          map((id_nomenclature: number): boolean => {
            let cd_nomenclature = this.occtaxFormOccurrenceService.getCdNomenclatureById(
              id_nomenclature,
              this.occtaxFormOccurrenceService.existProof_DATA
            );
            return cd_nomenclature == '1';
          })
        )
        .subscribe((display: boolean) => (this.displayProofFromElements = display))
    );

    this.initTaxrefSearch();
  }

  ngAfterViewInit() {
    //a chaque reinitialisation du formulaire on place le focus sur la zone de saisie du taxon
    const taxonInput = document.getElementById('taxonInput');
    taxonInput.focus();

    this.occtaxFormOccurrenceService.occurrence.subscribe(() => taxonInput.focus());

    //Pour gérer l'affichage de l'erreur required quand le focus est présent dans l'input
    taxonInput.addEventListener('focus', (event) => (this.taxonFormFocus = true));
    taxonInput.addEventListener('blur', (event) => (this.taxonFormFocus = false));
  }

  setExistProofData(data) {
    this.occtaxFormOccurrenceService.existProof_DATA = data;
  }

  initTaxrefSearch() {
    this.taxonForm = new FormControl(null, [
      Validators.required,
      this._coreFormService.taxonValidator,
    ]);

    //attribut le cd_nom au formulaire si un taxon est selectionné
    //gère le taxon en cours pour filtrer les valeurs des differents select
    this._subscriptions.push(
      this.taxonForm.valueChanges
        .pipe(
          tap(() => this.occtaxFormOccurrenceService.taxref.next(null)),
          filter((taxon) => taxon !== null && taxon.cd_nom !== undefined),
          tap((taxon) => this.occtaxFormOccurrenceService.taxref.next(taxon)),
          map((taxon) => {
            // mark the occform as dirty
            this.occtaxFormOccurrenceService.form.markAsDirty();
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
          const currentOccForm = this.occtaxFormOccurrenceService.occurrence.getValue();
          // Si édition d'une occurrence, on ne vérifie pas si déjà dans la liste
          if (currentOccForm && currentOccForm.id_releve_occtax) {
            this.occurrenceForm.get('nom_cite').setValue(values.nom_cite);
            this.occurrenceForm.get('cd_nom').setValue(values.cd_nom);
          } else {
            // check si taxon pas déjà dans la liste
            const currentTaxaList = this._occtaxTaxaListService.occurrences$.getValue();
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
      this.occtaxFormOccurrenceService.occurrence
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
    return this.occtaxFormCountingsService.countings || [];
  }

  submitOccurrenceForm() {
    document.getElementById('taxonInput').focus();
    if (this.occtaxFormOccurrenceService.form.valid) {
      this.occtaxFormOccurrenceService.submitOccurrence();
    }
  }

  resetOccurrenceForm() {
    this.occtaxFormOccurrenceService.reset();
  }

  ngOnDestroy() {
    this.resetOccurrenceForm();
    this._subscriptions.forEach((s) => {
      s.unsubscribe();
    });
  }

  addCounting() {
    this.occtaxFormCountingsService.countings.push({});
  }

  removeCounting(index) {
    this.occtaxFormCountingsService.countings.splice(index, 1);
  }

  /** A la selection d'un taxon, focus sur le bouton ajouter */
  selectAddOcc(event) {
    setTimeout(() => {
      document.getElementById('add-occ').focus();
    }, 50);
  }

  collapse() {
    this.advanced = this.advanced === 'collapsed' ? 'expanded' : 'collapsed';
  }
}
