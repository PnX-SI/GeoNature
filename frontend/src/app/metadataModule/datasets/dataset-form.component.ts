import { Component, OnInit } from '@angular/core';
import { UntypedFormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { of, Observable } from 'rxjs';
import { switchMap, tap, map } from 'rxjs/operators';

import { CommonService } from '@geonature_common/service/common.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { ModuleService } from '@geonature/services/module.service';
import { DatasetFormService } from '../services/dataset-form.service';
import { ActorFormService } from '../services/actor-form.service';
import { MetadataService } from '../services/metadata.service';
import { MetadataDataService } from '../services/metadata-data.service';
import { ConfigService } from '@geonature/services/config.service';
import { TranslateService } from '@librairies/@ngx-translate/core';

import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';

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
  public entityLabel: string;
  public dataCategoryValues: any[] = []; // Add this property
  public oldDataCategoryPrecisionValue: string = null;

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
    private _config: ConfigService,
    public translation_service: TranslateService,
    private dateParser: NgbDateParserFormatter
  ) {}

  ngOnInit() {
    // get the id from the route
    this._route.params
      .pipe(
        switchMap((params) => {
          if (params['id']) {
            // Update
            return this._dfs
              .getDataset(params['id'])
              .pipe(tap((dataset) => this.handleDates(dataset, true)));
          }
          // Creation
          return of(null);
        })
      )
      .subscribe((dataset) => {
        if (dataset) {
          this.datasetFormS.dataset.next(dataset);
          this.updateFormControlsState(dataset);
        }
        if (dataset?.acquisition_framework?.opened === false) {
          // If AF closed, we only get the AF of the current dataset
          this.acquisitionFrameworks = of([dataset.acquisition_framework]);
        } else {
          // If AF opened or it is a creation, we get the list of AF
          this.acquisitionFrameworks = this._dfs
            .getAcquisitionFrameworksList({ opened: true }, {}, 1, -1)
            .pipe(map((response) => response.items));
        }
        this.loadDataCategoryNomenclatures();
      });
    this.form = this.datasetFormS.form;

    // Patch form with query parameters if they exist as form controls
    this._route.queryParams.subscribe((queryParams) => {
      const patchData: { [key: string]: any } = {};
      Object.keys(queryParams).forEach((key) => {
        if (this.form.controls[key]) {
          // Convert to number if the value looks like a number
          patchData[key] = isNaN(+queryParams[key]) ? queryParams[key] : +queryParams[key];
        }
      });
      if (Object.keys(patchData).length > 0) {
        this.form.patchValue(patchData);
      }
    });

    this._dfs.getTaxaBibList().subscribe((d) => (this.taxaBibList = d));
    this.uuidEditionEnabled = this._config.METADATA.ENABLE_UUID_EDITION_FIELD;
    this.entityLabel = this.translation_service.instant('Dataset');

    this.form.get('id_nomenclature_data_category')?.valueChanges.subscribe(() => {
      this.updatePrecisionDataCategoryValidation();
    });
  }

  handleDates(dataset, isParseElseFormat = false) {
    const handlingFunction = isParseElseFormat ? this.dateParser.parse : this.dateParser.format;

    // Additional fields - Format dates
    this.additionalFieldsForm.forEach((fieldForm: any) => {
      if (fieldForm.type_widget == 'date') {
        dataset.additional_data[fieldForm.attribut_name] = handlingFunction(
          dataset.additional_data[fieldForm.attribut_name]
        );
      }
    });
  }

  get propertiesForm(): any {
    return this.form;
  }

  get additionalFieldsForm(): any[] {
    return this.datasetFormS.additionalFieldsForm;
  }

  updateFormControlsState(dataset: any): void {
    // if the af is closed, we disable the acquisition_framework selection and active fields
    if (dataset && dataset.acquisition_framework?.opened === false) {
      this.form.get('active')?.disable();
      this.form.get('id_acquisition_framework')?.disable();
    }
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

  loadDataCategoryNomenclatures(): void {
    this._dfs.getNomenclature('DATA_CATEGORY').subscribe((response) => {
      this.dataCategoryValues = response.values || [];
    });
  }

  showPrecisionDataCategory() {
    const selectedId = this.form.get('id_nomenclature_data_category')?.value;
    if (!selectedId || !this.dataCategoryValues.length) {
      return false;
    }
    const selectedNomenclature = this.dataCategoryValues.find(
      (n) => n.id_nomenclature === selectedId
    );
    // Check if mnemonique is "autre" if so, show precision data category
    return selectedNomenclature?.mnemonique === 'autre';
  }

  updatePrecisionDataCategoryValidation(): void {
    const precisionControl = this.form.get('precision_data_category');
    if (!precisionControl) return;

    if (this.showPrecisionDataCategory()) {
      // Precision data category should be displayed and required
      precisionControl.setValue(this.oldDataCategoryPrecisionValue);
      precisionControl.setValidators([Validators.required]);
    } else {
      // Precision data category is not displayed, so not required and set to null
      this.oldDataCategoryPrecisionValue = precisionControl.getRawValue();
      precisionControl.setValue(null);
      precisionControl.clearValidators();
    }
    precisionControl.updateValueAndValidity({ emitEvent: false });
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

    this.handleDates(dataset);

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
