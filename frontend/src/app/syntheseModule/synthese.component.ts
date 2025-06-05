import { ChangeDetectorRef, Component, OnDestroy, OnInit } from '@angular/core';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';

import { ActivatedRoute, Router } from '@angular/router';
import { NotificationDataService } from '@geonature/components/notification/notification-data.service';
import { ConfigService } from '@geonature/services/config.service';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import * as cloneDeep from 'lodash/cloneDeep';
import { ToastrService } from 'ngx-toastr';
import { Subscription } from 'rxjs';
import { SyntheseInfoObsComponent } from '../shared/syntheseSharedModule/synthese-info-obs/synthese-info-obs.component';
import { SyntheseStoreService, SyntheseTask } from './services/store.service';
import { EventToggle } from './synthese-results/synthese-carte/synthese-carte.component';
import { SyntheseModalDownloadComponent } from './synthese-results/synthese-list/modal-download/modal-download.component';

@Component({
  selector: 'pnx-synthese',
  styleUrls: ['synthese.component.scss'],
  templateUrl: 'synthese.component.html',
  providers: [MapListService],
})
export class SyntheseComponent implements OnInit, OnDestroy {
  public searchBarHidden = false;
  public marginButton: number;
  public firstLoad = true;
  public isCollapseSyntheseNavBar = false;

  // Gestion des tâches asynchrones
  private pollingSubscription: Subscription;
  private pollingInterval = 30000; // 30 secondes
  private moduleCode = 'SYNTHESE'; // Code du module

  constructor(
    public searchService: SyntheseDataService,
    public _mapListService: MapListService,
    private _modalService: NgbModal,
    private _fs: SyntheseFormService,
    private _syntheseStore: SyntheseStoreService,
    private _toasterService: ToastrService,
    private _route: ActivatedRoute,
    private _ngModal: NgbModal,
    private _changeDetector: ChangeDetectorRef,
    public config: ConfigService,
    private _router: Router,
    private _dataFormService: DataFormService,
    private _notificationService: NotificationDataService
  ) {}

  ngOnInit() {
    // Initialiser le polling des tâches
    this.startTaskPolling();

    // Récupérer les tâches existantes pour le module
    this.loadExistingTasks();

    this._fs.selectors = this._fs.selectors
      .set('limit', this.config.SYNTHESE.NB_LAST_OBS)
      .set(
        'format',
        this.config.SYNTHESE.AREA_AGGREGATION_ENABLED &&
          this.config.SYNTHESE.AREA_AGGREGATION_BY_DEFAULT
          ? 'grouped_geom_by_areas'
          : 'grouped_geom'
      );
    this._route.queryParamMap.subscribe((params) => {
      if (params.get('id_dataset')) {
        this._fs.searchForm.patchValue({ id_dataset: params.get('id_dataset') });
      }
      if (params.get('id_acquisition_framework')) {
        this._fs.searchForm.patchValue({
          id_acquisition_framework: params.get('id_acquisition_framework'),
        });
      }
      const idSynthese = this._route.snapshot.paramMap.get('id_synthese');

      if (idSynthese) {
        this._fs.searchForm.patchValue({ id_synthese: params.get('idSynthese') });
        this.openInfoModal(idSynthese);
      }

      this._fs.selectedCdRefFromTree = [];
      this._fs.selectedTaxonFromRankInput = [];
      this._fs.selectedtaxonFromComponent = [];
      this._fs.selectedRedLists = [];
      this._fs.selectedStatus = [];
      this._fs.selectedTaxRefAttributs = [];

      // application des valeurs par defaut
      this._fs
        .processDefaultFilters(this.config.SYNTHESE.DEFAULT_FILTERS)
        .subscribe((processedDefaultFilters) => {
          if (params.get('id_import')) {
            processedDefaultFilters['id_import'] = params.get('id_import');
          }
          this._fs.searchForm.patchValue(this._fs.processedDefaultFilters);
          this._fs.processedDefaultFilters = processedDefaultFilters;
          this._changeDetector.detectChanges();

          this.loadAndStoreData(this._fs.formatParams());
        });
    });
  }

