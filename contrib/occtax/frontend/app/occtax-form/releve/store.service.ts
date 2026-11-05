import { Injectable } from "@angular/core";
import { DataFormService } from "@geonature_common/form/data-form.service";
import { ConfigService } from "@geonature/services/config.service";


@Injectable()
export class OcctaxStoreService {
  public typoHabitat: Array<any> = [];
  constructor(
    private _gnDataService: DataFormService,
    public config: ConfigService
  ) {
    this._gnDataService
      .getTypologyHabitat(this.config.OCCHAB.ID_LIST_HABITAT)
      .subscribe((data) => {
        this.typoHabitat = data.filter((typoref)=> typoref.type_table === "TYPO");
      });
  }
}
