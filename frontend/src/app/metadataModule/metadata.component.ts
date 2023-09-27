import { Component, OnInit, ViewChild } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { PageEvent, MatPaginator } from '@angular/material/paginator';
import { CruvedStoreService } from '../GN2CommonModule/service/cruved-store.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { Observable, combineLatest } from 'rxjs';
import { map, distinctUntilChanged, debounceTime } from 'rxjs/operators';
import { omitBy } from 'lodash';

import { DataFormService, ParamsDict } from '@geonature_common/form/data-form.service';
import { CommonService } from '@geonature_common/service/common.service';
import { MetadataService } from './services/metadata.service';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'pnx-metadata',
  templateUrl: './metadata.component.html',
  styleUrls: ['./metadata.component.scss'],
})
export class MetadataComponent implements OnInit {
  @ViewChild(MatPaginator, { static: false }) paginator: MatPaginator;

  /* getter this.metadataService.filteredAcquisitionFrameworks */
  acquisitionFrameworks: Observable<any[]>;
  public rapidSearchControl: UntypedFormControl = new UntypedFormControl();

  get expandAccordions(): boolean {
    return this.metadataService.expandAccordions;
  }

  /* liste des organismes issues de l'API pour le select. */
  public organisms: any[] = [];
  /* liste des roles issues de l'API pour le select. */
  public roles: any[] = [];
  public meta_type: any[] = [
    { label: 'Jeu de données', value: 'ds' },
    { label: "Cadre d'acquisition", value: 'af' },
  ];

  public areaFilters: Array<any>;

  get isLoading(): boolean {
    return this.metadataService.isLoading;
  }

  searchTerms: any = {};
  afPublishModalId: number;
  afPublishModalLabel: string;
  afPublishModalContent: string;

  acquisitionFrameworksLength: number = 0;

  constructor(
    public _cruvedStore: CruvedStoreService,
    private _dfs: DataFormService,
    private modal: NgbModal,
    public metadataService: MetadataService,
    private _commonService: CommonService,
    public config: ConfigService
  ) {}

  ngOnInit() {
    this._dfs.getOrganisms().subscribe((organisms) => (this.organisms = organisms));

    this._dfs.getRoles({ group: false }).subscribe((roles) => (this.roles = roles));

    this.afPublishModalLabel = this.config.METADATA.CLOSED_MODAL_LABEL;
    this.afPublishModalContent = this.config.METADATA.CLOSED_MODAL_CONTENT;

    //Combinaison des observables pour afficher les éléments filtrés en fonction de l'état du paginator
    this.acquisitionFrameworks = combineLatest(
      this.metadataService.acquisitionFrameworks.pipe(distinctUntilChanged()),
      this.metadataService.pageIndex.asObservable().pipe(distinctUntilChanged()),
      this.metadataService.pageSize.asObservable().pipe(distinctUntilChanged())
    ).pipe(
      map(([afs, pageIndex, pageSize]) => {
        this.acquisitionFrameworksLength = afs.length;
        return afs.slice(pageIndex * pageSize, (pageIndex + 1) * pageSize);
      })
    );

    // rapid search event
    //combinaison de la zone de recherche et du chargement des données
    this.rapidSearchControl.valueChanges
      .pipe(debounceTime(1000), distinctUntilChanged())
      .subscribe((term) => {
        if (term !== null) {
          if (term === '') {
            delete this.searchTerms.search;
          } else {
            this.searchTerms = { ...this.searchTerms, search: this.rapidSearchControl.value };
          }
          this.metadataService.search(this.searchTerms);
          this.metadataService.pageIndex.next(0);
        }
      });

    // format areas filter
    this.areaFilters = this.config.METADATA.METADATA_AREA_FILTERS.map((area) => {
      if (typeof area['type_code'] === 'string') {
        area['type_code_array'] = [area['type_code']];
      } else {
        area['type_code_array'] = area['type_code'];
      }
      return area;
    });
  }

  getOptionText(option) {
    return option?.area_name;
  }

  refreshFilters() {
    this.metadataService.resetForm();
    this.advancedSearch();
    this.metadataService.expandAccordions = false;
  }

  private advancedSearch() {
    let formValues = Object.fromEntries(
      Object.entries(this.metadataService.form.value).filter(([_, v]) => v != null)
    );
    // reformat areas value
    let areas = [];
    let omited = omitBy(formValues, (value = [], field) => {
      // omit control names started by area_
      if (!field || !field.startsWith('area_')) return false;
      // use only one areas ids list
      if (value) {
        areas = [...areas, ...value.map((area) => area.id_area)];
      }
      return true;
    });
    this.searchTerms = {
      ...omited,
      ...(areas.length && { areas: areas }),
      ...(this.rapidSearchControl.value !== null && {
        search: this.rapidSearchControl.value,
      }),
    };
    this.metadataService.form.patchValue(this.searchTerms);
    this.metadataService.formatFormValue(Object.assign({}, formValues));
    this.metadataService.getMetadata(this.searchTerms);
  }

  openSearchModal(searchModal) {
    this.modal.open(searchModal);
  }

  closeSearchModal() {
    this.modal.dismissAll();
  }

  onOpenExpansionPanel(af: any) {
    if (af.t_datasets === undefined) {
      let params = {};
      const queryStrings: ParamsDict = { synthese_records_count: 1 };
      if (this.searchTerms.selector === 'ds') {
        params = this.searchTerms;
      }
      if (this.rapidSearchControl.value) {
        params = { ...params, search: this.rapidSearchControl.value };
      }
      this.metadataService.addDatasetToAcquisitionFramework(af, params, queryStrings);
    }
  }

  changePaginator(event: PageEvent) {
    this.metadataService.pageSize.next(event.pageSize);
    this.metadataService.pageIndex.next(event.pageIndex);
  }

  deleteAf(af_id) {
    this._dfs.deleteAf(af_id).subscribe((res) => this.metadataService.getMetadata());
  }

  openPublishModalAf(e, af_id, publishModal) {
    this.afPublishModalId = af_id;
    this.modal.open(publishModal, { size: 'lg' });
  }

  publishAf() {
    this._dfs.publishAf(this.afPublishModalId).subscribe(
      (res) => this.metadataService.getMetadata(),
      (error) => {
        if (error.error.name == 'mailError') {
          this._commonService.regularToaster(
            'warning',
            "Erreur lors de l'envoi de l'email de confirmation. Le cadre d'acquisition a bien été fermé"
          );
        }
      }
    );

    this.modal.dismissAll();
  }

  displayMetaAreaFilters = () =>
    this.config.METADATA?.METADATA_AREA_FILTERS &&
    this.config.METADATA?.METADATA_AREA_FILTERS.length;
}
