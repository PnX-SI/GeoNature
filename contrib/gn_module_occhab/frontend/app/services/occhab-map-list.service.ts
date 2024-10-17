import { Injectable } from "@angular/core";
import { UntypedFormBuilder, UntypedFormGroup } from "@angular/forms";
import { MapListService } from "@geonature_common/map-list/map-list.service";
import { OccHabDataService } from "../services/data.service";
import * as moment from "moment";

@Injectable()
export class OccHabMapListService {
  public searchForm: UntypedFormGroup;
  public mapListService: MapListService;
  constructor(
    private _fb: UntypedFormBuilder,
    private _occHabDataService: OccHabDataService
  ) {
    this.searchForm = this._fb.group({
      id_dataset: null,
      id_import: null,
      date_low: null,
      date_up: null,
      habitat: null,
    });
  }
  nbOfFilter() {
    let result = 0;
    Object.keys(this.searchForm.value).forEach((key) => {
      if (this.searchForm.value[key]) {
        result = result + 1;
      }
    });
    return result;
  }
}
