import {
  Component,
  OnInit,
  Output,
  EventEmitter,
  Input,
  ViewEncapsulation,
  TemplateRef,
  ViewChild,
} from '@angular/core';
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
  public organisms: Array<any>;
  public taxonApiEndPoint = null;
  public validationStatus: Array<any>;
  private params: any;

  public isCollapsePeriod = true;
  public isCollapseScore = true;

  @Input() displayValidation = false;
  // valeur des filtres par defaut
  // les nomenclature sont données en liste de code de nomenclaure
  // par exemple :
  //    id_nomenclature_valid_status = ['0', '1', '2', '3', '5', '6']
  @Input() defaultFilters = {};
  @Output() searchClicked = new EventEmitter();
  @Output() resetFilter = new EventEmitter();

  @ViewChild('confirmSearchModal') private confirmSearchModal: TemplateRef<any>;

  public filtersToConfirm: Array<{ name: string; value: any }> = [];

  constructor(
    public dataService: SyntheseDataService,
    public formService: SyntheseFormService,
    public ngbModal: NgbModal,
    public mapService: MapService,
    private _storeService: TaxonAdvancedStoreService,
    private _api: DataFormService,
    private route: ActivatedRoute,
    public config: ConfigService
  ) {
    this.route.queryParams.subscribe((params) => {
      this.params = params;
    });
    this.taxonApiEndPoint = `${this.config.API_ENDPOINT}/synthese/taxons_autocomplete`;
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
    const configuredFilters = this.config.SYNTHESE.CONFIRM_SEARCH_FILTERS || [];
    this.filtersToConfirm = configuredFilters
      .filter((configuredFilter) =>
        this.hasValueToConfirm(configuredFilter, updatedParams[configuredFilter.field])
      )
      .map((configuredFilter) => ({
        field: configuredFilter.field,
        value: updatedParams[configuredFilter.field],
        message: configuredFilter.message?.trim() || 'Filters.ConfirmSearch.DefaultMessage',
      }));

    if (this.filtersToConfirm.length === 0) {
      this.searchClicked.emit(updatedParams);
      return;
    }

    const modalRef = this.ngbModal.open(this.confirmSearchModal, { centered: true });
    modalRef.result.then(
      () => this.searchClicked.emit(updatedParams), //on fullfilled
      () => {} // on rejected
    );
  }

  private hasValueToConfirm(filter: any, value: any): boolean {
    const configuredValues = Array.isArray(filter.values) ? filter.values : [];
    const selectedValues = (Array.isArray(value) ? value : value == null ? [] : [value]).filter(
      (item) => item != null && !(typeof item === 'string' && item.trim() === '')
    );

    // Without specific trigger values, confirm when this filter has a value when confirmOnAbsence.
    // And confirm when no value is selected when confirmOnAbsence is true
    if (configuredValues.length === 0) {
      return filter.confirmOnAbsence ? selectedValues.length === 0 : selectedValues.length > 0;
    }

    const isIntersected = selectedValues.some((item) => configuredValues.includes(item));
    return filter.confirmOnAbsence ? !isIntersected : isIntersected;
  }

  refreshFilters() {
    this.formService.selectedtaxonFromComponent = [];
    this.formService.selectedTaxonFromRankInput = [];
    this.formService.selectedCdRefFromTree = [];
    this.formService.selectedRedLists = [];
    this.formService.selectedStatus = [];
    this.formService.selectedTaxRefAttributs = [];
    this.formService.searchForm.reset(this.formService.processedDefaultFilters);
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
