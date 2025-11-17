import { Component, OnInit } from '@angular/core';
import { Router, ActivatedRoute } from '@angular/router';
import { UntypedFormGroup, UntypedFormBuilder, Validators } from '@angular/forms';

import { ToastrService } from 'ngx-toastr';
import { similarValidator } from '@geonature/services/validators';

import { AuthService } from '../../../components/auth/auth.service';
import { ConfigService } from '@geonature/services/config.service';
import { CommonService } from '@geonature_common/service/common.service';
import { TranslateService } from '@ngx-translate/core';

@Component({
  selector: 'gn-confirm',
  templateUrl: 'confirm.component.html',
  styleUrls: ['confirm.component.scss'],
})
export class ConfirmAccountComponent implements OnInit {
  token: string;
  confirmationDivMessage: string;
  confirmationButtonLabel: string;
  background_url: string;
  isValidator: boolean = false;

  constructor(
    private _authService: AuthService,
    private router: Router,
    private activatedRoute: ActivatedRoute,
    public config: ConfigService,
    public commonService: CommonService,
    private _translationService: TranslateService
  ) {
    this.activatedRoute.queryParams.subscribe((params) => {
      this.token = params['token'];
      if (!RegExp('^[0-9]+$').test(this.token)) {
        this.router.navigate(['/login']);
      }
      this.isValidator = params['asValidator'];
    });
  }

  ngOnInit() {
    this.background_url = `${this.config.API_ENDPOINT}${this.config.STATIC_URL}/images/login_background.jpg`;
    let labelKey = 'Authentication.Actions.ActivateAccount';
    let messageKey = 'Authentication.Messages.ActivateAccountConfirmation';
    if (this.isValidator) {
      labelKey = 'Authentication.Actions.ActivateAccountValidator';
      messageKey = 'Authentication.Messages.ActivateAccountConfirmationValidator';
    }
    this._translationService.get(messageKey).subscribe((res) => {
      this.confirmationDivMessage = res;
    });

    this._translationService.get(labelKey).subscribe((res) => {
      this.confirmationButtonLabel = res;
    });
  }

  submit() {
    this._authService.confirmToken({ token: this.token }).subscribe(
      (res) => {
        this.commonService.regularToaster('success', 'Votre compte a bien été activé !');
      },
      (error) => {
        this.commonService.regularToaster('error', error.error.msg);
      }
    );
    this.router.navigate(['/login']);
  }
}
