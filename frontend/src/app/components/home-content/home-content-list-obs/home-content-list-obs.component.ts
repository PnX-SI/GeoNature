import { Component, OnDestroy, OnInit } from '@angular/core';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { Subject } from 'rxjs';
import { map, takeUntil } from 'rxjs/operators';
import { HomeContentListObsFiltersComponent } from './home-content-list-obs-filters/home-content-list-obs-filters.component';
import { HomeContentListObsListComponent } from './home-content-list-obs-list/home-content-list-obs-list.component';

interface HomeContentListObservationItem {
  id_synthese: number;
  nom_vern_or_lb_nom: string;
  date_min: string | null;
  observers: string | null;
}

interface HomeContentListObsFilters {
  taxonomy_group2_inpn?: string[];
  taxonomy_group3_inpn?: string[];
}

@Component({
  standalone: true,
  selector: 'pnx-home-content-list-obs',
  templateUrl: './home-content-list-obs.component.html',
  styleUrls: ['./home-content-list-obs.component.scss'],
  imports: [HomeContentListObsFiltersComponent, HomeContentListObsListComponent],
})
export class HomeContentListObsComponent implements OnInit, OnDestroy {
  observations: HomeContentListObservationItem[] = [];
  isLoading = false;
  filters: HomeContentListObsFilters = {};

  private destroy$ = new Subject<void>();

  constructor(private _syntheseDataService: SyntheseDataService) {}

  ngOnInit() {
    this._fetchObservations();
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }

  onFiltersChange(filters: HomeContentListObsFilters) {
    this.filters = filters;
    this._fetchObservations();
  }

  private _fetchObservations() {
    this.isLoading = true;
    this._syntheseDataService
      .getSyntheseData(this.filters, { limit: 100, format: 'ungrouped_geom' })
      .pipe(
        map((data) =>
          (data?.features ?? [])
            .map((feature) => feature.properties)
            .sort((a, b) => {
              const aTime = a.date_min ? new Date(a.date_min).getTime() : 0;
              const bTime = b.date_min ? new Date(b.date_min).getTime() : 0;
              return bTime - aTime;
            })
        ),
        takeUntil(this.destroy$)
      )
      .subscribe({
        next: (observations: HomeContentListObservationItem[]) => {
          this.observations = observations;
          this.isLoading = false;
        },
        error: () => {
          this.isLoading = false;
        },
      });
  }
}
