import {
  Component,
  OnInit,
  OnChanges,
  Output,
  EventEmitter,
  Input,
  ViewEncapsulation,
  SimpleChanges,
} from '@angular/core';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { MapService } from '@geonature_common/map/map.service';
import { TaxonAdvancedModalComponent } from '@geonature_common/form/synthese-form/advanced-form/synthese-advanced-form-component';
import { TaxonAdvancedStoreService } from '@geonature_common/form/synthese-form/advanced-form/synthese-advanced-form-store.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'pnx-synthese-search',
  templateUrl: 'synthese-form.component.html',
  styleUrls: ['synthese-form.component.scss'],
  providers: [],
  encapsulation: ViewEncapsulation.None,
})
export class SyntheseSearchComponent implements OnInit, OnChanges {
  public organisms: Array<any>;
  public taxonApiEndPoint = null;
  public validationStatus: Array<any>;

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

  constructor(
    public dataService: SyntheseDataService,
    public formService: SyntheseFormService,
    public ngbModal: NgbModal,
    public mapService: MapService,
    private _storeService: TaxonAdvancedStoreService,
    private _api: DataFormService,
    public config: ConfigService
  ) {
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

    this._handleDisplayValidation();
  }

  ngOnChanges(changes: SimpleChanges) {
    if (changes.displayValidation) {
      this._handleDisplayValidation();
    }
  }

  private _handleDisplayValidation() {
    this.formService.configureValidationControls(this.displayValidation);
    if (this.displayValidation) {
      this._api.getNomenclatures(['STATUT_VALID']).subscribe((data) => {
        this.validationStatus = data[0].values;
      });
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
