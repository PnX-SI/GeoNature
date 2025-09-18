import { Component, OnInit } from '@angular/core';
import { UntypedFormGroup } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { of, Observable } from 'rxjs';
import { switchMap, tap } from 'rxjs/operators';

import { CommonService } from '@geonature_common/service/common.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { ModuleService } from '@geonature/services/module.service';
import { DatasetFormService } from '../services/dataset-form.service';
import { ActorFormService } from '../services/actor-form.service';
import { MetadataService } from '../services/metadata.service';
import { MetadataDataService } from '../services/metadata-data.service';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'pnx-datasets-form',
  templateUrl: './dataset-form.component.html',
  styleUrls: ['../form.component.scss'],
  providers: [DatasetFormService],
})
export class DatasetFormComponent implements OnInit {
  public form: UntypedFormGroup;
  //observable pour la liste déroulantes HTML des AF
  public acquisitionFrameworks: Observable<any>;
  public taxaBibList: number;
  public uuidEditionEnabled: boolean = true;

  constructor(
    private _route: ActivatedRoute,
    private _router: Router,
    private _commonService: CommonService,
    private _dfs: DataFormService,
    public datasetFormS: DatasetFormService,
    public moduleService: ModuleService,
    private actorFormS: ActorFormService,
    private metadataS: MetadataService,
    private metadataDataS: MetadataDataService,
    private _config: ConfigService
  ) {}

  ngOnInit() {
    // get the id from the route
    this._route.params
      .pipe(
        switchMap((params) => {
          return params['id'] ? this._dfs.getDataset(params['id']) : of(null);
        })
      )
      .subscribe((dataset) => this.datasetFormS.dataset.next(dataset));

    this.form = this.datasetFormS.form;

    this._dfs.getTaxaBibList().subscribe((d) => (this.taxaBibList = d));

    this.acquisitionFrameworks = this._dfs.getAcquisitionFrameworksList();
    this.uuidEditionEnabled = this._config.METADATA.ENABLE_UUID_EDITION_FIELD;
  }

  genericActorFormSubmit(result) {
    if (result) {
      // TODO
      // this.datasetFormS.addActor(this.genericActorForm.value);
      // this.genericActorForm.reset();
    }
  }

  addMainContact() {
    this.datasetFormS.addActor({
      id_nomenclature_actor_role: this.actorFormS.getIDRoleTypeByCdNomenclature('1'),
    });
  }
  addGenericContact() {
    this.datasetFormS.genericActorForm.push(this.actorFormS.createForm());
  }

  mergeActors(dataset, genericActors) {
    dataset.cor_dataset_actor = dataset.cor_dataset_actor.concat(genericActors);
  }

  postDataset() {
    if (this.form.invalid || this.datasetFormS.genericActorForm.invalid) return;

    let api: Observable<any>;

    const base = {
      ...this.datasetFormS.dataset.getValue(),
      ...this.form.value,
    };

    const dataset =
      this.form.value.unique_dataset_id != null
        ? {
            ...base,
            unique_dataset_id: this.form.value.unique_dataset_id,
          }
        : base;
    this.mergeActors(dataset, this.datasetFormS.genericActorForm.value);

    //UPDATE
    if (this.datasetFormS.dataset.getValue() !== null) {
      //si modification on assign les valeurs du formulaire au dataset modifié
      api = this.metadataDataS.updateDataset(dataset.id_dataset, dataset);
    } else {
      //si creation on envoie le contenu du formulaire
      api = this.metadataDataS.createDataset(dataset);
    }

    //envoie de la requete au serveur
    api
      .pipe(
        tap(() => {
          this._commonService.translateToaster('success', 'MetaData.Messages.DatasetAdded');
          this.metadataS.getMetadata(); //rechargement de la liste de la page principale
        })
      )
      .subscribe(
        (dataset: any) => {
          this._router.navigate(['/metadata/dataset_detail', dataset.id_dataset]);
        },
        (error) => {
          if (error.status === 403) {
            this._commonService.translateToaster('error', 'Errors.NotAllowed');
            this._router.navigate(['/metadata/']);
          }
        }
      );
  }
}
