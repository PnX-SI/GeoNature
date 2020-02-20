import { Component, Input, OnInit } from "@angular/core";
import { filter, map } from 'rxjs/operators';
import { OcctaxFormService } from "../occtax-form.service";


@Component({
  selector: "pnx-occtax-form-taxa-list",
  templateUrl: "./taxa-list.component.html",
  styleUrls: ["./taxa-list.component.scss"]
})
export class OcctaxFormTaxaListComponent implements OnInit {

  public taxons: Array<any>;

  constructor(public occtaxFormService: OcctaxFormService) { }

  ngOnInit() {
    this.occtaxFormService.occtaxData
              .pipe(
                filter(data=> data && data.releve.properties.t_occurrences_occtax),
                map(data=>data.releve.properties.t_occurrences_occtax.sort((o1, o2) => {
                  const name1 = (o1.taxref ? o1.taxref.nom_complet : o1.nom_cite.replace(/<[^>]*>/g, '')).toLowerCase();
                  const name2 = (o2.taxref ? o2.taxref.nom_complet : o2.nom_cite.replace(/<[^>]*>/g, '')).toLowerCase();
                  if (name1 > name2) { return 1; }
                  if (name1 < name2) { return -1; }
                  return 0;
                  //return (o1.taxref.nom_complet|o1.nom_cite) > (o2.taxref.nom_complet|o2.nom_cite) ? 1 : 0;
                }))
              )
              .subscribe(taxons=>this.taxons = taxons);
  }

}
