import { Component, Input, OnInit } from "@angular/core";
import { filter, map } from 'rxjs/operators';
import { OcctaxFormService } from "../occtax-form.service";
import { OcctaxFormOccurrenceService } from "../occurrence/occurrence.service";


@Component({
  selector: "pnx-occtax-form-taxa-list",
  templateUrl: "./taxa-list.component.html",
  styleUrls: ["./taxa-list.component.scss"]
})
export class OcctaxFormTaxaListComponent implements OnInit {

  public occurrences: Array<any>;

  constructor(
    private occtaxFormService: OcctaxFormService,
    private occtaxFormOccurrenceService: OcctaxFormOccurrenceService) { }

  ngOnInit() {
    this.occtaxFormService.occtaxData
              .pipe(
                //TODO merge Observable this.occtaxFormOccurrenceService.occurrence
                filter(data=> data && data.releve.properties.t_occurrences_occtax),
                map(data=>{
                  return data.releve.properties.t_occurrences_occtax
                            .filter(occ=>occ.id_occurrence_occtax !== this.occIDInEdit)
                            .sort((o1, o2) => {
                              const name1 = (o1.taxref ? o1.taxref.nom_complet : o1.nom_cite.replace(/<[^>]*>/g, '')).toLowerCase();
                              const name2 = (o2.taxref ? o2.taxref.nom_complet : o2.nom_cite.replace(/<[^>]*>/g, '')).toLowerCase();
                              if (name1 > name2) { return 1; }
                              if (name1 < name2) { return -1; }
                              return 0;
                            })
                })
              )
              .subscribe(occurrences=>this.occurrences = occurrences);
  }

  editOCcurrence(occurrence) {
    this.occtaxFormOccurrenceService.occurrence.next(occurrence);
  }

  get occIDInEdit() {
    let occurrence = this.occtaxFormOccurrenceService.occurrence.getValue();
    return occurrence ? occurrence.id_occurrence_occtax : null;
  }

}
