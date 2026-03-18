import { CommonModule } from '@angular/common';
import { Component, EventEmitter, OnDestroy, OnInit, Output } from '@angular/core';
import { UntypedFormControl, ReactiveFormsModule } from '@angular/forms';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { NgSelectModule } from '@ng-select/ng-select';
import { Subject } from 'rxjs';
import { map, takeUntil } from 'rxjs/operators';

interface HomeContentListObsFilters {
  taxonomy_group2_inpn?: string[];
  taxonomy_group3_inpn?: string[];
}

interface HomeContentListObsFilterOption {
  value: string;
}

@Component({
  standalone: true,
  selector: 'pnx-home-content-list-obs-filters',
  templateUrl: './home-content-list-obs-filters.component.html',
  styleUrls: ['./home-content-list-obs-filters.component.scss'],
  imports: [CommonModule, ReactiveFormsModule, NgSelectModule],
})
export class HomeContentListObsFiltersComponent implements OnInit, OnDestroy {
  @Output() filtersChange = new EventEmitter<HomeContentListObsFilters>();

  readonly group2InpnControl = new UntypedFormControl(null);
  readonly group3InpnControl = new UntypedFormControl(null);
  group2InpnOptions: HomeContentListObsFilterOption[] = [];
  group3InpnOptions: HomeContentListObsFilterOption[] = [];

  private destroy$ = new Subject<void>();

  constructor(private readonly dataFormService: DataFormService) {}

  ngOnInit() {
    this.dataFormService
      .getRegneAndGroup2Inpn()
      .pipe(
        map((data) => {
          const allGroups = new Set<string>();

          Object.values(data ?? {}).forEach((groups: string[]) => {
            groups.forEach((group) => {
              if (group) {
                allGroups.add(group);
              }
            });
          });

          return Array.from(allGroups)
            .sort((a, b) => a.localeCompare(b))
            .map((value) => ({ value }));
        }),
        takeUntil(this.destroy$)
      )
      .subscribe((options) => {
        this.group2InpnOptions = options;
      });

    this.dataFormService
      .getGroup3Inpn()
      .pipe(
        map((data) =>
          (data ?? [])
            .filter((value): value is string => typeof value === 'string' && value.length > 0)
            .sort((a, b) => a.localeCompare(b))
            .map((value) => ({ value }))
        ),
        takeUntil(this.destroy$)
      )
      .subscribe((options) => {
        this.group3InpnOptions = options;
      });

    this.group2InpnControl.valueChanges.pipe(takeUntil(this.destroy$)).subscribe(() => {
      this._emitFilters();
    });

    this.group3InpnControl.valueChanges.pipe(takeUntil(this.destroy$)).subscribe(() => {
      this._emitFilters();
    });
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private _emitFilters() {
    const filters: HomeContentListObsFilters = {};

    if (typeof this.group2InpnControl.value === 'string' && this.group2InpnControl.value.length > 0) {
      filters.taxonomy_group2_inpn = [this.group2InpnControl.value];
    }

    if (typeof this.group3InpnControl.value === 'string' && this.group3InpnControl.value.length > 0) {
      filters.taxonomy_group3_inpn = [this.group3InpnControl.value];
    }

    this.filtersChange.emit(filters);
  }
}
