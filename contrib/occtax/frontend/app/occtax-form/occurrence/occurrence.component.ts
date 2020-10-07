import { Component, OnInit, OnDestroy, ViewContainerRef, ViewChild, ComponentRef, ComponentFactory, ComponentFactoryResolver } from "@angular/core";
import {
  animate,
  state,
  style,
  transition,
  trigger
} from "@angular/animations";
import { FormControl, FormGroup, FormArray, Validators, FormBuilder } from "@angular/forms";
import { map, filter, tap, delay, switchMap } from "rxjs/operators";
import { OcctaxFormService } from "../occtax-form.service";
import { ModuleConfig } from "../../module.config";
import { AppConfig } from "@geonature_config/app.config";
import { OcctaxFormOccurrenceService } from "./occurrence.service";
import { Taxon } from "@geonature_common/form/taxonomy/taxonomy.component";
import { FormService } from "@geonature_common/form/form.service";
import { OcctaxTaxaListService } from "../taxa-list/taxa-list.service";
import { ConfirmationDialog } from "@geonature_common/others/modal-confirmation/confirmation.dialog";
import { MatDialog } from "@angular/material";
import { Observable } from "rxjs";
import { dynamicFormReleveComponent } from "../dynamique-form-releve/dynamic-form-releve.component";


@Component({
  selector: "pnx-occtax-form-occurrence",
  templateUrl: "./occurrence.component.html",
  styleUrls: ["./occurrence.component.scss"],
  animations: [
    trigger("detailExpand", [
      state(
        "collapsed",
        style({
          height: "0px",
          minHeight: "0",
          margin: "-1px",
          overflow: "hidden",
          padding: "0",
          display: "none",
        })
      ),
      state("expanded", style({ height: "*" })),
      transition(
        "expanded <=> collapsed",
        animate("250ms cubic-bezier(0.4, 0.0, 0.2, 1)")
      ),
    ]),
  ],
})
export class OcctaxFormOccurrenceComponent implements OnInit, OnDestroy {
  @ViewChild("dynamiqueContainerOccurence", { read: ViewContainerRef }) public containerOccurence: ViewContainerRef;
  componentOccurenceRef: ComponentRef<any>;
  public occtaxConfig = ModuleConfig;
  public appConfig = AppConfig;
  public occurrenceForm: FormGroup;
  public taxonForm: FormControl; //control permettant de rechercher un taxon TAXREF
  public taxonFormFocus: boolean = false; //pour mieux gérer l'affichage de l'erreur required
  private advanced: string = "collapsed";
  public countingStep: number = 0;


  public displayProofFromElements: boolean = false;

  public dynamicFormGroup: FormGroup;
  public data : any;
  public dynamicContainerOccurence: ViewContainerRef;
  componentRefOccurence: ComponentRef<any>;

  public idTaxonList: number;

  constructor(
    public fs: OcctaxFormService,
    private occtaxFormOccurrenceService: OcctaxFormOccurrenceService,
    private _coreFormService: FormService,
    private _occtaxTaxaListService: OcctaxTaxaListService,
    public dialog: MatDialog,
    private _resolver: ComponentFactoryResolver,
    private fb: FormBuilder,
  ) { }

  ngOnInit() {
    this.occurrenceForm = this.occtaxFormOccurrenceService.form;

    //gestion de l'affichage des preuves d'existence selon si Preuve = 'Oui' ou non.
    this.occurrenceForm
      .get("id_nomenclature_exist_proof")
      .valueChanges.pipe(
        map((id_nomenclature: number): boolean => {
          let cd_nomenclature = this.occtaxFormOccurrenceService.getCdNomenclatureById(
            id_nomenclature,
            this.occtaxFormOccurrenceService.existProof_DATA
          );
          return cd_nomenclature == "1";
        })
      )
      .subscribe(
        (display: boolean) => (this.displayProofFromElements = display)
      );

      this.idTaxonList = this.occtaxConfig.id_taxon_list;
      //this.idTaxonList = 5;
    this.initTaxrefSearch();
    /*var occtaxData = this.fs.occtaxData.getValue();
    this.fs.currentIdDataset;*/
    this.occtaxFormOccurrenceService.dynamicContainerOccurence = this.containerOccurence;
  }
  

  /** Get occtax data and patch value to the form */
  private get releveValues(): Observable<any> {
    return this.fs.occtaxData.pipe(
      filter((data) => data && data.releve.properties),
      map((data) => {
        const releve = data.releve.properties;

        /* OCCTAX - CHAMPS ADDITIONNELS DEB */
        if(this.dynamicContainerOccurence != undefined){
          this.dynamicContainerOccurence.clear(); 
          const factory: ComponentFactory<any> = this._resolver.resolveComponentFactory(dynamicFormReleveComponent);
          this.componentRefOccurence = this.dynamicContainerOccurence.createComponent(factory);
          
          /*MET Champs additionnel*/
          this.dynamicFormGroup = this.fb.group({});
      
          this.componentRefOccurence.instance.formConfigReleveDataSet = ModuleConfig.add_fields[data.releve.properties.dataset.id_dataset]['taxon'];
          this.componentRefOccurence.instance.formArray = this.dynamicFormGroup;

          if(ModuleConfig.add_fields[data.releve.properties.dataset.id_dataset]['id_taxon_list']){
            this.idTaxonList = ModuleConfig.add_fields[data.releve.properties.dataset.id_dataset]['id_taxon_list'];
          }
        }
        /* OCCTAX - CHAMPS ADDITIONNELS FIN */
        return releve;
      })
    );
  }

