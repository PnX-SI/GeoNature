import { Injectable } from '@angular/core';
import { CanActivate, Router, ActivatedRouteSnapshot } from '@angular/router';
import { CommonService } from '@geonature_common/service/common.service';
import { OccHabDataService } from '../services/data.service';

@Injectable()
export class IsAcquisitionFrameworkOpened implements CanActivate {
  constructor(
    private router: Router,
    private _commonService: CommonService,
    private _occHabDataService: OccHabDataService
  ) {}

  async canActivate(route: ActivatedRouteSnapshot) {
    const idStation: string = route.paramMap.get('id_station') as string;
    const isCanActivate = await this._occHabDataService.isAcquisitionFrameworkOpened(idStation).toPromise();
    if (!isCanActivate) {
      this.router.navigate(['/occhab/info', idStation]);
      this._commonService.regularToaster(
        'error',
        "La station d'ID " +
          idStation +
          " n'est pas modifiable car le CA correspondant est clôturé"
      );
    }
    return isCanActivate;
  }
}
