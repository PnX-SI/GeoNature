import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { Location } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';

import * as cloneDeep from 'lodash/cloneDeep';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { ToastrService } from 'ngx-toastr';
import { ConfigService } from '@geonature/services/config.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';

import { EventToggle } from './synthese-results/synthese-carte/synthese-carte.component';
import { SyntheseInfoObsComponent } from '../shared/syntheseSharedModule/synthese-info-obs/synthese-info-obs.component';
import { SyntheseStoreService } from './services/store.service';
import { SyntheseModalDownloadComponent } from './synthese-results/synthese-list/modal-download/modal-download.component';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { SyntheseQueryParamsService } from './synthese-queryparams.service';

@Component({
  selector: 'pnx-synthese',
  styleUrls: ['synthese.component.scss'],
  templateUrl: 'synthese.component.html',
  providers: [MapListService, SyntheseQueryParamsService],
})
export class SyntheseComponent implements OnInit {
  private idsByFeature: Set<number>;
  public firstLoad = true;
  private noGeomMessage: boolean;

  // Handling of cd_ref from query_params requires an extra processing step.
  // Those are not directly control values.
  private _cdRefFromQueryParams: Array<number> = [];

  public isSearchBarReduced = false;

  constructor(
    public config: ConfigService,
    public searchService: SyntheseDataService,
    public mapListService: MapListService,
    private modalService: NgbModal,
    private formService: SyntheseFormService,
    private syntheseStore: SyntheseStoreService,
    private toasterService: ToastrService,
    private route: ActivatedRoute,
    private ngModal: NgbModal,
    private changeDetector: ChangeDetectorRef,
    private router: Router,
    private location: Location,
    private queryParamsService: SyntheseQueryParamsService
  ) {}

  ngOnInit() {
    this.formService.selectors = this.formService.selectors
      .set('limit', this.config.SYNTHESE.NB_LAST_OBS)
      .set(
        'format',
        this.config.SYNTHESE.AREA_AGGREGATION_ENABLED &&
          this.config.SYNTHESE.AREA_AGGREGATION_BY_DEFAULT
          ? 'grouped_geom_by_areas'
          : 'grouped_geom'
      );

    this.route.queryParamMap.subscribe((params) => {
      this._cdRefFromQueryParams = this.queryParamsService.getCdRefsFromQueryParams(params);

      const idSynthese = this.route.snapshot.paramMap.get('id_synthese');
      if (idSynthese) {
        this.formService.searchForm.patchValue({ id_synthese: params.get('idSynthese') });
        this.openInfoModal(idSynthese);
      }

      this.initializeForm();
      this.applyDefaultFormValues(params);
    });
  }

  private initializeForm() {
    this.formService.selectedCdRefFromTree = [];
    this.formService.selectedTaxonFromRankInput = [];
    this.formService.selectedtaxonFromComponent = [];
    this.formService.selectedRedLists = [];
    this.formService.selectedStatus = [];
    this.formService.selectedTaxRefAttributs = [];
  }

  private applyDefaultFormValues(params) {
    this.formService
      .processDefaultFilters(this.config.SYNTHESE.DEFAULT_FILTERS)
      .subscribe((processedDefaultFilters) => {
        const processedQueryParamsFilters = this.queryParamsService.processQueryParamsFilters(params);
        const processedFilters = {
          ...processedDefaultFilters,
          ...processedQueryParamsFilters,
        };
        this.formService.searchForm.reset(processedFilters);
        this.formService.processedFilters = processedFilters;

        // Build the URL from the merged form state after all query params are applied.
        // The url must be updated after cd_ref hydration so the URL represents the actual form state.
        const finalize = () => {
          const newQueryParams = this.queryParamsService.buildQueryParams(
            this.formService.formatParams()
          );
          if (Object.keys(newQueryParams).length) {
            const urlTree = this.router.createUrlTree([], {
              relativeTo: this.route,
              queryParams: newQueryParams,
            });
            this.location.go(this.router.serializeUrl(urlTree));
          }
          this.changeDetector.detectChanges();
          this.loadData();
        };

        // Hydrate taxon selections from cd_ref query params before finalizing the URL.
        const { cdRefs, taxons$ } = this.queryParamsService.getTaxonsFromQueryParams(params);
        if (cdRefs.length) {
          taxons$.subscribe((taxons) => {
            this._cdRefFromQueryParams = cdRefs;
            this.formService.selectedtaxonFromComponent = taxons;
            finalize();
          });
        } else {
          this._cdRefFromQueryParams = [];
          finalize();
        }
      });
  }

  loadData() {
    let formParams = this.formService.formatParams();
    if (this._cdRefFromQueryParams.length && !formParams['cd_ref']) {
      formParams = { ...formParams, cd_ref: this._cdRefFromQueryParams };
    }
    this.searchService.dataLoaded = false;
    this.formService.searchForm.markAsPristine();

    this.searchService.getSyntheseData(formParams, this.formService.selectors).subscribe(
      (data) => {
        this.parseGeoJson(data);
        this.displayMessageLimitNumberObservationsReached(formParams);
        this.searchService.dataLoaded = true;
      },
      () => {
        this.searchService.dataLoaded = true;
      }
    );

    this.displayMessageLastObsLimit();
  }