  ngAfterViewInit() {
    //a chaque reinitialisation du formulaire on place le focus sur la zone de saisie du taxon
    this.occtaxFormOccurrenceService.occurrence.subscribe(() =>
      document.getElementById("taxonInput").focus()
    );

    //Pour gérer l'affichage de l'erreur required quand le focus est présent dans l'input
    const taxonInput = document.getElementById("taxonInput");
    taxonInput.addEventListener(
      "focus",
      (event) => (this.taxonFormFocus = true)
    );
    taxonInput.addEventListener(
      "blur",
      (event) => (this.taxonFormFocus = false)
    );

    /* MET Champs additionnel, récupérer le dataset */
    /*this.fs.editionMode
      .pipe(
        switchMap((editionMode: boolean) => {
          //Le switch permet, selon si édition ou creation, de récuperer les valeur par defaut ou celle de l'API
          return editionMode ? this.releveValues : [];
        })
      )
      .subscribe((values) => this.data = values); //filter((editionMode: boolean) => !editionMode))
*/
    //console.log(this.data);
    //const data = this.releveValues;
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
          if (typeof taxon === "string") {
            nom_cite = taxon.length ? taxon : null;
          } else {
            nom_cite = taxon.search_name.replace(/<[^>]*>/g, "");
            cd_nom = taxon.cd_nom ? taxon.cd_nom : null;
          }
          return {
            nom_cite: nom_cite,
            cd_nom: cd_nom,
          };
        })
      )
      .subscribe((values: any) => {
        // console.log(this.occtaxFormOccurrenceService.occurrence.getValue());
        console.log(this._occtaxTaxaListService.occurrences$.getValue());

        const currentOccForm = this.occtaxFormOccurrenceService.occurrence.getValue()
        // Si édition d'une occurrence, on ne vérifie pas si déjà dans la liste
        if (currentOccForm && currentOccForm.id_releve_occtax) {
          this.occurrenceForm.get("nom_cite").setValue(values.nom_cite);
          this.occurrenceForm.get("cd_nom").setValue(values.cd_nom);
        } else {
          // check si taxon pas déjà dans la liste
          const currentTaxaList = this._occtaxTaxaListService.occurrences$.getValue();
          const alreadyExistingTax = currentTaxaList.find(
            (tax) => tax.cd_nom === this.taxonForm.value.cd_nom
          );
          if (alreadyExistingTax) {
            const message =
              "Le taxon saisi est déjà dans la liste des taxons enregistrés. Voulez-vous continuer ?";
            const dialogRef = this.dialog.open(ConfirmationDialog, {
              width: "auto",
              position: { top: "5%" },
              data: { message: message, yesColor: "basic", noColor: "warn" },
            });
            dialogRef.afterClosed().subscribe((result) => {
              if (!result) {
                this.taxonForm.reset();
              } else {
                this.occurrenceForm.get("nom_cite").setValue(values.nom_cite);
                this.occurrenceForm.get("cd_nom").setValue(values.cd_nom);
              }
            });
          } else {
            this.occurrenceForm.get("nom_cite").setValue(values.nom_cite);
            this.occurrenceForm.get("cd_nom").setValue(values.cd_nom);
          }
        }

      });

    // set taxon form value from occurrence data observable
    this.occtaxFormOccurrenceService.occurrence
      .pipe(
        tap(() => this.taxonForm.setValue(null)),
        filter((occurrence) => occurrence),
        map(
          (occurrence: any): Taxon => {
            let taxon: Taxon = occurrence.taxref
              ? <Taxon>occurrence.taxref
              : <Taxon>{};
            taxon.search_name = occurrence.nom_cite.replace(/<[^>]*>/g, "");
            return taxon;
          }
        )
      )
      .subscribe((taxref: Taxon) => this.taxonForm.setValue(taxref));
  }

  get countingControls() {
    return (this.occurrenceForm.get("cor_counting_occtax") as FormArray)
      .controls;
  }

  submitOccurrenceForm() {
    if (this.occtaxFormOccurrenceService.form.valid) {
      this.occtaxFormOccurrenceService.submitOccurrence();
    }
  }



  resetOccurrenceForm() {
    this.occtaxFormOccurrenceService.reset();
  }

  ngOnDestroy() {
    this.resetOccurrenceForm();
  }

  addCounting() {
    this.occtaxFormOccurrenceService.addCountingForm(true); //patchwithdefaultvalue
  }

  removeCounting(index) {
    (this.occurrenceForm.get("cor_counting_occtax") as FormArray).removeAt(
      index
    );
  }

  /** A la selection d'un taxon, focus sur le bouton ajouter */
  selectAddOcc() {
    setTimeout(() => {
      document.getElementById("add-occ").focus();
    }, 50);
  }

  collapse() {
    this.advanced = this.advanced === "collapsed" ? "expanded" : "collapsed";
  }

}
