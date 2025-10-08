import { Injectable } from '@angular/core';
import { ConfigService } from '@geonature/services/config.service';
import { BehaviorSubject } from '@librairies/rxjs';
import { Observer } from './observer';
import { UserDataService } from '@geonature/userModule/services';
import { Observable } from '@librairies/rxjs-compat/Rx';


@Injectable()
export class ObserverSheetService {
  observer: BehaviorSubject<Observer | null> = new BehaviorSubject<Observer | null>(null);

  constructor(
    private _config: ConfigService,
    private _userDataService: UserDataService
  ) {}

  updateObserver(observer: Observer) {
    const currentObserver = this.observer.getValue();
    if (currentObserver && currentObserver.id_role == observer.id_role) {
      return;
    }

    this.observer.next(observer);
  }

  fetchObserver(id_role: number): Observable<Observer> {
    return this._userDataService.getRole(id_role)
  }
}
