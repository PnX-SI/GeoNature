import { Component, OnInit, ViewChild } from "@angular/core";
import { MapListService } from "@geonature_common/map-list/map-list.service";
import { OcctaxDataService } from "../../services/occtax-data.service";
import { CommonService } from "@geonature_common/service/common.service";
import { Router } from "@angular/router";
import { NgbModal } from "@ng-bootstrap/ng-bootstrap";
import { ModuleConfig } from "../../module.config";
import { TaxonomyComponent } from "@geonature_common/form/taxonomy/taxonomy.component";
import { FormGroup, FormBuilder } from "@angular/forms";
import { GenericFormGeneratorComponent } from "@geonature_common/form/dynamic-form-generator/dynamic-form-generator.component";
import { NgbDateParserFormatter } from "@ng-bootstrap/ng-bootstrap";
import { FILTERSLIST } from "./filters-list";
import { AppConfig } from "@geonature_config/app.config";
import { GlobalSubService } from "@geonature/services/global-sub.service";
import { Subscription } from "rxjs/Subscription";
import { HttpParams } from '@angular/common/http';

@Component({
  selector: "pnx-occtax-map-list-filter",
  templateUrl: "occtax-map-list-filter.component.html",
  styleUrls: ["./occtax-map-list-filter.component.scss"]
})
export class OcctaxMapListFilterComponent implements OnInit {
  public formsDefinition = FILTERSLIST;
  public dynamicFormGroup: FormGroup;
  public formsSelected = [];
  public displayParams: HttpParams = new HttpParams();
  public occtaxConfig: any;
  @ViewChild(TaxonomyComponent)
  public taxonomyComponent: TaxonomyComponent;

  advandedFilterOpen = false;

  constructor(
    private mapListService: MapListService,
    private _fb: FormBuilder,
    private _dateParser: NgbDateParserFormatter
  ) {}

  ngOnInit() {

    this.dynamicFormGroup = this._fb.group({
      cd_nom: null,
      observers: null,
      dataset: null,
      observers_txt: null,
      id_dataset: null,
      date_up: null,
      date_low: null,
      municipality: null
    });

    this.occtaxConfig = ModuleConfig;

  }


  searchData() {
    this.mapListService.refreshUrlQuery(12);
    const params = [];
    for (let key in this.dynamicFormGroup.value) {
      let value = this.dynamicFormGroup.value[key];
      if (key === "cd_nom" && value) {
        value = this.dynamicFormGroup.value[key].cd_nom;
        params.push({ param: key, value: value });
      } else if ((key === "date_up" || key === "date_low") && value) {
        value = this._dateParser.format(this.dynamicFormGroup.value[key]);
        params.push({ param: key, value: value });
      } else if (key === "observers" && value) {
        this.dynamicFormGroup.value.observers.forEach(observer => {
          params.push({ param: "observers", value: observer });
        });
      } else if (value && value !== "") {
        params.push({ param: key, value: value });
      }
    }
    this.closeAdvancedFilters();
    this.mapListService.refreshData(null, "set", params);
  }

  toggleAdvancedFilters() {
    this.advandedFilterOpen = !this.advandedFilterOpen;
  }

  closeAdvancedFilters() {
    this.advandedFilterOpen = false;
  }

  refreshFilters() {
    this.taxonomyComponent.refreshAllInput();
    this.dynamicFormGroup.reset();
    this.mapListService.refreshUrlQuery(12);
  }
}
