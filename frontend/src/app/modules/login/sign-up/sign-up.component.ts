import { Component, OnInit } from '@angular/core';
import { UntypedFormGroup, UntypedFormBuilder, Validators } from '@angular/forms';
import { Router } from '@angular/router';

import { similarValidator } from '@geonature/services/validators/validators';
import { CommonService } from '@geonature_common/service/common.service';

import { AuthService } from '../../../components/auth/auth.service';
import { PasswordService } from '../../../userModule/services/password.service';
import { ConfigService } from '@geonature/services/config.service';
import { TranslateService } from '@librairies/@ngx-translate/core';
import { LoginExistsValidator } from '@geonature/userModule/services/login-exists.validator';
@Component({
  selector: 'pnx-signup',
  templateUrl: './sign-up.component.html',
  styleUrls: ['./sign-up.component.scss'],
})
export class SignUpComponent implements OnInit {
  form: UntypedFormGroup;
  dynamicFormGroup: UntypedFormGroup;
  public disableSubmit = false;
  public formControlBuilded = false;
  public FORM_CONFIG = null;
  public errorMsg = '';
  public passwordPopoverStyle: { [key: string]: string } = {};

  constructor(
    private fb: UntypedFormBuilder,
    private _authService: AuthService,
    private _router: Router,
    private _commonService: CommonService,
    public config: ConfigService,
    private translate: TranslateService,
    private passwordService: PasswordService,
    private loginExistsValidator: LoginExistsValidator
  ) {
    this.FORM_CONFIG = this.config.ACCOUNT_MANAGEMENT.ACCOUNT_FORM;
    if (!(this.config['ACCOUNT_MANAGEMENT']['ENABLE_SIGN_UP'] || false)) {
      this._router.navigate(['/login']);
    }
  }

  ngOnInit() {
    this.createForm();
  }

  createForm() {
    this.form = this.fb.group({
      nom_role: ['', Validators.required],
      prenom_role: ['', Validators.required],
      identifiant: ['', Validators.required, [this.loginExistsValidator]],
      email: [
        '',
        [Validators.pattern('^[+a-z0-9._-]+@[a-z0-9._-]{2,}.[a-z]{2,4}$'), Validators.required],
      ],
      password: ['', [this.passwordService.passwordValidator()]],
      password_confirmation: ['', [Validators.required]],
      remarques: ['', null],
      organisme: ['', null],
    });
    this.form.setValidators([similarValidator('password', 'password_confirmation')]);
    this.dynamicFormGroup = this.fb.group({});
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

  save() {
    if (this.form.valid) {
      this.errorMsg = ''; // raz de l'erreur
      this.disableSubmit = true;
      const finalForm = Object.assign({}, this.form.value);
      // concatenate two forms
      finalForm['champs_addi'] = {};
      if (this.config.ACCOUNT_MANAGEMENT.ACCOUNT_FORM.length > 0) {
        finalForm['champs_addi'] = this.dynamicFormGroup.value;
      }
      // ajout de organisme aux champs addi
      finalForm['champs_addi']['organisme'] = this.form.value['organisme'];
      this._authService
        .signupUser(finalForm)
        .subscribe(
          () => {
            const callbackMessage = this.config.ACCOUNT_MANAGEMENT.AUTO_ACCOUNT_CREATION
              ? 'MyAccount.Messages.AutoAccountEmailConfirmation'
              : 'MyAccount.Messages.AdminAccountEmailConfirmation';
            this._commonService.translateToaster('info', callbackMessage);
            this._router.navigate(['/login']);
          },
          (error) => {
            if (error.error.msg) {
              this.errorMsg = error.error.msg;
            } else if (error.status === 400) {
              // Ajouter une clé de traduction
              this.translate
                .get('Authentication.Errors.AccountCreationError')
                .subscribe((translation) => {
                  this.errorMsg = translation;
                });
            } else {
              this.translate
                .get('Authentication.Errors.UnexpectedError')
                .subscribe((translation) => {
                  this.errorMsg = translation;
                });
            }
          }
        )
        .add(() => {
          this.disableSubmit = false;
        });
    }
  }
}