  /**
   * Charge les tâches existantes du module synthèse
   */
  loadExistingTasks() {
    this._dataFormService.getModuleTasks(this.moduleCode).subscribe((tasks) => {
      if (tasks && Array.isArray(tasks)) {
        // Calculer la date limite (24 heures avant maintenant)
        const oneDayAgo = new Date();
        oneDayAgo.setDate(oneDayAgo.getDate() - 1);

        // Filtrer pour ne garder que les tâches actives (pending) et récentes (moins de 24h)
        tasks
          .filter((task) => {
            // Garder uniquement les tâches en attente
            if (task.status !== 'pending') return false;

            // Vérifier si la tâche est récente (si start est disponible)
            if (task.start) {
              const taskDate = new Date(task.start);
              return taskDate > oneDayAgo;
            }

            return true; // Si pas de date, on garde par défaut
          })
          // Limiter à maximum 10 tâches pour éviter de surcharger l'interface
          .slice(0, 10)
          .forEach((task) => {
            this._syntheseStore.addTask({
              uuid: task.uuid_celery || task.uuid,
              status: task.status,
              result: task.result,
              downloadUrl: task.download_url,
            });
          });
      }
    });
  }

  /**
   * Démarre le polling des tâches actives
   */
  startTaskPolling() {
    if (this.pollingSubscription) {
      this.pollingSubscription.unsubscribe();
    }

    // Utiliser le mécanisme de rafraîchissement du store
    this.pollingSubscription = this._syntheseStore
      .startAutoRefresh(this.pollingInterval)
      .subscribe((updatedTasks) => {
        // Pour chaque tâche mise à jour, vérifier s'il faut notifier l'utilisateur
        updatedTasks.forEach((taskData) => {
          const isComplete = taskData.status === 'success' || taskData.status === 'error';
          if (isComplete) {
            this.notifyTaskCompletion(taskData);
          }
        });
      });
  }

  /**
   * Notifie l'utilisateur lorsqu'une tâche est terminée
   */
  notifyTaskCompletion(task: SyntheseTask) {
    if (task.status === 'success') {
      this._toasterService.success(
        `L'export a été complété avec succès${task.downloadUrl ? '. Le téléchargement va commencer.' : ''}`,
        'Tâche terminée'
      );

      // Si un lien de téléchargement est disponible, démarrer le téléchargement
      if (task.downloadUrl) {
        const link = document.createElement('a');
        link.href = task.downloadUrl;
        link.target = '_blank';
        link.click();
      }
    } else if (task.status === 'error') {
      this._toasterService.error(
        `L'export a échoué${task.result ? ': ' + task.result : ''}`,
        'Erreur'
      );
    }

    // Rafraîchir les notifications
    this._notificationService.getNotificationsNumber();
  }

  ngOnDestroy() {
    // Nettoyer la souscription de polling lorsque le composant est détruit
    if (this.pollingSubscription) {
      this.pollingSubscription.unsubscribe();
    }
  }

  loadAndStoreData(formParams) {
    this.searchService.dataLoaded = false;
    this._fs.searchForm.markAsPristine();

    this.searchService.getSyntheseData(formParams, this._fs.selectors).subscribe(
      (data) => {
        // mark the form pristine at each search in order to manage store data
        if (this._fs.selectors.get('format') == 'grouped_geom_by_areas') {
          this._syntheseStore.gridData = data;
        } else {
          this._syntheseStore.pointData = data;
        }
        // Store the list of id_synthese for exports
        this._syntheseStore.idSyntheseList = this.extractSyntheseIds(data);

        // Check if synthese observations limit is reach
        if (this._syntheseStore.idSyntheseList.length >= this.config.SYNTHESE.NB_MAX_OBS_MAP) {
          const modalRef = this._modalService.open(SyntheseModalDownloadComponent, {
            size: 'lg',
          });
          modalRef.componentInstance.queryString = this.searchService.buildQueryUrl(formParams);
          modalRef.componentInstance.tooManyObs = true;
        }

        // Store geojson
        // TODO: [IMPROVE][PAGINATE]
        this._mapListService.geojsonData = this.simplifyGeoJson(cloneDeep(data));
        this.formatDataForTable(data);

        this._mapListService.idName = 'id_synthese';
        this.searchService.dataLoaded = true;
      },
      () => {
        this.searchService.dataLoaded = true;
      }
    );

    if (this.firstLoad && this._fs.selectors.has('limit')) {
      //toaster
      let limit = this._fs.selectors.get('limit');
      this._toasterService.info(`Les ${limit} dernières observations de la synthèse`, '');
    }
    this.firstLoad = false;
  }

