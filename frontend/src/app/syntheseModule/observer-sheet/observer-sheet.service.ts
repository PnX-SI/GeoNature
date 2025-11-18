import { Injectable } from '@angular/core';
import { BehaviorSubject } from '@librairies/rxjs';
import { ObservationsFiltersService as MapObservationsService } from '../sheets/observations/observations-filters.service';
import {
  ObserverStats,
  SyntheseDataService,
} from '@geonature_common/form/synthese-form/synthese-data.service';
import { Loadable } from '../sheets/loadable';
import { finalize } from 'rxjs/operators';

@Injectable()
export class ObserverSheetService extends Loadable {
  observer: BehaviorSubject<string | null> = new BehaviorSubject<string | null>(null);
  observerStats: BehaviorSubject<ObserverStats | null> = new BehaviorSubject<ObserverStats | null>(
    null
  );

  constructor(
    private _os: MapObservationsService,
    private _sds: SyntheseDataService
  ) {
    super();
    this.observer.pipe(finalize(() => this.stopLoading())).subscribe((observer: string | null) => {
      this.startLoading();
      if (!observer) {
        return;
      }
      this._os.filters.next({
        observers: observer,
      });
      this.fetchObserverStats();
    });
  }

  setObserver(name_raw: string) {
    this.observer.next(decodeURIComponent(name_raw));
  }

  fetchObserverStats() {
    this._sds
      .getSyntheseObserverSheetStats(this.observer.getValue())
      .subscribe((stats: ObserverStats) => {
        this._os.udpateFromSheetStats(stats);
        this.observerStats.next(stats);
      });
  }
}
