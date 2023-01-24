import { Component, OnInit, Output, EventEmitter, Input, ViewEncapsulation } from '@angular/core';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { MapService } from '@geonature_common/map/map.service';
import { TaxonAdvancedModalComponent } from '@geonature_common/form/synthese-form/advanced-form/synthese-advanced-form-component';
import { TaxonAdvancedStoreService } from '@geonature_common/form/synthese-form/advanced-form/synthese-advanced-form-store.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { ActivatedRoute } from '@angular/router';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'pnx-synthese-search',
  templateUrl: 'synthese-form.component.html',
  styleUrls: ['synthese-form.component.scss'],
  providers: [],
  encapsulation: ViewEncapsulation.None,
})
export class SyntheseSearchComponent implements OnInit {
  public AppConfig = null;
  public organisms: Array<any>;
  public taxonApiEndPoint = null;
  public validationStatus: Array<any>;
  private params: any;

  @Input() displayValidation = false;
  @Output() searchClicked = new EventEmitter();
  @Output() resetFilter = new EventEmitter();

  constructor(
    public dataService: SyntheseDataService,
    public formService: SyntheseFormService,
    public ngbModal: NgbModal,
    public mapService: MapService,
    private _storeService: TaxonAdvancedStoreService,
    private _api: DataFormService,
    private route: ActivatedRoute,
    public cs: ConfigService
  ) {
    this.route.queryParams.subscribe((params) => {
      this.params = params;
    });
    this.AppConfig = this.cs;
    this.taxonApiEndPoint = `${this.AppConfig.API_ENDPOINT}/synthese/taxons_autocomplete`
  }

  ngOnInit() {
    // get organisms:
    this._api.getOrganismsDatasets().subscribe((data) => {
      this.organisms = data;
    });

    // format areas filter
    this.formService.areasFilters.map((area) => {
      if (typeof area['type_code'] === 'string') {
        area['type_code_array'] = [area['type_code']];
      } else {
        area['type_code_array'] = area['type_code'];
      }
      return area;
    });

    if (this.displayValidation) {
      this._api.getNomenclatures(['STATUT_VALID']).subscribe((data) => {
        this.validationStatus = data[0].values;
      });
    }

    if (this.params) {
      if (this.params.id_acquisition_framework) {
        this.formService.searchForm.controls.id_acquisition_framework.setValue([
          +this.params.id_acquisition_framework,
        ]);
      }

      if (this.params.id_dataset) {
        this.formService.searchForm.controls.id_dataset.setValue([+this.params.id_dataset]);
      }
    }
  }

  onSubmitForm() {
    const updatedParams = this.formService.formatParams();
    this.searchClicked.emit(updatedParams);
  }

  refreshFilters() {
    this.formService.selectedtaxonFromComponent = [];
    this.formService.selectedTaxonFromRankInput = [];
    this.formService.selectedCdRefFromTree = [];
    this.formService.selectedRedLists = [];
    this.formService.selectedStatus = [];
    this.formService.selectedTaxRefAttributs = [];
    this.formService.searchForm.reset();
    this.resetFilter.emit();

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
      keyboard: false,
    });
  }
}
