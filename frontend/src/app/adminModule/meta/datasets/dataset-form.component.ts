import { Component, OnInit } from '@angular/core';
import { FormGroup, FormBuilder } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { AppConfig } from '@geonature_config/app.config';
import { FormArray } from '@angular/forms/src/model';
import { ActivatedRoute, Router } from '@angular/router';
import { CommonService } from '@geonature_common/service/common.service';
import { DataFormService } from '@geonature_common/form/data-form.service';

@Component({
  selector: 'pnx-datasets-form',
  templateUrl: './dataset-form.component.html',
  styleUrls: ['./dataset-form.scss']
})
export class DatasetFormComponent implements OnInit {
  public datasetForm: FormGroup;
  public acquisitionFrameworks: any;
  public organisms: Array<any>;
  public roles: Array<any>;
  public cor_dataset_actor: FormGroup;
  public cor_dataset_actor_array: FormArray;
  public id_dataset: number;
  public dataset: any;

  constructor(
    private _fb: FormBuilder,
    private _api: HttpClient,
    private _route: ActivatedRoute,
    private _router: Router,
    private _commonService: CommonService,
    private _dfs: DataFormService
  ) {}

  ngOnInit() {
    // get the id from the route
    this._route.params.subscribe(params => {
      this.id_dataset = params['id'];
      if (this.id_dataset) {
        this.getDataset(this.id_dataset);
      }
    });
    this.datasetForm = this._fb.group({
      id_acquisition_framework: null,
      dataset_name: null,
      dataset_shortname: null,
      dataset_desc: null,
      id_nomenclature_data_type: null,
      keywords: null,
      marine_domain: true,
      terrestrial_domain: false,
      id_nomenclature_dataset_objectif: null,

      //
      //TODO bouding-box
      id_nomenclature_collecting_method: null,
      id_nomenclature_data_origin: null,
      id_nomenclature_source_status: null,
      id_nomenclature_resource_type: null
    });

    this.cor_dataset_actor_array = this._fb.array([]);

    this._dfs.getAcquisitionFrameworks().subscribe(data => {
      this.acquisitionFrameworks = data;
    });
    this._dfs.getOrganisms().subscribe(data => {
      this.organisms = data;
    });
    this._dfs.getRoles().subscribe(data => {
      this.roles = data;
    });

    this.cor_dataset_actor_array.push(this.generateCorDatasetActorForm());
  }

  generateCorDatasetActorForm(): FormGroup {
    return this._fb.group({
      id_nomenclature_actor_role: null,
      organisms: [new Array()],
      roles: [new Array()]
    });
  }

  addFormArray(): void {
    this.cor_dataset_actor_array.push(this.generateCorDatasetActorForm());
  }
  deleteFormArray(i) {
    this.cor_dataset_actor_array.removeAt(i);
  }

  getDataset(id) {
    this._dfs.getDataset(id).subscribe(data => {
      this.dataset = data;
      this.datasetForm.patchValue(data);

      data.cor_dataset_actor.forEach((cor, index) => {
        const roles = data.cor_dataset_actor[index].role
          ? [data.cor_dataset_actor[index].role]
          : null;
        const organisms = data.cor_dataset_actor[index].organism
          ? [data.cor_dataset_actor[index].organism]
          : null;
        const formData = {
          id_nomenclature_actor_role: cor.id_nomenclature_actor_role,
          organisms: organisms,
          roles: roles
        };
        if (index === 0) {
          this.cor_dataset_actor_array.controls[index].patchValue(formData);
        } else {
          const formCor = this.generateCorDatasetActorForm();
          this.cor_dataset_actor_array.push(formCor);
          //hack pour attendre que le template soit rendu avant de mettre les valeurs au formulaire
          setTimeout(() => {
            this.cor_dataset_actor_array.controls[index].patchValue(formData);
          }, 2000);
        }
      });
    });
  }

  postDataset() {
    const cor_dataset_actor_array = JSON.parse(JSON.stringify(this.cor_dataset_actor_array.value));
    const update_cor_dataset_actor = [];
    cor_dataset_actor_array.forEach(element => {
      element.organisms.forEach(org => {
        const corOrg = {
          id_nomenclature_actor_role: element.id_nomenclature_actor_role,
          id_organism: org.id_organisme
        };
        update_cor_dataset_actor.push(corOrg);
        //TODO: la meme chose avec les observateur si c'est un multiselect
      });

      element.roles.forEach(role => {
        const corRole = {
          id_nomenclature_actor_role: element.id_nomenclature_actor_role,
          id_role: role.id_role
        };
        update_cor_dataset_actor.push(corRole);
      });
    });

    const dataset = this.datasetForm.value;

    dataset['cor_dataset_actor'] = update_cor_dataset_actor;
    this._api.post<any>(`${AppConfig.API_ENDPOINT}/meta/dataset`, dataset).subscribe(
      data => {
        this._router.navigate(['/admin/datasets']);
        this._commonService.translateToaster('success', 'Meta.Datasetadded');
      },
      error => {
        this._commonService.translateToaster('error', 'ErrorMessage');
      }
    );
  }
}
