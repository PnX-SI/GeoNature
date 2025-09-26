import { Component, Inject, Input } from '@angular/core';

import { NgbActiveModal } from '@librairies/@ng-bootstrap/ng-bootstrap';
import { TranslateService } from '@ngx-translate/core';

import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'gn-synthese-modal-messages',
  templateUrl: 'modal-messages.component.html',
})
export class SyntheseModalMessagesComponent {
  public syntheseConfig = this.config.SYNTHESE;

  public limitMsgParams = {
    nbMaxObsMap: this.config.SYNTHESE.NB_MAX_OBS_MAP,
    nbMaxObsExport: this.config.SYNTHESE.NB_MAX_OBS_EXPORT,
  };

  @Input() hasTooManyObs = false;
  @Input() hasBlurredSensitiveObs = false;

  constructor(
    public config: ConfigService,
    public activeModal: NgbActiveModal,
    public translateService: TranslateService
  ) {}
}
