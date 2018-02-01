import { Injectable } from '@angular/core';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import {TranslateService} from '@ngx-translate/core';

@Injectable()
export class CommonService {
  toastrConfig: ToastrConfig;

  constructor(private toastrService: ToastrService,
    private translate: TranslateService) {
      this.toastrConfig = {
        positionClass: 'toast-top-center',
        tapToDismiss: true,
        timeOut: 3000
    };
    }

    translateToaster(messageType: string, messageValue: string): void {
      this.translate.get(messageValue, {value: messageValue})
      .subscribe(res =>
        this.toastrService[messageType](res, '', this.toastrConfig)
      );
    }

    regularToaster(messageType: string, messageValue: string): void {
      this.toastrService[messageType](messageValue, '', this.toastrConfig);
    }
}
