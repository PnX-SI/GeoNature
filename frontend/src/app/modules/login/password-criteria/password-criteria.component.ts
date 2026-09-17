import { Component, Input } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';

import { PasswordService } from '../../../userModule/services/password.service';

@Component({
  selector: 'gn-password-criteria',
  templateUrl: './password-criteria.component.html',
  styleUrls: ['./password-criteria.component.scss'],
})
export class PasswordCriteriaComponent {
  @Input() control: UntypedFormControl;

  constructor(
    private passwordService: PasswordService,
    private translate: TranslateService
  ) {}

  getPasswordCriteria(): { label: string; valid: boolean }[] {
    const password: string = this.control?.value || '';
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
}
