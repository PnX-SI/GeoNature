import { Component, OnInit, Input } from '@angular/core';
import { FormGroup, FormArray } from '@angular/forms';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { MapService } from '@geonature_common/map/map.service';
import { CommonService } from '@geonature_common/service/common.service';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import { OcctaxFormService } from './occtax-form.service';
import { Router } from '@angular/router';
import * as L from 'leaflet';
import { ModuleConfig } from '../../module.config';
import { OcctaxService } from '../../services/occtax.service';
import { timeout } from 'rxjs/operators/timeout';

@Component({
  selector: 'pnx-occtax-form',
  templateUrl: './occtax-form.component.html',
  styleUrls: ['./occtax-form.component.scss'],
  providers: []
})
export class OcctaxFormComponent implements OnInit {
  public disabledAfterPost = false;
  @Input() id: number;

  constructor(
    public fs: OcctaxFormService,
    private _ms: MapService,
    private _dateParser: NgbDateParserFormatter,
    private _dfs: DataFormService,
    private _cfs: OcctaxService
    private toastr: ToastrService,
    private router: Router,
    private occtaxService: OcctaxService,
    private _commonService: CommonService
  ) {}

  ngOnInit() {
    // set show occurrence to false:
    this.fs.showOccurrence = false;
    // refresh the forms
    this.fs.releveForm = this.fs.initReleveForm();
    this.fs.occurrenceForm = this.fs.initOccurenceForm();
    this.fs.countingForm = this.fs.initCountingArray();

    // patch default values in ajax
    this.fs.patchAllDefaultNomenclature();

    // reset taxon list of service
    this.fs.taxonsList = [];
    this.fs.indexOccurrence = 0;
    this.fs.editionMode = false;

    // remove disabled on geom selected

    this.fs.releveForm.controls.geometry.valueChanges.subscribe(data => {
      this.fs.disabled = false;
    });

    // if its edition mode
    if (!isNaN(this.id)) {
      // set showOccurrence to false;
      this.fs.showOccurrence = false;
      this.fs.editionMode = true;
      // load one releve
      this.occtaxService.getOneReleve(this.id).subscribe(data => {

        data.releve.properties.observers = data.releve.properties.observers.map(obs => {
          obs['nom_complet'] = obs.nom_role + ' ' + obs.prenom_role;
          return obs;
        });

        // pre fill the form
        this.fs.releveForm.patchValue({ properties: data.releve.properties });

        (this.fs.releveForm.controls.properties as FormGroup).patchValue({
          date_min: this.fs.formatDate(data.releve.properties.date_min)
        });
        (this.fs.releveForm.controls.properties as FormGroup).patchValue({
          date_max: this.fs.formatDate(data.releve.properties.date_max)
        });
        const hour_min =
          data.releve.properties.hour_min === 'None' ? null : data.releve.properties.hour_min;
        const hour_max =
          data.releve.properties.hour_max === 'None' ? null : data.releve.properties.hour_max;
        (this.fs.releveForm.controls.properties as FormGroup).patchValue({ hour_min: hour_min });
        (this.fs.releveForm.controls.properties as FormGroup).patchValue({ hour_max: hour_max });

        const orderedCdNomList = [];
        data.releve.properties.t_occurrences_occtax.forEach(occ => {
          orderedCdNomList.push(occ.cd_nom);
          this._dfs.getTaxonInfo(occ.cd_nom).subscribe(taxon => {
            this.fs.taxonsList.push(taxon);
          });
        });

        // HACK to re order taxon list because of side effect of ajax
        // TODO: do it with async
        const reOrderTaxon = [];
        setTimeout(() => {
          for (let i = 0; i < orderedCdNomList.length; i++) {
            for (let j = 0; j < this.fs.taxonsList.length; j++) {
              if (this.fs.taxonsList[j].cd_nom === orderedCdNomList[i]) {
                reOrderTaxon.push(this.fs.taxonsList[j]);
                break;
              }
            }
          }
          this.fs.taxonsList = reOrderTaxon;
        }, 1500);

        // set the occurrence
        this.fs.indexOccurrence = data.releve.properties.t_occurrences_occtax.length;
        // push the geometry in releveForm
        this.fs.releveForm.patchValue({ geometry: data.releve.geometry });
        // load the geometry in the map
        this._ms.loadGeometryReleve(data.releve, true);
      },
    error => {
      this._commonService.translateToaster('error', 'Releve.DoesNotExist');
      this.router.navigate(['/occtax']);
    }
    ); // end subscribe
    }
  } // end ngOnInit

  formDisabled() {
    if (this.fs.disabled) {
      this._commonService.translateToaster('warning', 'Releve.FillGeometryFirst');
    }
  }

  submitData() {
    
    // set the releveForm
    // copy the form value without reference
    const finalForm = JSON.parse(JSON.stringify(this.fs.releveForm.value));
    // format date
    const saveForm = JSON.parse(JSON.stringify(this.fs.releveForm.value));
    finalForm.properties.date_min = this._dateParser.format(finalForm.properties.date_min);
    finalForm.properties.date_max = this._dateParser.format(finalForm.properties.date_max);
    // format nom_cite and update date
    finalForm.properties.t_occurrences_occtax.forEach((occ, index) => {
      if (this.fs.taxonsList[index].search_name) {
        occ.nom_cite = this.fs.taxonsList[index].search_name.replace('<i>', '');
        occ.nom_cite = occ.nom_cite.replace('</i>', '');
      }
    });
    // format observers
    if (finalForm.properties.observers && finalForm.properties.observers.length > 0) {
      finalForm.properties.observers = finalForm.properties.observers.map(
        observer => observer.id_role
      );
    }
    // disable button
    this.disabledAfterPost = true;
    // Post
    //console.log(JSON.stringify(finalForm));

    this._cfs.postOcctax(finalForm).subscribe(
      response => {
        this.disabledAfterPost = false;
        this.toastr.success('Relevé enregistré', '', { positionClass: 'toast-top-center' });
        // resert the forms
        this.fs.releveForm = this.fs.initReleveForm();
        this.fs.occurrenceForm = this.fs.initOccurenceForm();
        this.fs.patchDefaultNomenclatureOccurrence(this.fs.defaultValues);
        this.fs.countingForm = this.fs.initCountingArray();

        this.fs.taxonsList = [];
        this.fs.indexOccurrence = 0;
        this.fs.disabled = true;
        this.fs.showCounting = false;
        // redirect
        this.router.navigate(['/occtax']);
      },
      error => {
        if (error.status === 403) {
          this._commonService.translateToaster('error', 'NotAllowed');
        } else {
          console.error(error.error.message);
          this._commonService.translateToaster('error', 'ErrorMessage');
        }
      }
    );
  }
}
