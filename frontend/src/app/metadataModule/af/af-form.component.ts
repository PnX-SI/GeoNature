import { Component, OnInit } from '@angular/core';
import { UntypedFormArray, UntypedFormGroup } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { ToastrService } from 'ngx-toastr';
import { Router, ActivatedRoute } from '@angular/router';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { of, Observable } from 'rxjs';
import { switchMap, tap, map } from 'rxjs/operators';

import { DataFormService } from '@geonature_common/form/data-form.service';
import { CommonService } from '@geonature_common/service/common.service';
import { AppConfig } from '@geonature_config/app.config';
import { ActorFormService } from '../services/actor-form.service';
import { AcquisitionFrameworkFormService } from '../services/af-form.service';
import { MetadataService } from '../services/metadata.service';
import { MetadataDataService } from '../services/metadata-data.service';

@Component({
  selector: 'pnx-af-form',
  templateUrl: './af-form.component.html',
  styleUrls: ['../form.component.scss'],
  providers: [AcquisitionFrameworkFormService],
})
export class AfFormComponent implements OnInit {
  public form: UntypedFormGroup;
  //observable pour la liste déroulantes HTML des AF parents
  public acquisitionFrameworkParents: Observable<any>;

  constructor(
    private _dfs: DataFormService,
    private _commonService: CommonService,
    private _route: ActivatedRoute,
    private _api: HttpClient,
    private _router: Router,
    private _toaster: ToastrService,
    private dateParser: NgbDateParserFormatter,
    public afFormS: AcquisitionFrameworkFormService,
    private actorFormS: ActorFormService,
    public metadataS: MetadataService,
    private metadataDataS: MetadataDataService
  ) {}
  ngOnInit() {
    // get the id from the route
    this._route.params
      .pipe(
        switchMap((params) => {
          return params['id']
            ? this.getAcquisitionFramework(params['id'], { exclude: ['t_datasets'] })
            : of(null);
        })
      )
      .subscribe((af) => this.afFormS.acquisition_framework.next(af));

    this.form = this.afFormS.form;

    // get acquisistion frameworks parent
    this._dfs.getAcquisitionFrameworks({ is_parent: 'true' }).subscribe((afParent) => {
      this.acquisitionFrameworkParents = afParent;
    });
  }

  getAcquisitionFramework(id_af, param) {
    return this._dfs.getAcquisitionFramework(id_af, param).pipe(
      map((af: any) => {
        af.acquisition_framework_start_date = this.dateParser.parse(
          af.acquisition_framework_start_date
        );
        af.acquisition_framework_end_date = this.dateParser.parse(
          af.acquisition_framework_end_date
        );
        return af;
      })
    );
  }

  addContact(formArray: UntypedFormArray, mainContact: boolean) {
    let value = null;
    if (mainContact) {
      value = { id_nomenclature_actor_role: this.actorFormS.getIDRoleTypeByCdNomenclature('1') };
    }
    this.afFormS.addActor(formArray, value);
  }

  postAf() {
    if (!this.form.valid) return;

    let api: Observable<any>;

    const af = Object.assign(this.afFormS.acquisition_framework.getValue() || {}, this.form.value);

    af.acquisition_framework_start_date = this.dateParser.format(
      af.acquisition_framework_start_date
    );

    if (af.acquisition_framework_end_date) {
      af.acquisition_framework_end_date = this.dateParser.format(af.acquisition_framework_end_date);
    }
    //UPDATE
    if (this.afFormS.acquisition_framework.getValue() !== null) {
      //si modification on assigne les valeurs du formulaire au CA modifié
      api = this.metadataDataS.updateAF(af.id_acquisition_framework, af);
    } else {
      //si creation on envoie le contenu du formulaire
      api = this.metadataDataS.createAF(af);
    }

    //envoie de la requete au serveur
    api
      .pipe(
        tap(() => {
          this._commonService.translateToaster('success', 'MetaData.AFadded');
          this.metadataS.getMetadata(); //rechargement de la liste de la page principale
        })
      )
      .subscribe(
        (acquisition_framework: any) =>
          this._router.navigate([
            '/metadata/af_detail',
            acquisition_framework.id_acquisition_framework,
          ]),
        (error) => {
          if (error.status === 403) {
            this._commonService.translateToaster('error', 'NotAllowed');
            this._router.navigate(['/metadata/']);
          }
        }
      );
  }

  getPdf() {
    const url = `${AppConfig.API_ENDPOINT}/meta/acquisition_frameworks/export_pdf/${
      this.afFormS.acquisition_framework.getValue().id_acquisition_framework
    }`;
    window.open(url);
  }
}
