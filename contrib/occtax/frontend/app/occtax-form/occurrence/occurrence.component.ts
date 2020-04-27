import { Component, OnInit, AfterViewInit } from "@angular/core";
import { animate, state, style, transition, trigger } from '@angular/animations';
import { FormControl, FormGroup, FormArray, Validators } from "@angular/forms";
import { map, filter, tap } from 'rxjs/operators';
import { OcctaxFormService } from "../occtax-form.service";
import { CommonService } from "@geonature_common/service/common.service";
import { NomenclatureComponent } from "@geonature_common/form/nomenclature/nomenclature.component";
import { ModuleConfig } from "../../module.config";
import { OcctaxFormOccurrenceService } from "./occurrence.service";
import { Taxon } from "@geonature_common/form/taxonomy/taxonomy.component";

@Component({
  selector: "pnx-occtax-form-occurrence",
  templateUrl: "./occurrence.component.html",
  styleUrls: ["./occurrence.component.scss"],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({height: '0px', minHeight: '0', margin: '-1px', overflow: 'hidden', padding: '0', display:'none'})),
      state('expanded', style({height: '*'})),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class OcctaxFormOccurrenceComponent implements OnInit {
  
  public occtaxConfig = ModuleConfig;
  public occurrenceForm: FormGroup;
  public taxonForm: FormControl; //control permettant de rechercher un taxon TAXREF
  public taxonFormFocus: boolean = false; //pour mieux gérer l'affichage de l'erreur required
  private advanced: string = 'collapsed';
  public countingStep: number = 0;
  
  public displayProofFromElements: boolean = false;

  constructor(
    public fs: OcctaxFormService,
    private _commonService: CommonService,
    private occtaxFormOccurrenceService: OcctaxFormOccurrenceService,
    private occtaxFormService: OcctaxFormService
  ) {}

  ngOnInit() {
    this.occurrenceForm = this.occtaxFormOccurrenceService.form;

    //gestion de l'affichage des preuves d'existence selon si Preuve = 'Oui' ou non.
    this.occurrenceForm.get('id_nomenclature_exist_proof')
                              .valueChanges
                              .pipe(
                                map((id_nomenclature: number): boolean=>{
                                  let cd_nomenclature = this.occtaxFormOccurrenceService.getCdNomenclatureById(
                                                  id_nomenclature,
                                                  this.occtaxFormOccurrenceService.existProof_DATA
                                                );
                                  return cd_nomenclature == '1';
                                })
                              )
                              .subscribe((display: boolean)=>this.displayProofFromElements = display);

    this.initTaxrefSearch();
  }

  ngAfterViewInit() {
    //a chaque reinitialisation du formulaire on place le focus sur la zone de saisie du taxon
    this.occtaxFormOccurrenceService.occurrence
          .subscribe(()=>document.getElementById("taxonInput").focus());

    //Pour gérer l'affichage de l'erreur required quand le focus est présent dans l'input
    const taxonInput = document.getElementById("taxonInput");
    taxonInput.addEventListener('focus', (event) => this.taxonFormFocus = true);
    taxonInput.addEventListener('blur', (event) => this.taxonFormFocus = false);
  }

  setExistProofData(data) {
    this.occtaxFormOccurrenceService.existProof_DATA = data;
  }

  initTaxrefSearch() {
    this.taxonForm = new FormControl(null, Validators.required);

    //attribut le cd_nom au formulaire si un taxon est selectionné
    //gère le taxon en cours pour filtrer les valeurs des differents select
    this.taxonForm
          .valueChanges
          .pipe(
            tap(()=>this.occtaxFormOccurrenceService.taxref.next(null)),
            filter(taxon=>taxon !== null && taxon.cd_nom !== undefined),
            tap(taxon=>this.occtaxFormOccurrenceService.taxref.next(taxon)),
            map(taxon=>{
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
                        cd_nom: cd_nom
                      };
            })
          )
          .subscribe((values: any)=>{
            this.occurrenceForm.get('nom_cite').setValue(values.nom_cite);
            this.occurrenceForm.get('cd_nom').setValue(values.cd_nom);
          });

    this.occtaxFormOccurrenceService.occurrence
              .pipe(
                tap(()=>this.taxonForm.setValue(null)),
                filter(occurrence=>occurrence),
                map((occurrence: any): Taxon=>{
                  let taxon: Taxon = occurrence.taxref ? <Taxon> occurrence.taxref : <Taxon> {};
                  taxon.search_name = occurrence.nom_cite.replace(/<[^>]*>/g, '');
                  return taxon
                })
              )
              .subscribe((taxref: Taxon)=>this.taxonForm.setValue(taxref));
  }

  get countingControls() {
    return (this.occurrenceForm.get('cor_counting_occtax') as FormArray).controls;
  }

  submitOccurrenceForm() {
    if (this.occurrenceForm.valid) {
      this.occtaxFormOccurrenceService.submitOccurrence();
    }
  }

  resetOccurrenceForm() {
    this.occtaxFormOccurrenceService.reset();
  }

  addCounting() {
    this.occtaxFormOccurrenceService.addCountingForm(true); //patchwithdefaultvalue
  }

  removeCounting(index) {
    (this.occurrenceForm.get('cor_counting_occtax') as FormArray).removeAt(index);
  }

  collapse() {
    this.advanced = (this.advanced === 'collapsed' ? 'expanded' : 'collapsed');
  }

  console() {
    console.log("coucou")
  }
}