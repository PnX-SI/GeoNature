import { Component, OnInit } from '@angular/core';
import { FormGroup, FormBuilder, Validators, FormControl } from '@angular/forms';
import { Router } from '@angular/router';
import { AppConfig } from '@geonature_config/app.config';
import { ToastrService } from 'ngx-toastr';
import { AuthService } from '../auth/auth.service';
import { similarValidator } from '@geonature/services/validators/validators';
import { CommonService } from '@geonature_common/service/common.service';

@Component({
  selector: 'pnx-signup',
  templateUrl: './sign-up.component.html',
  styleUrls: ['./sign-up.component.scss']
})
export class SignUpComponent implements OnInit {
  form: FormGroup;
  dynamicFormGroup: FormGroup;
  public formControlBuilded = false;
  public FORM_CONFIG = AppConfig.ACCOUNT_MANAGEMENT.ACCOUNT_FORM;
  //[
  // {
  //   type_widget: 'nomenclature',
  //   attribut_label: 'Type de regroupement',
  //   attribut_name: 'id_nomenclature_grp_typ',
  //   code_nomenclature_type: 'TYP_GRP',
  //   required: false
  // },
  // {
  //   type_widget: 'text',
  //   attribut_label: 'Preuve non numérique',
  //   attribut_name: 'non_digital_proof',
  //   required: false
  // },
  // {
  //   type_widget: 'text',
  //   attribut_label: 'test2',
  //   attribut_name: 'test2',
  //   required: false
  // },
  //   {
  //     type_widget: 'checkbox',
  //     attribut_label: "J'ai lu et je valide la charte",
  //     attribut_name: 'validate_charte',
  //     values: ['blue', 'red', 'machin'],
  //     required: true
  //   },
  //   {
  //     type_widget: 'radio',
  //     attribut_label: 'Test radio',
  //     attribut_name: 'test_radio',
  //     values: ['blue', 'red', 'green'],
  //     required: true
  //   },
  //   {
  //     type_widget: 'select',
  //     attribut_label: 'Test select',
  //     attribut_name: 'test_select',
  //     values: ['blue', 'red', 'green'],
  //     required: true
  //   },
  //   {
  //     type_widget: 'multiselect',
  //     attribut_label: 'Test multi',
  //     attribut_name: 'test_multselect',
  //     values: [{ key: 'la', value: 'truc' }, { key: 'la', value: 'machin' }],
  //     required: true
  //   }
  // ];

  constructor(
    private fb: FormBuilder,
    private _authService: AuthService,
    private _router: Router,
    private _toasterService: ToastrService,
    private _commonService: CommonService
  ) {
    if (!(AppConfig['ACCOUNT_MANAGEMENT']['ENABLE_SIGN_UP'] || false)) {
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
      identifiant: ['', Validators.required],
      email: [
        '',
        [Validators.pattern('^[a-z0-9._-]+@[a-z0-9._-]{2,}.[a-z]{2,4}$'), Validators.required]
      ],
      password: ['', Validators.required],
      password_confirmation: ['', [Validators.required, similarValidator('password')]],
      remarques: ['', null],
      organisme: ['', null]
    });
    this.dynamicFormGroup = this.fb.group({});
  }

  save() {
    if (this.form.valid) {
      console.log(this.dynamicFormGroup);

      // this._authService.signupUser(this.form.value).subscribe(
      //   res => {
      //     this._commonService.translateToaster('info', 'AccountEmailConfirmation');
      //   },
      //   // error callback
      //   error => {
      //     this._toasterService.error(error.error.msg, '', {
      //       positionClass: 'toast-top-center',
      //       tapToDismiss: true,
      //       timeOut: 5000
      //     });
      //   }
      // );
    }
  }
}
