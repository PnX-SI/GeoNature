import {
  Component,
  EventEmitter,
  Input,
  OnDestroy,
  OnInit,
  Output,
  ViewEncapsulation,
} from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { NgbTypeaheadSelectItemEvent } from '@ng-bootstrap/ng-bootstrap';
import { Observable, of, Subject } from 'rxjs';
import {
  catchError,
  debounceTime,
  distinctUntilChanged,
  filter,
  map,
  switchMap,
  takeUntil,
  tap,
} from 'rxjs/operators';
import { DesignStyle } from '../items-select/items-select.component';
import { Taxon } from './taxonomy.component';

/** Filters of the taxon search */
export interface TaxonSearchFilters {
  regne: string | null;
  group2_inpn: string | null;
}

/** Function searching the taxa matching a term */
export type TaxonSearchFn = (term: string, filters: TaxonSearchFilters) => Observable<Taxon[]>;

/**
 * Presentational typeahead to search a taxon: it only knows the function to search taxa and the
 * regnes and groups to filter with. Use ``pnx-taxonomy`` to search taxa through the TaxHub API.
 *
 * Two designs are available (``designStyle``): ``material`` (the default, ``mat-autocomplete``)
 * and ``bootstrap`` (``ngbTypeahead``).
 */
@Component({
  selector: 'pnx-taxonomy-select',
  templateUrl: './taxonomy-select.component.html',
  styleUrls: ['./taxonomy-select.component.scss'],
  encapsulation: ViewEncapsulation.None,
})
export class TaxonomySelectComponent implements OnInit, OnDestroy {
  @Input() designStyle: DesignStyle = 'material';
  @Input() parentFormControl: UntypedFormControl;
  @Input() label: string;
  /** Search the taxa matching a term (and the regne and group filters) */
  @Input() searchFn: TaxonSearchFn = () => of([]);
  /** Number of characters typed before the search is launched */
  @Input() charNumber: number;
  /** Attribute of the taxon displayed in the input once selected */
  @Input() displayedLabel = 'nom_valide';
  @Input() displayAdvancedFilters = false;
  /** Groups by regne, ex: ``{ Animalia: ['Mammifères', ...] }`` */
  @Input() regnesAndGroup: { [regne: string]: Array<string> };
  @Output() onChange = new EventEmitter<NgbTypeaheadSelectItemEvent>();
  @Output() onDelete = new EventEmitter<Taxon>();

  regneControl = new UntypedFormControl(null);
  groupControl = new UntypedFormControl(null);
  /** Taxa matching the text typed by the user (``material`` design) */
  results$: Observable<Array<Taxon>>;
  noResult: boolean;
  isLoading = false;
  public isCollapseTaxonomy = true;
  private _destroy$ = new Subject<void>();

  get regnes(): Array<string> {
    return Object.keys(this.regnesAndGroup ?? {});
  }

  ngOnInit() {
    this.results$ = this.searchTaxon(
      this.parentFormControl.valueChanges.pipe(
        filter((value): value is string => typeof value === 'string')
      )
    );
    // Use "!= null" instead of "!== null" to also match undefined values.
    this.parentFormControl.valueChanges
      .pipe(
        filter((value) => value != null && value.length === 0),
        takeUntil(this._destroy$)
      )
      .subscribe(() => this.onDelete.emit());

    // put group to null if regne = null
    this.regneControl.valueChanges.pipe(takeUntil(this._destroy$)).subscribe((value) => {
      if (value === '' || value === null) {
        this.groupControl.patchValue(null);
      }
    });
  }

  ngOnDestroy() {
    this._destroy$.next();
    this._destroy$.complete();
  }

  get showLoading(): boolean {
    return this.isLoading && this.parentFormControl.value?.length >= 3;
  }

  /** The taxon picked in the list (``material`` design), as the event of the typeahead */
  optionSelected(item: Taxon) {
    this.taxonSelected({ item, preventDefault: () => {} } as NgbTypeaheadSelectItemEvent);
  }

  taxonSelected(e: NgbTypeaheadSelectItemEvent) {
    this.onChange.emit(e);
  }

  formatter = (taxon: any) => {
    //Remove HTML tags
    return taxon?.[this.displayedLabel]?.replace(/<[^>]*>/g, '') ?? '';
  };

  searchTaxon = (text$: Observable<string>) =>
    text$.pipe(
      distinctUntilChanged(),
      debounceTime(400),
      tap(() => (this.isLoading = true)),
      switchMap((search_name_) => {
        const search_name = search_name_.toString();
        if (search_name.length >= this.charNumber) {
          return this.searchFn(search_name, {
            regne: this.regneControl.value,
            group2_inpn: this.groupControl.value,
          }).pipe(catchError(() => of([] as Taxon[])));
        } else {
          this.isLoading = false;
          return of([] as Taxon[]);
        }
      }),
      map((response) => {
        this.noResult = response.length === 0;
        this.isLoading = false;
        return response;
      })
    );

  refreshAllInput() {
    this.parentFormControl.reset();
    this.regneControl.reset();
    this.groupControl.reset();
  }
}
