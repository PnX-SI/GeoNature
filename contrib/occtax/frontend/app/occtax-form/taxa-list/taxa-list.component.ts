import { Component, Input, OnInit, Renderer2, ElementRef, ViewChild } from "@angular/core";
import { combineLatest } from "rxjs";
import { filter, map, tap } from "rxjs/operators";
import { NgbModal } from "@ng-bootstrap/ng-bootstrap";
import { MatDialog, MatTabChangeEvent  } from "@angular/material";
import { TranslateService } from "@ngx-translate/core";
import { OcctaxFormService } from "../occtax-form.service";
import { OcctaxFormOccurrenceService } from "../occurrence/occurrence.service";
import { OcctaxTaxaListService } from "./taxa-list.service";
import { MediaService } from "@geonature_common/service/media.service"
import { ModuleConfig } from "../../module.config"

import { ConfirmationDialog } from "@geonature_common/others/modal-confirmation/confirmation.dialog";

@Component({
  selector: "pnx-occtax-form-taxa-list",
  templateUrl: "./taxa-list.component.html",
  styleUrls: ["./taxa-list.component.scss"],
})
export class OcctaxFormTaxaListComponent implements OnInit {
  @ViewChild("tabOccurence") tabOccurence: ElementRef;

  public ModuleConfig = ModuleConfig;
  public alreadyActivatedCountingTab : Array<any> = [];

  constructor(
    public ngbModal: NgbModal,
    public dialog: MatDialog,
    private translate: TranslateService,
    private occtaxFormService: OcctaxFormService,
    private occtaxFormOccurrenceService: OcctaxFormOccurrenceService,
    public occtaxTaxaListService: OcctaxTaxaListService,
    public ms: MediaService,
    private renderer: Renderer2
  ) {
  }

  ngOnInit() {
    combineLatest(
      this.occtaxFormService.occtaxData,
      this.occtaxFormOccurrenceService.occurrence
    )
    .pipe(
      //tap(() => (this.occurrences = [])),
      filter(
        ([occtaxData, occurrence]: any) =>
          occtaxData && occtaxData.releve.properties.t_occurrences_occtax
      ),
      map(([occtaxData, occurrence]: any) => {
        return occtaxData.releve.properties.t_occurrences_occtax
          .filter((occ) => {
            //enlève l'occurrence en cours de modification de la liste affichée
            return occurrence !== null
              ? occ.id_occurrence_occtax !== occurrence.id_occurrence_occtax
              : true;
          })
          .sort((o1, o2) => {
            const name1 = (o1.taxref
              ? o1.taxref.nom_complet
              : this.removeHtml(o1.nom_cite)
            ).toLowerCase();
            const name2 = (o2.taxref
              ? o2.taxref.nom_complet
              : this.removeHtml(o2.nom_cite)
            ).toLowerCase();
            if (name1 > name2) {
              return 1;
            }
            if (name1 < name2) {
              return -1;
            }
            return 0;
          });
      })
    )
    .subscribe((occurrences) => {
      this.occtaxTaxaListService.occurrences$.next(occurrences);
      setTimeout(() => {
        this.occtaxTaxaListService.occurrences$.value.map((occurrence) => {
          //Réinitialiser le contenu des champs additionnel
          let containerOccurrence = document.getElementById("tabOccurence" + occurrence.id_occurrence_occtax);
          if(containerOccurrence){
            while(containerOccurrence.getElementsByClassName("additional_field").length > 0) {
              containerOccurrence.getElementsByClassName("additional_field")[0].remove();
            }
          }
          //Ajoute le contenu
          let dynamiqueFormDataset = this.occtaxFormService.getAddDynamiqueFields(this.occtaxFormOccurrenceService.idDataset);
          let hasDynamicFormOccurence = false;
          if (dynamiqueFormDataset){
            if (dynamiqueFormDataset["OCCURRENCE"]){
              hasDynamicFormOccurence = true;
            }
          }
          if(hasDynamicFormOccurence){
            dynamiqueFormDataset["OCCURRENCE"].map((widget) => {
              this.ms.createVisualizeElement(containerOccurrence, widget, occurrence);
            });
          }
        })
      }, 200);
    });
  }

