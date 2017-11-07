import { Component, OnInit, Input } from '@angular/core';
import { FormGroup, FormArray } from '@angular/forms';
import { DataFormService } from '../../../../core/GN2Common/form/data-form.service';
import { MapService } from '../../../../core/GN2Common/map/map.service';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import { ContactFormService } from './contact-form.service';
import { Router } from '@angular/router';
import * as L from 'leaflet';
import { ContactConfig } from '../../contact.config';
import { ContactService } from '../../services/contact.service';




@Component({
  selector: 'pnx-contact-form',
  templateUrl: './contact-form.component.html',
  styleUrls: ['./contact-form.component.scss'],
  providers: []
})
export class ContactFormComponent implements OnInit {
  @Input() id: number;

  constructor(public fs: ContactFormService, private _ms: MapService,
     private _dateParser: NgbDateParserFormatter, private _dfs: DataFormService,
     private toastr: ToastrService,
     private router: Router,
     private contactService: ContactService,
    ) {  }

  ngOnInit() {
    // set show occurrence to false:
    this.fs.showOccurrence = false;
    // init the form
    this.fs.releveForm = this.fs.initObservationForm();
    this.fs.occurrenceForm = this.fs.initOccurrenceForm();
    this.fs.countingForm = this.fs.initCountingArray();
    // reset taxon list of service
    this.fs.taxonsList = [];
    this.fs.indexOccurrence = 0;
    this.fs.editionMode = false;

    // if its edition mode
    if (!isNaN(this.id )) {
      // set showOccurrence to false;
      this.fs.showOccurrence = false;
      this.fs.editionMode = true;
      // load one releve
      this.contactService.getReleve(this.id)
        .subscribe(data => {
          // pre fill the form
          this.fs.releveForm.patchValue({properties: data.properties});
          (this.fs.releveForm.controls.properties as FormGroup).patchValue({date_min: this.fs.formatDate(data.properties.date_min)});
          (this.fs.releveForm.controls.properties as FormGroup).patchValue({date_max: this.fs.formatDate(data.properties.date_max)});
          const hour_min = data.properties.hour_min === 'None' ? null : data.properties.hour_min;
          const hour_max = data.properties.hour_max === 'None' ? null : data.properties.hour_max;
          (this.fs.releveForm.controls.properties as FormGroup).patchValue({hour_min: hour_min});
          (this.fs.releveForm.controls.properties as FormGroup).patchValue({hour_max: hour_max});
          for (const occ of data.properties.t_occurrences_contact){
            // load taxon info in ajax
            this._dfs.getTaxonInfo(occ.cd_nom)
              .subscribe(taxon => this.fs.taxonsList.push(taxon));
          }
          // set the occurrence
          this.fs.indexOccurrence = data.properties.t_occurrences_contact.length;
          // push the geometry in releveForm
          this.fs.releveForm.patchValue({geometry: data.geometry});
          // load the geometry in the map
          this._ms.loadGeometryReleve(data, true);
      }); // end subscribe
    }

  } // end ngOnInit



  submitData() {
    // set the releveForm
    const finalForm = this.fs.releveForm.value;
    // format date
    finalForm.properties.date_min = this._dateParser.format(finalForm.properties.date_min);
    finalForm.properties.date_max = this._dateParser.format(finalForm.properties.date_max);
    // format nom_cite and update date
    finalForm.properties.t_occurrences_contact.forEach((occ, index) => {
      if (this.fs.taxonsList[index].search_name) {
        occ.nom_cite = this.fs.taxonsList[index].search_name.replace('<i>', '');
        occ.nom_cite = occ.nom_cite.replace('</i>', '');
      }
      occ.meta_update_date = new Date();
    });
    // format observers
    if (!ContactConfig.observers_txt) {
      finalForm.properties.observers = finalForm.properties.observers
      .map(observer => observer.id_role);
    }
    // Post
    console.log(JSON.stringify(finalForm));
    this._dfs.postContact(finalForm)
      .subscribe(
        (response) => {
          this.toastr.success('Relevé enregistré', '', {positionClass:'toast-top-center'});
        // resert the forms
        this.fs.releveForm = this.fs.initObservationForm();
        this.fs.occurrenceForm = this.fs.initOccurrenceForm();
        this.fs.countingForm = this.fs.initCountingArray();
        this.fs.taxonsList = [];
        this.fs.indexOccurrence = 0 ;
        // redirect
        this.router.navigate(['/occtax']);
        },
        (error) => { this.toastr.error("Une erreur s'est produite!", '', {positionClass:'toast-top-center'});}
      );

  }


}
