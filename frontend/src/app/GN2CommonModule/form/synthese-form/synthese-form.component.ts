import { Component, OnInit, Output, EventEmitter, Input, ViewEncapsulation } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { forkJoin, Observable, of } from 'rxjs';
import { map, tap } from 'rxjs/operators';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { MapService } from '@geonature_common/map/map.service';
import { TaxonAdvancedModalComponent } from '@geonature_common/form/synthese-form/advanced-form/synthese-advanced-form-component';
import {
  SearchFilter,
  ConfirmationModalComponent,
} from '@geonature_common/form/synthese-form/confirmation-modal/confirmation-modal.component';
import { TaxonAdvancedStoreService } from '@geonature_common/form/synthese-form/advanced-form/synthese-advanced-form-store.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { ActivatedRoute } from '@angular/router';
import { ConfigService } from '@geonature/services/config.service';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import {
  hasValueToConfirm,
  getTaxonRefs,
  SearchParams,
  restoreSearchParams,
  TaxonRef,
  Digitiser,
} from './search-filter-restoration/search-filter-restoration';

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

  public filtersToConfirm: SearchFilter[] = [];

  constructor(
    public dataService: SyntheseDataService,
    public formService: SyntheseFormService,
    public ngbModal: NgbModal,
    public mapService: MapService,
    private _storeService: TaxonAdvancedStoreService,
    private _api: DataFormService,
    private route: ActivatedRoute,
    public config: ConfigService,
    public dialog: MatDialog
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
    const configuredFiltersToConfirm = this.config.SYNTHESE.CONFIRM_SEARCH_FILTERS || [];
    this.filtersToConfirm = configuredFiltersToConfirm
      .filter((configuredFilter: SearchFilter) =>
        hasValueToConfirm(configuredFilter, updatedParams[configuredFilter.field])
      )
      .map((configuredFilter: SearchFilter) => ({
        field: configuredFilter.field,
        message: configuredFilter.message?.trim() || 'Filters.ConfirmSearch.DefaultMessage',
        confirmOnAbsence: configuredFilter.confirmOnAbsence,
        values: configuredFilter.values,
      }));

    if (this.filtersToConfirm.length === 0) {
      this.searchClicked.emit(updatedParams);
      return;
    }

    const dialogRef = this.dialog.open(ConfirmationModalComponent, {
      data: this.filtersToConfirm,
    });
    dialogRef.afterClosed().subscribe((feedback: { canceled?: boolean; confirmed?: boolean }) => {
      if (!feedback) {
        return;
      }
      if (feedback.confirmed) {
        this.searchClicked.emit(updatedParams);
      }
      if (feedback.canceled) {
        this.restoreCanceledSearch(updatedParams, this.filtersToConfirm).subscribe(
          (restoredParams) => this.searchClicked.emit(restoredParams)
        );
      }
    });
  }

  private restoreCanceledSearch(
    params: SearchParams,
    filters: SearchFilter[]
  ): Observable<SearchParams> {
    const restoredParams = restoreSearchParams(params, filters);
    const hasCdRefFilter = filters.some((filter) => filter.field === 'cd_ref');
    const hasCdRefParentFilter = filters.some((filter) => filter.field === 'cd_ref_parent');
    const hasDigitiserFilter = filters.some((filter) => filter.field === 'id_digitiser');
    const restoreTaxa$ = hasCdRefFilter
      ? this.restoreSelectedTaxa(getTaxonRefs(restoredParams.cd_ref))
      : of([]);
    const restoreParentTaxa$ = hasCdRefParentFilter
      ? this.restoreSelectedParentTaxa(getTaxonRefs(restoredParams.cd_ref_parent))
      : of([]);
    const restoreDigitisers$ = hasDigitiserFilter
      ? this.restoreDigitisers(restoredParams.id_digitiser)
      : of([]);

    return forkJoin([restoreTaxa$, restoreParentTaxa$, restoreDigitisers$]).pipe(
      map(([, , digitisers]) => {
        this.syncFormControls(restoredParams, filters);
        if (hasDigitiserFilter) {
          this.formService.searchForm.get('id_digitiser')?.setValue(digitisers);
        }
        return restoredParams;
      })
    );
  }

  private syncFormControls(params: SearchParams, filters: SearchFilter[]): void {
    const stateBackedFields = new Set(['cd_ref', 'cd_ref_parent', 'id_digitiser']);
    filters
      .filter((filter) => !stateBackedFields.has(filter.field))
      .forEach((filter) => {
        const control = this.formService.searchForm.get(filter.field);
        if (control) {
          control.setValue(this.formService.toFormValue(filter.field, params[filter.field]));
        }
      });
  }

  private restoreSelectedTaxa(cdRefs: TaxonRef[]): Observable<Taxon[]> {
    return this.resolveTaxa(cdRefs, this.formService.selectedtaxonFromComponent).pipe(
      tap((taxa) => {
        this.formService.selectedtaxonFromComponent = taxa;
      })
    );
  }

  private resolveTaxa(cdRefs: TaxonRef[], knownTaxa: Taxon[]): Observable<Taxon[]> {
    const targetCdRefs = Array.from(new Map(cdRefs.map((ref) => [String(ref), ref])).values());
    const taxaByCdRef = new Map(
      knownTaxa
        .filter((taxon) => taxon.cd_ref != null)
        .map((taxon) => [String(taxon.cd_ref), taxon])
    );
    const missingCdRefs = targetCdRefs.filter((cdRef) => !taxaByCdRef.has(String(cdRef)));
    const taxonRequests = missingCdRefs.map((cdRef) => {
      const cdNom = Number(cdRef);
      if (!Number.isSafeInteger(cdNom)) {
        throw new Error(`Invalid taxon reference: ${String(cdRef)}`);
      }
      return this._api.getTaxonInfo(cdNom);
    });
    const restoredTaxa$: Observable<Taxon[]> =
      taxonRequests.length > 0 ? forkJoin(taxonRequests) : of([]);

    return restoredTaxa$.pipe(
      map((taxa) => {
        taxa.forEach((taxon) => {
          if (taxon.cd_ref != null) {
            taxaByCdRef.set(String(taxon.cd_ref), taxon);
          }
        });
        return targetCdRefs.map((cdRef) => {
          const taxon = taxaByCdRef.get(String(cdRef));
          if (!taxon) {
            throw new Error(`Could not restore taxon with cd_ref ${cdRef}`);
          }
          return taxon;
        });
      })
    );
  }

  private restoreSelectedParentTaxa(cdRefs: TaxonRef[]): Observable<Taxon[]> {
    const targetCdRefs = Array.from(
      new Map(cdRefs.map((cdRef) => [String(cdRef), cdRef])).values()
    );
    const targetCdRefSet = new Set(targetCdRefs.map((cdRef) => String(cdRef)));
    const selectedRankTaxa = this.formService.selectedTaxonFromRankInput.filter((taxon) =>
      targetCdRefSet.has(String(taxon.cd_ref))
    );
    const selectedTreeCdRefs = this.formService.selectedCdRefFromTree.filter((cdRef) =>
      targetCdRefSet.has(String(cdRef))
    );
    const selectedTreeCdRefSet = new Set(selectedTreeCdRefs.map((cdRef) => String(cdRef)));
    const rankCdRefs = targetCdRefs.filter((cdRef) => !selectedTreeCdRefSet.has(String(cdRef)));

    return this.resolveTaxa(rankCdRefs, selectedRankTaxa).pipe(
      tap((taxa) => {
        this.formService.selectedTaxonFromRankInput = taxa;
        this.restoreTreeSelection(selectedTreeCdRefs);
        this.formService.selectedCdRefFromTree = selectedTreeCdRefs;
      })
    );
  }

  private restoreTreeSelection(cdRefs: TaxonRef[]): void {
    if (!this._storeService.treeModel) {
      return;
    }

    const selectedCdRefs = new Set(cdRefs.map((cdRef) => String(cdRef)));
    this._storeService.treeModel.doForAll((node) => {
      if (node.data.leaf) {
        node.setIsSelected(selectedCdRefs.has(String(node.data.id)));
      }
    });
    this._storeService.taxonTreeState = this._storeService.treeModel.getState();
  }

  private restoreDigitisers(ids: unknown): Observable<Digitiser[]> {
    const rawIds = Array.isArray(ids) ? ids : ids == null ? [] : [ids];
    const digitiserIds = rawIds.map((id) => {
      if (typeof id !== 'number' && typeof id !== 'string') {
        throw new Error(`Invalid digitiser id: ${String(id)}`);
      }
      return id;
    });
    if (digitiserIds.length === 0) {
      return of([]);
    }

    return this._api.getObservers().pipe(
      map((observers: Digitiser[]) =>
        digitiserIds.map((id) => {
          const digitiser = observers.find((observer) => String(observer.id_role) === String(id));
          if (!digitiser) {
            throw new Error(`Could not restore digitiser with id_role ${id}`);
          }
          return digitiser;
        })
      )
    );
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
