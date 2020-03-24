import { Component, Input, OnInit } from "@angular/core";
import { combineLatest  } from 'rxjs';
import { filter, map, tap } from 'rxjs/operators';
import { NgbModal } from "@ng-bootstrap/ng-bootstrap";
import { MatDialog } from '@angular/material';
import { TranslateService } from '@ngx-translate/core';
import { OcctaxFormService } from "../occtax-form.service";
import { OcctaxFormOccurrenceService } from "../occurrence/occurrence.service";
import { OcctaxTaxaListService } from "./taxa-list.service";

import { ConfirmationDialog } from "@geonature_common/others/modal-confirmation/confirmation.dialog";


@Component({
  selector: "pnx-occtax-form-taxa-list",
  templateUrl: "./taxa-list.component.html",
  styleUrls: ["./taxa-list.component.scss"]
})
export class OcctaxFormTaxaListComponent implements OnInit {

  public occurrences: Array<any>;

  constructor(
    public ngbModal: NgbModal,
    public dialog: MatDialog,
    private translate: TranslateService,
    private occtaxFormService: OcctaxFormService,
    private occtaxFormOccurrenceService: OcctaxFormOccurrenceService,
    public occtaxTaxaListService: OcctaxTaxaListService
  ) { }

  ngOnInit() {
    combineLatest(this.occtaxFormService.occtaxData, this.occtaxFormOccurrenceService.occurrence)
      .pipe(
        tap(()=>this.occurrences = []),
        filter(([occtaxData, occurrence]: any)=>occtaxData && occtaxData.releve.properties.t_occurrences_occtax),
        map(([occtaxData, occurrence]: any)=>{
          return occtaxData.releve.properties.t_occurrences_occtax
                    .filter(occ=>{
                      //enlève l'occurrence en cours de modification de la liste affichée
                      return occurrence !== null ? occ.id_occurrence_occtax !== occurrence.id_occurrence_occtax : true;
                    }) 
                    .sort((o1, o2) => {
                      const name1 = (o1.taxref ? o1.taxref.nom_complet : this.removeHtml(o1.nom_cite)).toLowerCase();
                      const name2 = (o2.taxref ? o2.taxref.nom_complet : this.removeHtml(o2.nom_cite)).toLowerCase();
                      if (name1 > name2) { return 1; }
                      if (name1 < name2) { return -1; }
                      return 0;
                    })
        })
      )
      .subscribe(occurrences=>this.occurrences = occurrences);
  }

  editOccurrence(occurrence) {
    this.occtaxFormOccurrenceService.occurrence.next(occurrence);
  }

  deleteOccurrence(occurrence) {
    const message = `${this.translate.instant('Delete')} ${this.taxonTitle(occurrence)} ?`;
    const dialogRef = this.dialog.open(ConfirmationDialog, {
      width: '350px',
      position: {top: '5%'},
      data: {message: message}
    });

    dialogRef.afterClosed().subscribe(result => {
      if(result) {
        this.occtaxFormOccurrenceService.deleteOccurrence(occurrence);
      }
    });
  }

  get occIDInEdit() {
    let occurrence = this.occtaxFormOccurrenceService.occurrence.getValue();
    return occurrence ? occurrence.id_occurrence_occtax : null;
  }

  removeHtml(str: string): string  {
    return str.replace(/<[^>]*>/g, '')
  }

  taxonTitle(occurrence) {
    if (occurrence.taxref) {
      occurrence.taxref.nom_complet
      return occurrence.taxref.cd_nom === occurrence.taxref.cd_ref ? 
              '<b>'+occurrence.taxref.nom_valide+'</b>' :
              occurrence.taxref.nom_complet;
    }
    return this.removeHtml(occurrence.nom_cite);
  }
}
