import { Component, OnInit, ViewChild } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { PageEvent, MatPaginator } from '@angular/material/paginator';
import { CruvedStoreService } from '../GN2CommonModule/service/cruved-store.service';
import { NgbDateParserFormatter, NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { TranslateService } from '@ngx-translate/core';
import { Observable, combineLatest } from 'rxjs';
import { distinctUntilChanged, debounceTime, tap, switchMap, startWith } from 'rxjs/operators';
import { omitBy } from 'lodash';

import { DataFormService, ParamsDict } from '@geonature_common/form/data-form.service';
import { CommonService } from '@geonature_common/service/common.service';
import { MetadataService, MetadataFilterPill } from './services/metadata.service';
import { ConfigService } from '@geonature/services/config.service';
import { CdkPortal } from '@angular/cdk/portal';

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

  public filtersOpen: boolean = false;

  public areaFilters: Array<any>;

  get isLoading(): boolean {
    return this.metadataService.isLoading;
  }

  acquisitionFrameworksLength: number = 0;

  constructor(
    public _cruvedStore: CruvedStoreService,
    private _dfs: DataFormService,
    private modal: NgbModal,
    public metadataService: MetadataService,
    private _commonService: CommonService,
    public config: ConfigService,
    public dateParser: NgbDateParserFormatter,
    private translate: TranslateService
  ) {}

  ngOnInit() {
    //Combinaison des observables pour afficher les éléments filtrés en fonction de l'état du paginator
    this.acquisitionFrameworks = this.metadataService.acquisitionFrameworks.pipe(
      distinctUntilChanged(),
      tap((afs) => {
        this.acquisitionFrameworksLength = afs.length;
      })
    );

    // quick search event: the applied filters are kept
    this.rapidSearchControl.valueChanges
      .pipe(
        startWith(''),
        debounceTime(500),
        switchMap((term) => {
          this.metadataService.setQuickTerm(term);
          this.metadataService.changePage(0);
          this.paginator?.firstPage(); // required
          return this.metadataService.search();
        })
      )
      .subscribe(() => {
        return;
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

  toggleFilters() {
    this.filtersOpen = !this.filtersOpen;
  }

  refreshFilters() {
    this.rapidSearchControl.reset(null, { emitEvent: false });
    this.metadataService.clearSearch();
    this.runSearch();
  }

  /** Apply the filters of the form: the quick search stays applied. */
  applyFilters() {
    const { selector, uuid, name, date, organism, person } = this.metadataService.form.value;
    const criteria: { [key: string]: any } = {};
    const pills: MetadataFilterPill[] = [];
    const addFilter = (key: string, label: string, apiValue: any, displayValue: string) => {
      criteria[key] = apiValue;
      pills.push({ key, label: `${this.translate.instant(label)} : ${displayValue}` });
    };

    if (uuid?.trim()) {
      addFilter('uuid', 'MetaData.SearchFilterUuid', uuid.trim(), uuid.trim());
    }
    if (name?.trim()) {
      addFilter('name', 'MetaData.SearchFilterName', name.trim(), name.trim());
    }
    // an invalid typed date is ignored
    if (date && !isNaN(date.getTime())) {
      addFilter(
        'date',
        'MetaData.CreationDate',
        { year: date.getFullYear(), month: date.getMonth() + 1, day: date.getDate() },
        date.toLocaleDateString(this.translate.currentLang)
      );
    }
    // an autocomplete holds a string as long as no option is selected
    if (organism?.id_organisme) {
      addFilter(
        'organism',
        'MetaData.StakeholderOrganization',
        organism.id_organisme,
        organism.nom_organisme
      );
    }
    if (person?.id_role) {
      addFilter('person', 'MetaData.SearchFilterPerson', person.id_role, person.nom_complet);
    }
    const areas = this.selectedAreas();
    if (areas.length) {
      addFilter(
        'areas',
        'MetaData.SearchFilterAreas',
        areas.map((area) => area.id_area),
        areas.map((area) => area.area_name).join(', ')
      );
    }

    this.metadataService.setFilters(selector, criteria, pills);
    this.filtersOpen = false;
    this.runSearch();
  }

  removeFilter(pill: MetadataFilterPill) {
    this.metadataService.removeFilter(pill.key);
    this.runSearch();
  }

  private selectedAreas(): any[] {
    return Object.entries(this.metadataService.form.value)
      .filter(([key]) => key.startsWith('area_'))
      .flatMap(([_, areas]) => (areas as any[]) ?? []);
  }

  private runSearch() {
    this.paginator?.firstPage();
    this.metadataService.changePage(0);
    this.metadataService.search().subscribe();
  }

  onOpenExpansionPanel(af: any) {
    if (af.t_datasets === undefined) {
      const queryStrings: ParamsDict = { nb_observations_synthese: 1 };
      this.metadataService.addDatasetToAcquisitionFramework(
        af,
        this.metadataService.datasetSearchParams(),
        queryStrings
      );
    }
  }
  deleteAf(af_id) {
    this._dfs.deleteAf(af_id).subscribe((res) => this.metadataService.getMetadata());
  }

  get totalItems(): number {
    return this.metadataService.totalItems.value;
  }

  get totalPages(): number {
    return this.metadataService.totalPages.value;
  }

  changePaginator(event: PageEvent) {
    this.metadataService.changePageEvent(event);
  }

  displayMetaAreaFilters = () =>
    this.config.METADATA?.METADATA_AREA_FILTERS &&
    this.config.METADATA?.METADATA_AREA_FILTERS.length;

  onAfMetadataDataRefresh() {
    this.metadataService.getMetadata();
  }

  isAfFilters() {
    return this.metadataService.form.controls['selector'].value !== 'ds';
  }

  searchFormIsSubmitable() {
    return !this.metadataService.form.invalid;
  }
}
