import { Injectable } from '@angular/core';
import { BehaviorSubject } from '@librairies/rxjs';
import { Observer } from './observer';
import { UserDataService } from '@geonature/userModule/services';
import { ObservationsFiltersService as MapObservationsService } from '../sheets/observations/observations-filters.service';
import { ObserverStats, SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { Loadable } from '../sheets/loadable';
import { finalize } from 'rxjs/operators';


@Injectable()
export class ObserverSheetService extends Loadable{
  observer: BehaviorSubject<Observer | null> = new BehaviorSubject<Observer | null>(null);
  observerStats: BehaviorSubject<ObserverStats | null> = new BehaviorSubject<ObserverStats | null>(
    null
  );

  constructor(
    private _userDataService: UserDataService,
    private _os: MapObservationsService,
    private _sds: SyntheseDataService
  ) {
    super();
  }


  fetchObserverByIdRole(id_role: number) {
    const observer = this.observer.getValue();
    if (observer && observer.id_role == id_role) {
      return;
    }

    this.startLoading();
    this._userDataService.getRole(id_role)
      .pipe(finalize(() => this.stopLoading()))
      .subscribe((observer) => {
        this.observer.next(observer);
        this._os.filters.next({
          id_role: observer.id_role,
          observers: observer.nom_complet,
        });
        this.fetchObserverStats(observer);
      });
  }


  fetchObserverStats(observer: Observer) {
    this._sds.getSyntheseObserverSheetStats(observer.id_role).subscribe((stats: ObserverStats) => {
      this._os.udpateFromSheetStats(stats);
      this.observerStats.next(stats);
    });
  }
}