  editOccurrence(occurrence) {
    setTimeout(() => { })
    this.occtaxFormOccurrenceService.occurrence.next(occurrence);
    //on redessine la tab au prochain affichage
    this.alreadyActivatedCountingTab[occurrence.id_occurrence_occtax] = false;
  }

  deleteOccurrence(occurrence) {
    const message = `${this.translate.instant("Delete")} ${this.taxonTitle(
      occurrence
    )} ?`;
    const dialogRef = this.dialog.open(ConfirmationDialog, {
      width: "350px",
      position: { top: "5%" },
      data: { message: message },
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        this.occtaxFormOccurrenceService.deleteOccurrence(occurrence);
      }
    });
  }

  /**
   *  Test si un taxon déjà enregistré est actuellement dans le formulaire => modif en cours et suppression de la liste des taxons enregistrés
   **/
  get occIDInEdit() {
    let occurrence = this.occtaxFormOccurrenceService.occurrence.getValue();
    return occurrence ? occurrence.id_occurrence_occtax : null;
  }

  /**
   *  Supprime les balises HTML d'un string
   **/
  removeHtml(str: string): string {
    return str.replace(/<[^>]*>/g, "");
  }

  /**
   *  Return un titre formaté sans balise HTML
   **/
  taxonTitle(occurrence) {
    if (occurrence.taxref) {
      occurrence.taxref.nom_complet;
      return occurrence.taxref.cd_nom === occurrence.taxref.cd_ref
        ? "<b>" + occurrence.taxref.nom_valide + "</b>"
        : occurrence.taxref.nom_complet;
    }
    return this.removeHtml(occurrence.nom_cite);
  }

  /**
   *  Permet de replacer un taxon ayant subit une erreur dans le formulaire pour modif et réenregistrement
   **/
  inProgressErrorToForm(occ_in_progress) {
    if (occ_in_progress.state !== "error") {
      return;
    }

    this.editOccurrence(occ_in_progress.data);
    this.occtaxTaxaListService.removeOccurrenceInProgress(occ_in_progress.id);
  }

  //Met Affichage des champs additionnel dans l'onglet Dénombrement. L'élément est chargé seulement lorsque l'on clique dessus => Angular Material
  tabChanged(tabChangeEvent: MatTabChangeEvent): void {
    
    //Petit bidouillage avec le label pour récupérer l'id_occurrence_occtax
    let infoTab = tabChangeEvent.tab.textLabel.split("#");
    if(infoTab[0] == "counting"){
      this.occtaxTaxaListService.occurrences$.value.map((occurrence) => {
        if(occurrence.id_occurrence_occtax == infoTab[1]){
          //On ne créer pas les composants 2 fois, merci
          if (this.alreadyActivatedCountingTab[occurrence.id_occurrence_occtax]){return}
          this.alreadyActivatedCountingTab[occurrence.id_occurrence_occtax] = true;
          //Si le counting possède un formDynamique, on se lance dans la créa
          let hasDynamicFormCounting = false;
          let dynamiqueFormDataset = this.occtaxFormService.getAddDynamiqueFields(this.occtaxFormOccurrenceService.idDataset);
          if (dynamiqueFormDataset){
            if (dynamiqueFormDataset["COUNTING"]){
              hasDynamicFormCounting = true;
            }
          }
          if(hasDynamicFormCounting){
            //Pour chaque counting, on créer les composants associés
            occurrence.cor_counting_occtax.map((counting) => {
              //On récupère la div mère, en l'occurrence, la div list-values du mat-tab
              let containerCounting = document.getElementById("tabCounting" + counting.id_counting_occtax);
              //Pour chaque widget, on ajoute son libelle et sa valeur
              dynamiqueFormDataset["COUNTING"].map((widget) => {
                this.ms.createVisualizeElement(containerCounting, widget, counting);
              });
            });
          }
        }
      })
    }
  }
}
