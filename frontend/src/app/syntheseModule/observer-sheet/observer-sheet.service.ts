import { Injectable } from '@angular/core';
import { ConfigService } from '@geonature/services/config.service';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject } from '@librairies/rxjs';
import { Observer } from './observer';


@Injectable()
export class ObserverSheetService {
  observer: BehaviorSubject<Observer | null> = new BehaviorSubject<Observer | null>(null);

  constructor(
    private _http: HttpClient,
    private _config: ConfigService
  ) {
  }

  updateObserverByIdRole(id_role: number) {
    const observer = this.observer.getValue();
    if (observer && observer.id_role == id_role) {
      return;
    }

    this._getObserverInfo(id_role).subscribe((observer) => {
      this.observer.next(observer);
    });
  }

  private _getObserverInfo(id_role: number) {
    return this._http.get<any>(`${this._config.API_ENDPOINT}/users/role/${id_role}`);
  }
}
