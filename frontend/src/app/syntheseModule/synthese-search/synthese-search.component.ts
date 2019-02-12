import { Component, OnInit, Output, EventEmitter, ViewChild } from '@angular/core';
import { DataService } from '../services/data.service';
import { SyntheseFormService } from '../services/form.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { AppConfig } from '@geonature_config/app.config';
import { MapService } from '@geonature_common/map/map.service';
import { TaxonAdvancedModalComponent } from './taxon-advanced/taxon-advanced.component';
import { TaxonAdvancedStoreService } from './taxon-advanced/taxon-advanced-store.service';
import { DataFormService } from '@geonature_common/form/data-form.service';

@Component({
  selector: 'pnx-synthese-search',
  templateUrl: 'synthese-search.component.html',
  styleUrls: ['synthese-search.component.scss'],
  providers: []
})
export class SyntheseSearchComponent implements OnInit {
  public AppConfig = AppConfig;
  public organisms: any;
  public areaFilters: Array<any>;

  public taxonApiEndPoint = `${AppConfig.API_ENDPOINT}/synthese/taxons_autocomplete`;
  @Output() searchClicked = new EventEmitter();
  constructor(
    public dataService: DataService,
    public formService: SyntheseFormService,
    public ngbModal: NgbModal,
    public mapService: MapService,
    private _storeService: TaxonAdvancedStoreService,
    private _api: DataFormService
  ) {}

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
  }

  onSubmitForm() {
    // mark as dirty to avoid set limit=100 when download
    this.formService.searchForm.markAsDirty();
    const updatedParams = this.formService.formatParams();
    this.searchClicked.emit(updatedParams);
  }

  refreshFilters() {
    this.formService.selectedtaxonFromComponent = [];
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
