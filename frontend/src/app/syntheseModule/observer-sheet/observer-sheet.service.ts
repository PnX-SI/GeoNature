import { Injectable } from '@angular/core';
import { BehaviorSubject } from '@librairies/rxjs';
import { ObservationsFiltersService } from '../sheets/observations/observations-filters.service';
import {
  ObserverStats,
  SyntheseDataService,
} from '@geonature_common/form/synthese-form/synthese-data.service';
import { Loadable } from '../sheets/loadable';
import { finalize } from 'rxjs/operators';
import { Observer } from './observer';

@Injectable()
export class ObserverSheetService extends Loadable {
  observer: BehaviorSubject<Observer> = new BehaviorSubject<Observer>(null);
  observerStats: BehaviorSubject<ObserverStats> = new BehaviorSubject<ObserverStats>(null);

  constructor(
    private _os: ObservationsFiltersService,
    private _sds: SyntheseDataService
  ) {
    super();
    this.observer.pipe(finalize(() => this.stopLoading())).subscribe((observer: Observer) => {
      this.startLoading();
      this._os.reset();
      this.observerStats.next(null);
      if (!observer) {
        return;
      }
      // trigger observation tab content update
      this._os.filters.next({
        observers: observer.nom_complet,
      });

      this.fetchObserverStats();
    });
  }

  setObserver(observer: Observer) {
    this.observer.next(observer);
  }

  fetchObserverStats() {
    this._sds
      .getSyntheseObserverSheetStats(this.observer.getValue())
      .subscribe((stats: ObserverStats) => {
        this._os.updateFromSheetStats(stats);
        this.observerStats.next(stats);
      });
  }
}
