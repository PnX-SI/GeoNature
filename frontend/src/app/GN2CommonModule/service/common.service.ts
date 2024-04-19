import { Injectable } from '@angular/core';
import { ToastrService } from 'ngx-toastr';
import { TranslateService } from '@ngx-translate/core';

@Injectable()
export class CommonService {
  constructor(
    private toastrService: ToastrService,
    private translate: TranslateService
  ) {}

  /** pour ne pas afficher plusieurs fois le meme message
   * (par ex quand on ) zomme sur la carte avant la saisie */

  private current: any = {};

  translateToaster(messageType: string, messageValue: string, parameters: Object = {}): void {
    // si toaster contenant le message est en cours on ne fait rien
    if (this.current[messageValue]) {
      return;
    }

    this.current[messageValue] = true;

    this.translate
      .get(messageValue, parameters)
      .subscribe((res) => this.toastrService[messageType](res, ''));

    // on supprime le message de current au bout de 5s
    setTimeout(() => {
      delete this.current[messageValue];
    }, 5000);
  }

  regularToaster(messageType: string, messageValue: string): void {
    this.toastrService[messageType](messageValue, '');
  }

  /**Calculate the height of th main card
   *  @minusHeight: heigth to retire from the card
   */
  calcCardContentHeight(minusHeight?) {
    const windowHeight = window.innerHeight;
    const tbH = document.getElementById('app-toolbar')
      ? document.getElementById('app-toolbar').offsetHeight
      : 0;
    const height = windowHeight - tbH - (minusHeight || 0);
    return height >= 350 ? height : 350;
  }
}
