import { Component, Inject, Input } from '@angular/core';

import { NgbActiveModal } from '@librairies/@ng-bootstrap/ng-bootstrap';
import { TranslateService } from '@ngx-translate/core';

import { APP_CONFIG_TOKEN, AppConfig } from '@geonature_config/app.config';


@Component({
  selector: 'gn-synthese-modal-messages',
  templateUrl: 'modal-messages.component.html',
})
export class SyntheseModalMessagesComponent {
  public syntheseConfig = this.config.SYNTHESE;

  public blurredSensitiveObsMsgParams = {
    requestAccessUrl: '/\u0023/permissions/requests/add',
    blurringField: this.config.DATA_BLURRING.EXPORT_FIELD_BLURRING,
  };

  @Input() hasTooManyObs = false;
  @Input() hasBlurredSensitiveObs = false;

  constructor(
    @Inject(APP_CONFIG_TOKEN) private config,
    public activeModal: NgbActiveModal,
    public translateService: TranslateService
  ) {}
}
