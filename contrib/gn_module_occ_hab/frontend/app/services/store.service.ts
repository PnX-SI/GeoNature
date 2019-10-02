import { Injectable } from "@angular/core";
import { DataFormService } from "@geonature_common/form/data-form.service";

@Injectable()
export class OcchabStoreService {
  public nomenclatureItems = {};
  constructor(private _gnDataService: DataFormService) {
    this._gnDataService
      .getNomenclatures([
        "METHOD_CALCUL_SURFACE",
        "DETERMINATION_TYP_HAB",
        "TECHNIQUE_COLLECT_HAB",
        "HAB_INTERET_COM",
        "EXPOSITION",
        "NAT_OBJ_GEO",
        "HAB_INTERET_COM",
        "ABONDANCE_HAB"
      ])
      .subscribe(data => {
        data.forEach(element => {
          this.nomenclatureItems[element.mnemonique] = element.values;
        });
        console.log(this.nomenclatureItems);
      });
  }
}
