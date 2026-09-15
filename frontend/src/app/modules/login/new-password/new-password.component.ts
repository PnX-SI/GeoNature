import { Component, OnInit } from '@angular/core';
import { Router, ActivatedRoute } from '@angular/router';
import { UntypedFormGroup, UntypedFormBuilder, Validators } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';

import { similarValidator } from '@geonature/services/validators';

import { AuthService } from '../../../components/auth/auth.service';
import { PasswordService } from '../../../userModule/services/password.service';
import { ConfigService } from '@geonature/services/config.service';
import { CommonService } from '@geonature_common/service/common.service';

@Component({
  selector: 'pnx-new-password',
  templateUrl: 'new-password.component.html',
  styleUrls: ['./new-password.component.scss'],
})
export class NewPasswordComponent implements OnInit {
  token: string;
  form: UntypedFormGroup;
  password_recovery: boolean = false;
  login_recovery: boolean = false;
  passwordPopoverStyle: { [key: string]: string } = {};

  constructor(
    private _authService: AuthService,
    private fb: UntypedFormBuilder,
    private router: Router,
    private activatedRoute: ActivatedRoute,
    public config: ConfigService,
    private _commonService: CommonService,
    private passwordService: PasswordService,
    private translate: TranslateService
  ) {
    this.activatedRoute.queryParams.subscribe((params) => {
      let token = params['token'];
      if (!RegExp('^[0-9]+$').test(token)) {
        this.router.navigate(['/login']);
      }
      this.token = token;
    });
  }

  ngOnInit() {
    this.setForm();
  }

  setForm() {
    this.form = this.fb.group({
      password: ['', [this.passwordService.passwordValidator()]],
      password_confirmation: ['', [Validators.required]],
    });
    this.form.setValidators([similarValidator('password', 'password_confirmation')]);
  }

  getPasswordErrors(): string[] {
    const control = this.form.get('password');
    if (!control || !control.errors) {
      return [];
    }

    return Object.keys(control.errors).map((errorKey) => {
      const error = control.errors[errorKey];
      return error.message || 'Erreur inconnue';
    });
  }

  // The password-criteria popover floats to the left of the field, which overflows the
  // scrollable split-form panel (clipped by its `overflow-y: auto`). Positioning it with
  // `position: fixed` computed from the input's bounding rect escapes that clipping so it
  // stays visible above the brand panel instead of being hidden behind it.
  updatePasswordPopoverPosition(target: EventTarget): void {
    const inputRect = (target as HTMLElement).getBoundingClientRect();
    const popoverWidth = 230;
    const gap = 12;
    this.passwordPopoverStyle = {
      top: `${inputRect.top}px`,
      left: `${inputRect.left - popoverWidth - gap}px`,
    };
  }

  getPasswordCriteria(): { label: string; valid: boolean }[] {
    const password: string = this.form.get('password').value || '';
    const criteria = [
      {
        label: this.translate.instant('Authentication.Errors.Password.MinLength', {
          requiredLength: this.passwordService.min_password_size,
          actualLength: password.length,
        }),
        valid: this.passwordService.check_password_length(password),
      },
    ];
    if (this.passwordService.case_required) {
      criteria.push(
        {
          label: this.translate.instant('Authentication.Errors.Password.UpperCase'),
          valid: this.passwordService.check_password_uppercase(password),
        },
        {
          label: this.translate.instant('Authentication.Errors.Password.LowerCase'),
          valid: this.passwordService.check_password_lowercase(password),
        }
      );
    }
    if (this.passwordService.digit_required) {
      criteria.push({
        label: this.translate.instant('Authentication.Errors.Password.Digit'),
        valid: this.passwordService.check_password_digit(password),
      });
    }
    if (this.passwordService.special_char_required) {
      criteria.push({
        label: this.translate.instant('Authentication.Errors.Password.SpecialChar'),
        valid: this.passwordService.check_special_char(password),
      });
    }
    return criteria;
  }

  submit() {
    if (this.form.valid) {
      let data = this.form.value;
      data['token'] = this.token;
      this._authService.passwordChange(data).subscribe(
        (res) => {
          this._commonService.translateToaster(
            'success',
            'Authentication.Messages.PasswordChanged'
          );
          this.router.navigate(['/login']);
        },
        // error callback
        (error) => {
          this._commonService.regularToaster('error', error.error.msg);
        }
      );
    }
  }
}
