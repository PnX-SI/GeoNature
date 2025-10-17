import { Injectable } from '@angular/core';
import { ConfigService } from '@geonature/services/config.service';
import { SheetStats } from '@geonature_common/form/synthese-form/synthese-data.service';
import { BehaviorSubject } from 'rxjs';

export type Filters = Record<string, string | number | number[]>;

export interface YearInterval {
  min: number;
  max: number;
}

@Injectable()
export class ObservationsFiltersService {
  // Filter - can hold  filter by observer, taxon, etc.
  filters: BehaviorSubject<Filters> = new BehaviorSubject<Filters>({});

  // Filter - yearInterval management - reference, and user setup
  yearIntervalBoundaries: BehaviorSubject<YearInterval | null> =
    new BehaviorSubject<YearInterval | null>(null);

  //
  isSuperiorToSyntheseLimit: boolean = true;

  constructor(private _config: ConfigService) {}

  udpateFromSheetStats(stats: SheetStats) {
    this.yearIntervalBoundaries.next({
      min: new Date(stats.date_min).getFullYear(),
      max: new Date(stats.date_max).getFullYear(),
    });
    this.isSuperiorToSyntheseLimit =
      stats.observation_count > this._config['SYNTHESE']['NB_MAX_OBS_MAP'];
  }
}
