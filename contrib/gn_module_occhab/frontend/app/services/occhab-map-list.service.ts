import { Injectable } from "@angular/core";
import { FormBuilder, FormGroup } from "@angular/forms";
import { MapListService } from "@geonature_common/map-list/map-list.service";
import { OccHabDataService } from "../services/data.service";
import * as moment from "moment";

@Injectable()
export class OccHabMapListService {
  public searchForm: FormGroup;
  public mapListService: MapListService;
  constructor(
    private _fb: FormBuilder,
    private _occHabDataService: OccHabDataService
  ) {
    this.searchForm = this._fb.group({
      id_dataset: null,
      date_low: null,
      date_up: null,
      habitat: null
    });
  }
}
