import { Injectable } from '@angular/core';
import { Resolve, ActivatedRouteSnapshot, RouterStateSnapshot, Router } from '@angular/router';
import { Observable, of } from 'rxjs';

import { CommonService } from '@geonature_common/service/common.service';

import { StationFeature } from '../models';
import { OccHabDataService } from '../services/data.service';

@Injectable({ providedIn: 'root' })
export class StationResolver implements Resolve<StationFeature> {
  constructor(
    private service: OccHabDataService,
    private commonService: CommonService,
    private router: Router
  ) {}

  resolve(route: ActivatedRouteSnapshot, state: RouterStateSnapshot): Observable<StationFeature> {
    return this.service.getStation(+route.paramMap.get('id_station')).catch((error) => {
      if (error.status == 404) {
        this.commonService.translateToaster('warning', 'Station introuvable');
      }
      this.router.navigate(['/occhab']);
      return of(null);
    });
  }
}
