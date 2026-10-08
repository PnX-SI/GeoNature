import { Component, EventEmitter, OnInit, Output } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { Observable } from 'rxjs';
import { map, startWith } from 'rxjs/operators';

import { DataFormService } from '@geonature_common/form/data-form.service';
import { ConfigService } from '@geonature/services/config.service';
import { MetadataService, MetadataFilterPill } from '../services/metadata.service';

/**
 * Advanced search form of the metadata catalog. The form itself is held by `MetadataService`,
 * so that its values survive this panel being closed.
 */
@Component({
  selector: 'pnx-metadata-filters',
  templateUrl: './metadata-filters.component.html',
  styleUrls: ['./metadata-filters.component.scss'],
})
export class MetadataFiltersComponent implements OnInit {
  /** The filters have been applied to the search (`MetadataService.setFilters`). */
  @Output() applied = new EventEmitter<void>();
  @Output() closed = new EventEmitter<void>();

  /* liste des organismes issues de l'API pour l'autocomplete. */
  public organisms: any[] = [];
  /* liste des personnes issues de l'API pour l'autocomplete. */
  public persons: any[] = [];
  public filteredOrganisms: Observable<any[]>;
  public filteredPersons: Observable<any[]>;

  public areaFilters: Array<any>;

  constructor(
    private _dfs: DataFormService,
    public metadataService: MetadataService,
    public config: ConfigService,
    private translate: TranslateService
  ) {}

  ngOnInit() {
    this._dfs.getOrganisms().subscribe((organisms) => (this.organisms = organisms));
    this._dfs.getObservers().subscribe((persons) => (this.persons = persons));
    this.filteredOrganisms = this.autocompleteOptions('organism', () => this.organisms, [
      'nom_organisme',
    ]);
    this.filteredPersons = this.autocompleteOptions('person', () => this.persons, ['nom_complet']);

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

  /**
   * Options of an autocomplete field: the items of `getItems()` matching what is typed in the
   * form control, regardless of case and accents. Once an option is selected, the control holds
   * the item itself.
   */
  private autocompleteOptions(
    controlName: string,
    getItems: () => any[],
    fields: string[]
  ): Observable<any[]> {
    const normalize = (text: string) => text.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();
    return this.metadataService.form.get(controlName).valueChanges.pipe(
      startWith(''),
      map((value) => {
        const typed = typeof value === 'string' ? normalize(value) : '';
        return getItems().filter((item) =>
          fields.some((field) => normalize(item[field] ?? '').includes(typed))
        );
      })
    );
  }

  displayOrganism = (organism: any): string => organism?.nom_organisme ?? '';

  displayPerson = (person: any): string => person?.nom_complet ?? '';

  displayMetaAreaFilters = () =>
    this.config.METADATA?.METADATA_AREA_FILTERS &&
    this.config.METADATA?.METADATA_AREA_FILTERS.length;

  searchFormIsSubmitable() {
    return !this.metadataService.form.invalid;
  }

  /** Apply the filters of the form: the quick search stays applied. */
  applyFilters() {
    if (!this.searchFormIsSubmitable()) {
      return;
    }
    const { selector, uuid, name, date, organism, person } = this.metadataService.form.value;
    const criteria: { [key: string]: any } = {};
    const pills: MetadataFilterPill[] = [];
    const addFilter = (key: string, label: string, apiValue: any, displayValue: string) => {
      criteria[key] = apiValue;
      pills.push({ key, label: `${this.translate.instant(label)} : ${displayValue}` });
    };
    const isValidDate = (value: any) => value instanceof Date && !isNaN(value.getTime());

    if (uuid?.trim()) {
      addFilter('uuid', 'MetaData.SearchFilterUuid', uuid.trim(), uuid.trim());
    }
    if (name?.trim()) {
      addFilter('name', 'MetaData.SearchFilterName', name.trim(), name.trim());
    }
    // period: each bound is optional, an invalid typed date is ignored
    const start = isValidDate(date?.start) ? date.start : null;
    const end = isValidDate(date?.end) ? date.end : null;
    if (start || end) {
      const toApi = (day: Date) => ({
        year: day.getFullYear(),
        month: day.getMonth() + 1,
        day: day.getDate(),
      });
      const toDisplay = (day: Date | null) =>
        day ? day.toLocaleDateString(this.translate.currentLang) : '…';
      const criteriaKeys = [];
      if (start) {
        criteria['date_min'] = toApi(start);
        criteriaKeys.push('date_min');
      }
      if (end) {
        criteria['date_max'] = toApi(end);
        criteriaKeys.push('date_max');
      }
      pills.push({
        key: 'date',
        label: `${this.translate.instant('MetaData.CreationDate')} : ${toDisplay(
          start
        )} – ${toDisplay(end)}`,
        criteriaKeys,
      });
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
    this.applied.emit();
  }

  private selectedAreas(): any[] {
    return Object.entries(this.metadataService.form.value)
      .filter(([key]) => key.startsWith('area_'))
      .flatMap(([_, areas]) => (areas as any[]) ?? []);
  }
}
