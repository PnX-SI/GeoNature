import { Component, OnInit, Output, EventEmitter } from "@angular/core";
import { OccHabMapListService } from "../../services/occhab-map-list.service";
import { ConfigService } from '@geonature/utils/configModule/core';
import { NgbDateParserFormatter } from "@ng-bootstrap/ng-bootstrap";
import { ModuleConfig } from "../../module.config";

@Component({
  selector: "pnx-occhab-map-list-filter",
  templateUrl: "./occhab-map-list-filter.component.html",
  styleUrls: ["./occhab-map-list-filter.component.scss"]
})
export class OcchabMapListFilterComponent implements OnInit {

  constructor(
    public mapListFormService: OccHabMapListService,
    private _dateParser: NgbDateParserFormatter,
    private _configService: ConfigService,
  ) {
    this.appConfig = this._configService.getSettings();
  }

  public appConfig: any;
  public moduleConfig = ModuleConfig;

  @Output() onSearch = new EventEmitter<any>();

  formatter(item) {
    return item.search_name;
  }

  searchEvent($event) {
    this.onSearch.emit(this.cleanFilter());
  }

  resetFilterForm() {
    this.mapListFormService.searchForm.reset();
  }

  cleanFilter() {
    const cleanedObject = {};
    Object.keys(this.mapListFormService.searchForm.value).forEach(key => {
      /** return only the form items where value is not null or empty array */
      if (
        this.mapListFormService.searchForm.value[key] ||
        (Array.isArray(this.mapListFormService.searchForm.value[key]) &&
          this.mapListFormService.searchForm.value[key] > 0)
      ) {
        if (key == "habitat") {
          cleanedObject["cd_hab"] = this.mapListFormService.searchForm.value[
            key
          ]["cd_hab"];
        } else if (key === "date_low" || key === "date_up") {
          console.log(this.mapListFormService.searchForm.value[key]);

          cleanedObject[key] = this._dateParser.format(
            this.mapListFormService.searchForm.value[key]
          );
        } else {
          cleanedObject[key] = this.mapListFormService.searchForm.value[key];
        }
      }
    });
    return cleanedObject;
  }
}
