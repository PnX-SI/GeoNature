import { Subscription } from "rxjs";
import {
  Component,
  OnInit,
  Input,
  Output,
  EventEmitter,
  ViewChild
} from "@angular/core";
import { FormBuilder } from "@angular/forms";
import { DataService } from "../../services/data.service";
import { FormService } from "../../services/form.service";
import { NgbModal } from "@ng-bootstrap/ng-bootstrap";
import { AppConfig } from "@geonature_config/app.config";
import { MapService } from "@geonature_common/map/map.service";
import {
  TreeComponent,
  TreeModel,
  TreeNode,
  TREE_ACTIONS,
  IActionMapping,
  ITreeOptions
} from "angular-tree-component";
import { ValidationTaxonAdvancedModalComponent } from "./validation-taxon-advanced/validation-taxon-advanced.component";
import { ValidationTaxonAdvancedStoreService } from "./validation-taxon-advanced/validation-taxon-advanced-store.service";
import { NomenclatureComponent } from "@geonature_common/form/nomenclature/nomenclature.component";
import { DataFormService } from "@geonature_common/form/data-form.service";

@Component({
  selector: "pnx-validation-search",
  templateUrl: "validation-search.component.html",
  styleUrls: ["validation-search.component.scss"],
  providers: []
})
export class ValidationSearchComponent implements OnInit {
  public AppConfig = AppConfig;
  public control_keys;
  public taxonApiEndPoint = `${
    AppConfig.API_ENDPOINT
  }/validation/taxons_autocomplete`;
  public areaFilters: Array<any>;

  @Output() searchClicked = new EventEmitter();
  public values;

  constructor(
    public dataService: DataService,
    public formService: FormService,
    public ngbModal: NgbModal,
    public mapService: MapService,
    private _storeService: ValidationTaxonAdvancedStoreService,
    public nomenclat: NomenclatureComponent,
    private _dfs: DataFormService
  ) {}

  ngOnInit() {
    // format areas filter
    this.areaFilters = AppConfig.SYNTHESE.AREA_FILTERS.map(area => {
      if (typeof area.id_type === "number") {
        area["id_type_array"] = [area.id_type];
      } else {
        area["id_type_array"] = area.id_type;
      }
      return area;
    });

    this._dfs.getNomenclatures("STATUT_VALID").subscribe(data => {
      this.values = data[0].values;
    });
  }

  onSubmitForm() {
    // mark as dirty to avoid set limit=100 when download
    //this.formService.searchForm.markAsDirty();
    //console.log(this.formService.searchForm);
    const updatedParams = this.formService.formatParams();
    this.searchClicked.emit(updatedParams);
  }

  refreshFilters() {
    this.formService.selectedtaxonFromComponent = [];
    this.formService.selectedCdRefFromTree = [];
    //this.formService.dynamycFormDef = [];
    this.formService.searchForm.reset();

    // refresh taxon tree
    this._storeService.taxonTreeState = {};

    // remove layers draw in the map
    if (this.mapService.releveFeatureGroup != undefined) {
      this.mapService.removeAllLayers(
        this.mapService.map,
        this.mapService.releveFeatureGroup
      );
    }
  }

  openModal() {
    const taxonModal = this.ngbModal.open(
      ValidationTaxonAdvancedModalComponent,
      {
        size: "lg",
        backdrop: "static",
        keyboard: false
      }
    );
  }
}
