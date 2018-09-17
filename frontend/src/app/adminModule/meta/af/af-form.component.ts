import { Component, OnInit } from '@angular/core';
import { FormGroup, FormBuilder, FormArray, Validators } from '@angular/forms';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { MetadataFormService } from '../services/metadata-form.service';
import { CommonService } from '@geonature_common/service/common.service';
import { AppConfig } from '@geonature_config/app.config';
import { HttpClient } from '@angular/common/http';
import { ToastrService } from 'ngx-toastr';
import { Router, ActivatedRoute } from '@angular/router';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap/datepicker/ngb-date-parser-formatter';



@Component({
  selector: 'pnx-af-form',
  templateUrl: './af-form.component.html',
  providers: [MetadataFormService]
})
export class AfFormComponent implements OnInit {
  public afForm: FormGroup;
  public acquisitionFrameworks;
  public cor_af_actor: FormArray;
  public id_af: number;
  public af: any;

  constructor(
    private _fb: FormBuilder,
    private _dfs: DataFormService,
    private _formService: MetadataFormService,
    private _commonService: CommonService,
    private _route: ActivatedRoute,
    private _api: HttpClient,
    private _router: Router,
    private _toaster: ToastrService,
    private _dateParser: NgbDateParserFormatter,

  ) { }

  ngOnInit() {
    this._route.params.subscribe(params => {
      this.id_af = params['id'];
      if (this.id_af) {
        this.getAf(this.id_af);
      }
    });

    this._dfs.getAcquisitionFrameworks().subscribe(data => {
      this.acquisitionFrameworks = data;
    });
    this.afForm = this._fb.group({
      acquisition_framework_name: [null, Validators.required],
      acquisition_framework_desc: [null, Validators.required],
      id_nomenclature_territorial_level: [null, Validators.required],
      territory_desc: null,
      keywords: null,
      id_nomenclature_financing_type: [null, Validators.required],
      target_description: null,
      ecologic_or_geologic_target: null,
      acquisition_framework_parent_id: null,
      is_parent: false,
      acquisition_framework_start_date: [null, Validators.required],
      acquisition_framework_end_date: null,
      cor_objectifs: [new Array()],
      cor_volets_sinp: [new Array()]
    });


    this.cor_af_actor = this._fb.array([]);
    this.cor_af_actor.push(this._formService.generateCorDatasetActorForm());
  }

  getAf(id_af) {
    this._dfs.getAcquisitionFramework(id_af).subscribe(data => {
      this.af = data;
      this.afForm.patchValue(data);
      data.cor_af_actor.forEach((cor, index) => {
        const roles = data.cor_af_actor[index].role
          ? [data.cor_af_actor[index].role]
          : null;
        const organisms = data.cor_af_actor[index].organism
          ? [data.cor_af_actor[index].organism]
          : null;
        const formData = {
          id_nomenclature_actor_role: cor.id_nomenclature_actor_role,
          organisms: organisms,
          roles: roles
        };
        if (index === 0) {
          this.cor_af_actor.controls[index].patchValue(formData);
        } else {
          const formCor = this._formService.generateCorDatasetActorForm();
          this.cor_af_actor.push(formCor);
          //hack pour attendre que le template soit rendu avant de mettre les valeurs au formulaire
          setTimeout(() => {
            this.cor_af_actor.controls[index].patchValue(formData);
          }, 2000);
        }
      });
    });
  }

  postAf() {
    const cor_af_actor = JSON.parse(JSON.stringify(this.cor_af_actor.value));
    const af = Object.assign({}, this.afForm.value);

    const update_cor_af_actor = [];
    let formValid = true;
    cor_af_actor.forEach(element => {
      if (element.organism) {
        element.organisms.forEach(org => {
          const corOrg = {
            id_nomenclature_actor_role: element.id_nomenclature_actor_role,
            id_organism: org.id_organisme
          };
          update_cor_af_actor.push(corOrg);
        });
      }
      if (element.roles) {
        element.roles.forEach(role => {
          const corRole = {
            id_nomenclature_actor_role: element.id_nomenclature_actor_role,
            id_role: role.id_role
          };
          update_cor_af_actor.push(corRole);
        });
      }

      if (update_cor_af_actor.length === 0) {
        formValid = false;
        this._toaster.error('Veuillez spécifier un organisme ou une personne pour chaque acteur du JDD', '',
          { 'positionClass': 'toast-top-center' },
        );
      }
    });

    // format objectifs
    af.cor_objectifs.map(obj => obj.id_nomenclature);
    // format volets
    af.cor_volets_sinp.map(obj => obj.id_nomenclature);


    if (formValid) {

      af.acquisition_framework_start_date = this._dateParser.format(
        af.acquisition_framework_start_date
      );

      if (af.acquisition_framework_end_date) {
        af.acquisition_framework_end_date = this._dateParser.format(
          af.acquisition_framework_end_date
        );
      }


      af['cor_af_actor'] = update_cor_af_actor;
      this._api.post<any>(`${AppConfig.API_ENDPOINT}/meta/acquisition_framework`, af).subscribe(
        data => {
          this._router.navigate(['/admin/afs']);
          this._commonService.translateToaster('success', 'MetaData.AFadded');
        },
        error => {
          this._commonService.translateToaster('error', 'ErrorMessage');
        }
      );
    }

  }
}
