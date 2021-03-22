import { Component, OnInit } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { ActivatedRoute, Router } from '@angular/router';
import { of, Observable, BehaviorSubject } from 'rxjs';
import { switchMap, tap, map } from 'rxjs/operators';

import { CommonService } from '@geonature_common/service/common.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { ModuleService } from '@geonature/services/module.service';
import { AppConfig } from '@geonature_config/app.config';
import { DatasetFormService } from '../services/dataset-form.service';
import { ActorFormService } from '../services/actor-form.service';
import { MetadataService } from '../services/metadata.service';
import { MetadataDataService } from '../services/metadata-data.service';

@Component({
  selector: 'pnx-datasets-form',
  templateUrl: './dataset-form.component.html',
  styleUrls: ['../form.component.scss'],
  providers: [DatasetFormService]
})
export class DatasetFormComponent implements OnInit {

  public form: FormGroup;
  public genericActorForm: FormGroup = this.actorFormS.createForm();
  //observable pour la liste déroulantes HTML des AF
  public acquisitionFrameworks: Observable<any>;

  constructor(
    private _route: ActivatedRoute,
    private _router: Router,
    private _commonService: CommonService,
    private _dfs: DataFormService,
    public datasetFormS: DatasetFormService,
    public moduleService: ModuleService,
    private actorFormS: ActorFormService,
    private metadataS: MetadataService,
    private metadataDataS: MetadataDataService
  ) {}

  ngOnInit() {
    // get the id from the route
    this._route.params
      .pipe(
        switchMap((params) => {
          return params['id'] ? this._dfs.getDataset(params['id']) : of(null);
        })
      )
      .subscribe(dataset => this.datasetFormS.dataset.next(dataset));

    this.form = this.datasetFormS.form;

    // get Modules
    if (!this.moduleService.modules) {
      this.moduleService.fetchModules();
    }

    //getAcquisitionFrameworksForSelect
    this.acquisitionFrameworks = this._dfs.getAcquisitionFrameworks();
  }

  genericActorFormSubmit(result) {
    if (result) {
      this.datasetFormS.addActor(this.genericActorForm.value);
      this.genericActorForm.reset();
    }
  }

  addMainContact(){
    this.datasetFormS.addActor({id_nomenclature_actor_role: this.actorFormS.getIDRoleTypeByCdNomenclature("1")})
  }

  postDataset() {
    if (!this.form.valid)
      return;

    let api: Observable<any>;

    //UPDATE
    if (this.datasetFormS.dataset.getValue() !== null) {
      //si modification on assign les valeurs du formulaire au dataset modifié
      const dataset = Object.assign(this.datasetFormS.dataset.getValue(), this.form.value);
      api = this.metadataDataS.updateDataset(dataset.id_dataset, dataset);
    } else {
      //si creation on envoie le contenu du formulaire
      api = this.metadataDataS.createDataset(this.form.value);
    }

    //envoie de la requete au serveur
    api
      .pipe(
        tap(() => {
          this._commonService.translateToaster('success', 'MetaData.Datasetadded');
          this.metadataS.getMetadata(); //rechargement de la liste de la page principale
        })
      )
      .subscribe(
        (dataset: any) => this._router.navigate(['/metadata/dataset_detail', dataset.id_dataset]),
        error => {
          if (error.status === 403) {
            this._commonService.translateToaster('error', 'NotAllowed');
            this._router.navigate(['/metadata/']);
          } else {
            this._commonService.translateToaster('error', 'ErrorMessage');
          }
        }
      );
  }
}
