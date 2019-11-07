import { Component, OnInit, Output, EventEmitter } from "@angular/core";
import { OccHabMapListService } from "../services/occhab-map-list.service";
import { AppConfig } from "@geonature_config/app.config";

@Component({
  selector: "pnx-occhab-map-list-filter",
  templateUrl: "./occhab-map-list-filter.component.html",
  styleUrls: ["./occhab-map-list-filter.component.scss"]
})
export class OcchabMapListFilterComponent implements OnInit {
  constructor(public mapListFormService: OccHabMapListService) {}
  public appConfig = AppConfig;
  @Output() onSearch = new EventEmitter<any>();
  ngOnInit() {}

  formatter(item) {
    return item.search_name;
  }

  searchEvent($event) {
    this.onSearch.emit(this.cleanFilter());
  }

  resetFilterForm() {
    this.mapListFormService.searchForm.reset();
  }

  /** return only the form items where value is not null or empty array */
  cleanFilter() {
    const cleanedObject = {};
    Object.keys(this.mapListFormService.searchForm.value).forEach(key => {
      if (
        this.mapListFormService.searchForm.value[key] ||
        (Array.isArray(this.mapListFormService.searchForm.value[key]) &&
          this.mapListFormService.searchForm.value[key] > 0)
      ) {
        cleanedObject[key] = this.mapListFormService.searchForm.value[key];
      }
    });
    return cleanedObject;
  }
}
