import { Component, OnInit, Output, EventEmitter, Input } from '@angular/core';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { AppConfig } from '@geonature_config/app.config';
import { MapService } from '@geonature_common/map/map.service';
import { TaxonAdvancedModalComponent } from '@geonature_common/form/synthese-form/advanced-form/synthese-advanced-form-component';
import { TaxonAdvancedStoreService } from '@geonature_common/form/synthese-form/advanced-form/synthese-advanced-form-store.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import {ActivatedRoute} from "@angular/router";

@Component({
  selector: 'pnx-synthese-search',
  templateUrl: 'synthese-form.component.html',
  styleUrls: ['synthese-form.component.scss'],
  providers: []
})
export class SyntheseSearchComponent implements OnInit {
  public AppConfig = AppConfig;
  public organisms: any;
  public areaFilters: Array<any>;
  public taxonApiEndPoint = `${AppConfig.API_ENDPOINT}/synthese/taxons_autocomplete`;
  public validationStatus: Array<any>;
  private params: any;
  @Input() displayValidation = false;
  @Output() searchClicked = new EventEmitter();
  constructor(
    public dataService: SyntheseDataService,
    public formService: SyntheseFormService,
    public ngbModal: NgbModal,
    public mapService: MapService,
    private _storeService: TaxonAdvancedStoreService,
    private _api: DataFormService,
    private route: ActivatedRoute
  ) {
    this.route.queryParams.subscribe(params => {
      this.params = params;
  });
  }

  ngOnInit() {
    // get organisms:
    this._api.getOrganismsDatasets().subscribe(data => {
      this.organisms = data;
    });

    // format areas filter
    this.areaFilters = AppConfig.SYNTHESE.AREA_FILTERS.map(area => {
      if (typeof area.id_type === 'number') {
        area['id_type_array'] = [area.id_type];
      } else {
        area['id_type_array'] = area.id_type;
      }
      return area;
    });

    if (this.displayValidation) {
      this._api.getNomenclatures(['STATUT_VALID']).subscribe(data => {
        this.validationStatus = data[0].values;
      });
    }

    //let params = {'id_acquisition_framework': [2]}

    //this.params = {'id_acquisition_framework': 2}


    if (this.params) {
      console.log("this.params");
      console.log(this.params);
      console.log(this.params.id_acquisition_framework);

      if (this.params.id_acquisition_framework)
      this.formService.searchForm.controls.id_acquisition_framework.setValue([+this.params.id_acquisition_framework])
    
      if (this.params.id_dataset)
        this.formService.searchForm.controls.id_dataset.setValue([+this.params.id_dataset])

      this.onSubmitForm();
    }

    

  }

  onSubmitForm() {
    // mark as dirty to avoid set limit=100 when download
    this.formService.searchForm.markAsDirty();
    const updatedParams = this.formService.formatParams();
    this.searchClicked.emit(updatedParams);
    console.log("updatedParams");
    console.log(updatedParams);
    console.log(updatedParams['id_acquisition_framework']);
  }

  refreshFilters() {
    this.formService.selectedtaxonFromComponent = [];
    this.formService.selectedTaxonFromRankInput = [];
    this.formService.selectedCdRefFromTree = [];
    this.formService.searchForm.reset();

    // refresh taxon tree
    this._storeService.taxonTreeState = {};

    // remove layers draw in the map
    this.mapService.removeAllLayers(this.mapService.map, this.mapService.leafletDrawFeatureGroup);
    this.mapService.removeAllLayers(this.mapService.map, this.mapService.fileLayerFeatureGroup);
  }

  openModal() {
    const taxonModal = this.ngbModal.open(TaxonAdvancedModalComponent, {
      size: 'lg',
      backdrop: 'static',
      keyboard: false
    });
  }
}