  /** table data expect an array obs observation
   * the geojson get from API is a list of features whith an observation list
   */
  // TODO: [IMPROVE][PAGINATE] data in datable is formated here
  formatDataForTable(geojson) {
    this._mapListService.tableData = [];
    const idSynthese = new Set();
    geojson.features.forEach((feature) => {
      feature.properties.observations.forEach((obs) => {
        if (!idSynthese.has(obs.id_synthese)) {
          this._mapListService.tableData.push(obs);
          idSynthese.add(obs.id_synthese);
        }
      });
    });

    // order by date
    this._mapListService.tableData = this._mapListService.tableData.sort((a, b) => {
      return (new Date(b.date_min).valueOf() as any) - new Date(a.date_min).valueOf();
    });
  }

  fetchOrRenderData(event: EventToggle) {
    // if the form has change reload data
    // else load data from cache if already loaded
    if (this._fs.searchForm.dirty) {
      this.loadAndStoreData(this._fs.formatParams());
    } else {
      if (event == 'point') {
        if (this._syntheseStore.pointData) {
          this._mapListService.geojsonData = this.simplifyGeoJson(
            cloneDeep(this._syntheseStore.pointData)
          );
          this.formatDataForTable(this._syntheseStore.pointData);
        } else {
          this.loadAndStoreData(this._fs.formatParams());
        }
      } else {
        if (this._syntheseStore.gridData) {
          this._mapListService.geojsonData = this.simplifyGeoJson(
            cloneDeep(this._syntheseStore.gridData)
          );
          this.formatDataForTable(this._syntheseStore.gridData);
        } else {
          this.loadAndStoreData(this._fs.formatParams());
        }
      }
    }
  }
  onSearchEvent() {
    // remove limit
    this._fs.selectors = this._fs.selectors.delete('limit');
    // on search button click, clean cache and call loadAndStoreData
    this._syntheseStore.gridData = null;
    this._syntheseStore.pointData = null;
    this.loadAndStoreData(this._fs.formatParams());
  }

  private extractSyntheseIds(geojson) {
    let ids = [];
    for (let feature of geojson.features) {
      feature.properties.observations.forEach((obs) => {
        ids.push(obs['id_synthese']);
      });
    }
    return ids;
  }

  private simplifyGeoJson(geojson) {
    let noGeomMessage = false;
    for (let feature of geojson.features) {
      if (!feature.geometry) {
        noGeomMessage = true;
      }

      let ids = [];
      for (let obs of Object.values(feature.properties.observations)) {
        if (obs['id_synthese']) {
          ids.push(obs['id_synthese']);
        }
      }
      feature.properties.observations = { id_synthese: ids };
    }
    if (noGeomMessage) {
      this._toasterService.warning(
        "Certaine(s) observation(s) n'ont pas pu être affiché(es) sur la carte car leur maille d’aggrégation n'est pas disponible"
      );
    }
    return geojson;
  }

  openInfoModal(idSynthese) {
    const modalRef = this._ngModal.open(SyntheseInfoObsComponent, {
      size: 'lg',
      windowClass: 'large-modal',
    });
    modalRef.componentInstance.idSynthese = idSynthese;
    modalRef.componentInstance.header = true;
    modalRef.componentInstance.useFrom = 'synthese';

    let tabRoute = this._route.snapshot.paramMap.get('tab');
    if (tabRoute != null) {
      modalRef.componentInstance.selectedTab = tabRoute;
    }

    modalRef.result
      .then((result) => {})
      .catch((_) => {
        this._router.navigate([modalRef.componentInstance.useFrom]);
      });
  }

  mooveButton() {
    this.searchBarHidden = !this.searchBarHidden;
  }

  closeInfo(infoAlert: HTMLElement) {
    infoAlert.hidden = true;
  }
}
