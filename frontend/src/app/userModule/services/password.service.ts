import { Injectable } from '@angular/core';
import { ValidatorFn, AbstractControl, ValidationErrors } from '@angular/forms';
import { ConfigService } from '@geonature/services/config.service';
import { TranslateService } from '@ngx-translate/core';

@Injectable({
  providedIn: 'root',
})
export class PasswordService {
  public min_password_size: number;
  public case_required: boolean;
  public digit_required: boolean;
  public special_char_required: boolean;

  constructor(
    public config: ConfigService,
    private translate: TranslateService
  ) {
    const password_config = this.config.ACCOUNT_MANAGEMENT.PASSWORD_MANAGEMENT;
    this.min_password_size = password_config.MIN_PASSWORD_LENGTH;
    this.case_required = password_config.REQUIRE_MULTIPLE_CASE;
    this.digit_required = password_config.REQUIRE_DIGIT;
    this.special_char_required = password_config.REQUIRE_SPECIAL_CHARACTER;
  }

  passwordValidator(): ValidatorFn {
    return (control: AbstractControl): ValidationErrors | null => {
      const password = control.value;
      const errors: ValidationErrors = {};

      if (!this.check_password_length(password)) {
        errors.minlength = {
          requiredLength: this.min_password_size,
          actualLength: password?.length || 0,
          message: this.translate.instant('Authentication.Errors.Password.MinLength', {
            requiredLength: this.min_password_size,
            actualLength: password?.length || 0,
          }),
        };
      }

      if (!this.check_password_uppercase(password)) {
        errors.uppercase = {
          message: this.translate.instant('Authentication.Errors.Password.UpperCase'),
        };
      }

      if (!this.check_password_lowercase(password)) {
        errors.lowercase = {
          message: this.translate.instant('Authentication.Errors.Password.LowerCase'),
        };
      }

      if (!this.check_password_digit(password)) {
        errors.digit = {
          message: this.translate.instant('Authentication.Errors.Password.Digit'),
        };
      }

      if (!this.check_special_char(password)) {
        errors.special_char = {
          message: this.translate.instant('Authentication.Errors.Password.SpecialChar'),
        };
      }

      return Object.keys(errors).length > 0 ? errors : null;
    };
  }

  check_password_length(password: string): boolean {
    return password?.length >= this.min_password_size;
  }

  check_password_uppercase(password: string): boolean {
    if (!this.case_required) {
      return true;
    }
    return /[A-Z]/.test(password);
  }

  check_password_lowercase(password: string): boolean {
    if (!this.case_required) {
      return true;
    }
    return /[a-z]/.test(password);
  }

  check_password_digit(password: string): boolean {
    if (!this.digit_required) {
      return true;
    }
    return /\d/.test(password);
  }

  check_special_char(password: string): boolean {
    if (!this.special_char_required) {
      return true;
    }
    return /[!"#$%&'()*+,-./:;<=>?@[\\\]^_`{|}~]/.test(password);
  }
}
