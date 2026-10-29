import { Component, OnInit, ViewChild } from '@angular/core';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { TaxonomyComponent } from '@geonature_common/form/taxonomy/taxonomy.component';
import { UntypedFormGroup } from '@angular/forms';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { FILTERSLIST } from './filters-list';
import { HttpParams } from '@angular/common/http';
import { OcctaxMapListService } from '../occtax-map-list.service';
import { ModuleService } from '@geonature/services/module.service';
import { OcctaxConfigService } from '../../services/occtax-config.service';
import { TranslateService } from '@ngx-translate/core';

@Component({
  selector: 'pnx-occtax-map-list-filter',
  templateUrl: 'occtax-map-list-filter.component.html',
  styleUrls: ['./occtax-map-list-filter.component.scss'],
})
export class OcctaxMapListFilterComponent implements OnInit {
  public formsDefinition = FILTERSLIST.map((formDef) => ({ ...formDef }));
  public dynamicFormGroup: UntypedFormGroup;
  public formsSelected = [];
  public displayParams: HttpParams = new HttpParams();
  @ViewChild(TaxonomyComponent)
  public taxonomyComponent: TaxonomyComponent;

  advandedFilterOpen = false;

  constructor(
    private mapListService: MapListService,
    private _dateParser: NgbDateParserFormatter,
    public occtaxMapListService: OcctaxMapListService,
    public moduleService: ModuleService,
    public occtaxConfig: OcctaxConfigService,
    private _translate: TranslateService
  ) {
    // labels shared with the Synthese filters, mutated in place to keep the form controls
    const labelKey = (formDef) =>
      formDef.attribut_name === 'id_releve_occtax'
        ? 'Occtax.UI.SurveyIdFilter'
        : `Synthese.DynamicFilters.${formDef.attribut_name}`;
    this._translate.stream(this.formsDefinition.map(labelKey)).subscribe((labels) => {
      this.formsDefinition.forEach(
        (formDef) => (formDef.attribut_label = labels[labelKey(formDef)])
      );
    });
  }

  ngOnInit() {}

  searchData() {
    this.mapListService.zoomOnLayer = true;
    this.mapListService.refreshUrlQuery(this.occtaxMapListService.rowPerPage);
    const params = [];
    for (let key in this.occtaxMapListService.dynamicFormGroup.value) {
      let value = this.occtaxMapListService.dynamicFormGroup.value[key];
      if (key === 'cd_nom' && value) {
        value = this.occtaxMapListService.dynamicFormGroup.value[key].cd_nom;
        params.push({ param: key, value: value });
      } else if ((key === 'date_up' || key === 'date_low') && value) {
        value = this._dateParser.format(this.occtaxMapListService.dynamicFormGroup.value[key]);
        params.push({ param: key, value: value });
      } else if (key === 'observers' && value) {
        this.occtaxMapListService.dynamicFormGroup.value.observers.forEach((observer) => {
          params.push({ param: 'observers', value: observer.id_role });
        });
      } else if (value && value !== '') {
        params.push({ param: key, value: value });
      }
    }
    this.closeAdvancedFilters();
    this.mapListService.refreshData(null, 'set', params);
  }

  toggleAdvancedFilters() {
    this.advandedFilterOpen = !this.advandedFilterOpen;
  }

  closeAdvancedFilters() {
    this.advandedFilterOpen = false;
  }

  refreshFilters() {
    this.taxonomyComponent.refreshAllInput();
    this.occtaxMapListService.dynamicFormGroup.reset();
    this.mapListService.refreshUrlQuery(12);
  }
}