  onResetFilters() {
    this._cdRefFromQueryParams = [];
    this.router.navigate([], {
      relativeTo: this.route,
      queryParams: {},
      replaceUrl: true,
    });
  }

  private parseGeoJson(rawGeojson) {
    this.initializeStores(rawGeojson);

    let geojson = cloneDeep(rawGeojson);
    geojson.features.forEach((feature) => {
      this.idsByFeature = new Set();
      this.checkGeomAbsence(feature);

      feature.properties.observations.forEach((obs) => {
        this.extractIds(obs);
        this.addObservationToDataTable(cloneDeep(obs));
      });

      // WARNING: needs to return the updated object here !
      feature.properties.observations = this.buildObservationsProperty();
    });

    this.displayMessageGeomAbsence();
    this.orderDataTableByDates();
    this.mapListService.geojsonData = geojson;
  }

  private initializeStores(rawGeojson) {
    this.syntheseStore.clearData();
    this.syntheseStore.setData(this.getCurrentStoreType(), rawGeojson);
    this.mapListService.idName = 'id_synthese';
    this.mapListService.tableData = [];
    this.noGeomMessage = false;
  }

  private getCurrentStoreType() {
    return this.formService.selectors.get('format') == 'grouped_geom_by_areas' ? 'grid' : 'point';
  }

  private extractIds(observation) {
    if (observation['id_synthese']) {
      const id = observation['id_synthese'];
      if (this.syntheseStore.idSyntheseList.has(id) === false) {
        this.syntheseStore.idSyntheseList.add(id);
      }

      if (this.idsByFeature.has(id) === false) {
        this.idsByFeature.add(id);
      }
    }
  }

  private addObservationToDataTable(observation) {
    if (observation['id_synthese']) {
      if (this.mapListService.tableData.includes(observation.id_synthese) === false) {
        this.mapListService.tableData.push(observation);
      }
    }
  }

  private checkGeomAbsence(feature) {
    if (!feature.geometry) {
      this.noGeomMessage = true;
    }
  }

  private buildObservationsProperty() {
    return { id_synthese: Array.from(this.idsByFeature) };
  }

  private displayMessageLimitNumberObservationsReached(formParams) {
    if (this.syntheseStore.idSyntheseList.size >= this.config.SYNTHESE.NB_MAX_OBS_MAP) {
      const modalRef = this.modalService.open(SyntheseModalDownloadComponent, {
        size: 'lg',
      });
      modalRef.componentInstance.queryString = this.searchService.buildQueryUrl(formParams);
      modalRef.componentInstance.tooManyObs = true;
    }
  }

  private displayMessageGeomAbsence() {
    if (this.noGeomMessage) {
      this.toasterService.warning(
        "Certaine(s) observation(s) n'ont pas pu être affiché(es) sur la carte car leur maille d’aggrégation n'est pas disponible"
      );
    }
  }

  private displayMessageLastObsLimit() {
    if (this.firstLoad && this.formService.selectors.has('limit')) {
      let limit = this.formService.selectors.get('limit');
      this.toasterService.info(`Les ${limit} dernières observations de la synthèse`, '');
    }
    this.firstLoad = false;
  }

  private orderDataTableByDates() {
    this.mapListService.tableData = this.mapListService.tableData.sort((a, b) => {
      return (new Date(b.date_min).valueOf() as any) - new Date(a.date_min).valueOf();
    });
  }

  fetchOrRenderData(mapDisplayType: EventToggle) {
    // If the form has change reload data else load data from cache if already loaded
    if (this.formService.searchForm.dirty || this.syntheseStore.hasData(mapDisplayType) === false) {
      this.loadData();
    } else {
      let storedData = this.syntheseStore.getData(mapDisplayType);
      this.parseGeoJson(storedData);
    }
  }

  onSearchEvent(updatedParams?: Record<string, any>) {
    // Process params to update the location with query_params (location --> update url without actually loading a page)
    const formParams = updatedParams ?? this.formService.formatParams();
    const queryParams = this.queryParamsService.buildQueryParams(formParams);
    const urlTree = this.router.createUrlTree([], {
      relativeTo: this.route,
      queryParams,
    });
    this.location.go(this.router.serializeUrl(urlTree)); // Utilisation de location.go --> do not trigger the request, only modify url state
    this._cdRefFromQueryParams = Array.isArray(formParams['cd_ref']) ? formParams['cd_ref'] : [];

    // Remove limit
    this.formService.selectors = this.formService.selectors.delete('limit');
    // On search button click, clean cache and call loadAndStoreData
    this.syntheseStore.clearData();
    this.loadData();
  }

  openInfoModal(idSynthese) {
    const modalRef = this.ngModal.open(SyntheseInfoObsComponent, {
      size: 'lg',
      windowClass: 'large-modal',
    });
    modalRef.componentInstance.idSynthese = idSynthese;
    modalRef.componentInstance.header = true;
    modalRef.componentInstance.useFrom = 'synthese';

    let tabRoute = this.route.snapshot.paramMap.get('tab');
    if (tabRoute != null) {
      modalRef.componentInstance.selectedTab = tabRoute;
    }

    modalRef.result
      .then((result) => {})
      .catch((_) => {
        this.router.navigate([modalRef.componentInstance.useFrom]);
      });
  }
}
