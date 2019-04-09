import { Injectable } from '@angular/core';
import { ToastrService } from 'ngx-toastr';
import { TranslateService } from '@ngx-translate/core';

@Injectable()
export class CommonService {

  constructor(private toastrService: ToastrService, private translate: TranslateService) {}

    translateToaster(messageType: string, messageValue: string): void {
      this.translate.get(messageValue, {value: messageValue})
      .subscribe(res =>
        this.toastrService[messageType](res, '')
      );
    }

    regularToaster(messageType: string, messageValue: string): void {
      this.toastrService[messageType](messageValue, '');
    }
}
