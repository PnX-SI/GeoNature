import { Component, OnInit, ElementRef, ViewChild } from '@angular/core';
import { combineLatest } from 'rxjs';
import { filter, map } from 'rxjs/operators';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { MatDialog } from '@angular/material/dialog';
import { TranslateService } from '@ngx-translate/core';
import { OcctaxFormService } from '../occtax-form.service';
import { OcctaxFormOccurrenceService } from '../occurrence/occurrence.service';
import { OcctaxTaxaListService } from './taxa-list.service';
import { MediaService } from '@geonature_common/service/media.service';

import { ConfirmationDialog } from '@geonature_common/others/modal-confirmation/confirmation.dialog';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'pnx-occtax-form-taxa-list',
  templateUrl: './taxa-list.component.html',
  styleUrls: ['./taxa-list.component.scss'],
})
export class OcctaxFormTaxaListComponent implements OnInit {
  @ViewChild('tabOccurence') tabOccurence: ElementRef;

  constructor(
    public ngbModal: NgbModal,
    public dialog: MatDialog,
    private translate: TranslateService,
    private occtaxFormService: OcctaxFormService,
    public occtaxFormOccurrenceService: OcctaxFormOccurrenceService,
    public occtaxTaxaListService: OcctaxTaxaListService,
    public ms: MediaService,
    public config: ConfigService
  ) {}

  ngOnInit() {
    combineLatest(this.occtaxFormService.occtaxData, this.occtaxFormOccurrenceService.occurrence)
      .pipe(
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
              const name1 = (
                o1.taxref ? o1.taxref.nom_complet : this.removeHtml(o1.nom_cite)
              ).toLowerCase();
              const name2 = (
                o2.taxref ? o2.taxref.nom_complet : this.removeHtml(o2.nom_cite)
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
      });
  }

  editOccurrence(occurrence) {
    this.occtaxFormOccurrenceService.occurrence.next(occurrence);
  }

  deleteOccurrence(occurrence) {
    const message = `${this.translate.instant('Delete')} ${this.taxonTitle(occurrence)} ?`;
    const dialogRef = this.dialog.open(ConfirmationDialog, {
      width: '350px',
      position: { top: '5%' },
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
    return str.replace(/<[^>]*>/g, '');
  }

  /**
   *  Return un titre formaté sans balise HTML
   **/
  taxonTitle(occurrence) {
    return this.removeHtml(occurrence.nom_cite);
  }

  /**
   *  Permet de replacer un taxon ayant subit une erreur dans le formulaire pour modif et réenregistrement
   **/
  inProgressErrorToForm(occ_in_progress) {
    if (occ_in_progress.state !== 'error') {
      return;
    }

    this.editOccurrence(occ_in_progress.data);
    this.occtaxTaxaListService.removeOccurrenceInProgress(occ_in_progress.id);
  }
}
