import { Component, Input, OnInit, Renderer2, ElementRef, ViewChild } from "@angular/core";
import { combineLatest } from "rxjs";
import { filter, map, tap } from "rxjs/operators";
import { NgbModal } from "@ng-bootstrap/ng-bootstrap";
import { MatDialog, MatTabChangeEvent  } from "@angular/material";
import { TranslateService } from "@ngx-translate/core";
import { OcctaxFormService } from "../occtax-form.service";
import { OcctaxFormOccurrenceService } from "../occurrence/occurrence.service";
import { OcctaxTaxaListService } from "./taxa-list.service";
import { MediaService } from '@geonature_common/service/media.service'
import { ModuleConfig } from "../../module.config"

import { ConfirmationDialog } from "@geonature_common/others/modal-confirmation/confirmation.dialog";

@Component({
  selector: "pnx-occtax-form-taxa-list",
  templateUrl: "./taxa-list.component.html",
  styleUrls: ["./taxa-list.component.scss"],
})
export class OcctaxFormTaxaListComponent implements OnInit {
  @ViewChild('tabOccurence') tabOccurence: ElementRef;

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
          this.occtaxTaxaListService.occurrences$.value.map((occurence) => {
            let dynamiqueFormDataset = this.occtaxFormService.getAddDynamiqueFields(this.occtaxFormOccurrenceService.idDataset);
            let hasDynamicFormOccurence = false;
            if (dynamiqueFormDataset){
              if (dynamiqueFormDataset['OCCURRENCE']){
                hasDynamicFormOccurence = true;
              }
            }
            if(hasDynamicFormOccurence){
              let containerOccurence = document.getElementById('tabOccurence' + occurence.id_occurrence_occtax);
              dynamiqueFormDataset['OCCURRENCE'].map((widget) => {
                this.createVisualizeElement(containerOccurence, widget, occurence);
              });
            }
          })
        }, 200);
      });
  }

  editOccurrence(occurrence) {
    setTimeout(() => { })
    this.occtaxFormOccurrenceService.occurrence.next(occurrence);
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
    let infoTab = tabChangeEvent.tab.textLabel.split('#');
    if(infoTab[0] == 'counting'){
      this.occtaxTaxaListService.occurrences$.value.map((occurence) => {
        if(occurence.id_occurrence_occtax == infoTab[1]){
          //On ne créer pas les composants 2 fois, merci
          if (this.alreadyActivatedCountingTab[occurence.id_occurrence_occtax]){return}
          this.alreadyActivatedCountingTab[occurence.id_occurrence_occtax] = true;
          //Si le counting possède un formDynamique, on se lance dans la créa
          let hasDynamicFormCounting = false;
          let dynamiqueFormDataset = this.occtaxFormService.getAddDynamiqueFields(this.occtaxFormOccurrenceService.idDataset);
          if (dynamiqueFormDataset){
            if (dynamiqueFormDataset['COUNTING']){
              hasDynamicFormCounting = true;
            }
          }
          if(hasDynamicFormCounting){
            //Pour chaque counting, on créer les composants associés
            occurence.cor_counting_occtax.map((counting) => {
              //On récupère la div mère, en l'occurrence, la div list-values du mat-tab
              let containerCounting = document.getElementById('tabCounting' + counting.id_counting_occtax);
              //Pour chaque widget, on ajoute son libelle et sa valeur
              dynamiqueFormDataset['COUNTING'].map((widget) => {
                this.createVisualizeElement(containerCounting, widget, counting);
              });
            });
          }
        }
      })
    }
  }


  createVisualizeElement(container : HTMLElement, widget, values) {
    if(!container){
      return;
    }
    if(values.additional_fields[widget.attribut_name]){
      //FINALEMENT on passera jamais ici car les médias sont maintenant gérés dans le champs média du dénombrement (counting)
      //Bien sur petite exception pour le type médias
      if (widget.type_widget == 'medias'){
        //pour tous les médias présent par type de widget medias
        values.additional_fields[widget.attribut_name].forEach((media, i) => {
          //On duplique la première div pour récupérer le style qui va bien
          let newDiv = container.firstChild.cloneNode(true) as HTMLElement;
          //On réécrit son contenu
          newDiv.innerHTML = widget.attribut_label + ' (' + (i+1) + '/' + values.additional_fields[widget.attribut_name].length + ') ';
          
          //On lui ajoute la balise a
          let ahref = document.createElement("a");
          ahref.href = this.ms.href(media);
          ahref.target = 'blank';
          ahref.innerHTML = media.title_fr;
          newDiv.appendChild(ahref);

          //On lui ajoute la balise i
          let info = document.createElement("i");
          info.innerHTML = " (" + this.ms.typeMedia(media) + (media.author? ", " + media.author : "") + ") ";
          newDiv.appendChild(info);

          //On lui ajoute la balise span
          if(media.description_fr){
            let span = document.createElement("span");
            span.innerHTML = media.description_fr;
            newDiv.appendChild(span);
          }

          //On lui ajoute la miniature
          let visuMedia = document.createElement("div");
          //Il faut récupérer l'attribut ng pour la div afin qu'il utilise bien le css
          visuMedia.className = "flex-container";
          if(newDiv.attributes[0]){
            visuMedia.setAttribute(newDiv.attributes[0].name, '');
          }
          switch(this.ms.typeMedia(media)){
            case 'PDF':
              visuMedia.innerHTML = "<embed src='" + media.safeUrl + "' width='100%' height='200' type='application/pdf' />";
              //let visualizer = 
              break;
            case 'Vidéo Youtube':
            case 'Vidéo Dailymotion':
            case 'Vidéo Vimeo':
              visuMedia.innerHTML = "<iframe width='100%' height='200' src='" + media.safeEmbedUrl + "' allowfullscreen ></iframe>";
              break;
            case 'Vidéo (fichier)':
              visuMedia.innerHTML = "<video class='media-center' controls src='" + this.ms.href(media) + "'></video>";
              break;
            case 'Audio':
              visuMedia.innerHTML = "<audio class='media-center' controls src='" + this.ms.href(media) + "'></audio>";
              break;
            case 'Photo':
              visuMedia.innerHTML = "<img class='media-center' src='" + this.ms.href(media, 200) + "' alt='" + media.title_fr + "'/>";
              break;
          }
          
          newDiv.appendChild(visuMedia);
          container.appendChild(newDiv);
        })
      }else{
        //si ce n'est pas un média, on affiche son libellé (configuration) et sa valeur (bdd)
        let newDiv = container.firstChild.cloneNode(true)  as HTMLElement;
        newDiv.getElementsByClassName('label')[0].innerHTML = widget.attribut_label + ' :';
        newDiv.getElementsByClassName('value')[0].innerHTML = values.additional_fields[widget.attribut_name];
        container.appendChild(newDiv);
      }
    }
  }
}
