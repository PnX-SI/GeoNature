import { Injectable } from '@angular/core';
import { CanActivate, Router, ActivatedRouteSnapshot } from '@angular/router';
import { CommonService } from '@geonature_common/service/common.service';
import { OcctaxDataService } from '../services/occtax-data.service';

@Injectable()
export class IsAcquisitionFrameworkOpened implements CanActivate {
  constructor(
    private router: Router,
    private _commonService: CommonService,
    private _occtaxDataService: OcctaxDataService
  ) {}

  async canActivate(route: ActivatedRouteSnapshot) {
    const idReleve: string = route.paramMap.get('id') as string;
    const isCanActivate = await this._occtaxDataService
      .isAcquisitionFrameworkOpened(idReleve)
      .toPromise();
    if (!isCanActivate) {
      this.router.navigate(['/occtax/info', idReleve]);
      this._commonService.regularToaster(
        'error',
        "Le relevé d'ID " + idReleve + " n'est pas modifiable car le CA correspondant est clôturé"
      );
    }
    return isCanActivate;
  }
}
