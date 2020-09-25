import { Injectable } from '@angular/core';
import { ToastrService } from 'ngx-toastr';
import { TranslateService } from '@ngx-translate/core';

@Injectable()
export class CommonService {

  constructor(private toastrService: ToastrService, private translate: TranslateService) { }

  translateToaster(messageType: string, messageValue: string): void {
    this.translate.get(messageValue, { value: messageValue })
      .subscribe(res =>
        this.toastrService[messageType](res, '')
      );
  }

  regularToaster(messageType: string, messageValue: string): void {
    this.toastrService[messageType](messageValue, '');
  }

  /**Calculate the height of th main card
   *  @minusHeight: heigth to retire from the card
   */
  calcCardContentHeight(minusHeight?) {
    const windowHeight = window.innerHeight;
    const tbH = document.getElementById("app-toolbar")
      ? document.getElementById("app-toolbar").offsetHeight
      : 0;
    const height = windowHeight - tbH - (minusHeight || 0);
    return height >= 350 ? height : 350;
  }
}
