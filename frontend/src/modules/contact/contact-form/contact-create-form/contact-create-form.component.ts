import { Component, OnInit, Input } from '@angular/core';
import { FormGroup, FormArray } from '@angular/forms';
import { FormService } from '../../../../core/GN2Common/form/form.service'
import { DataFormService } from '../../../../core/GN2Common/form/data-form.service'
import { MapService } from '../../../../core/GN2Common/map/map.service';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import { ContactFormService } from './contact-form.service';
import { Router } from '@angular/router';
import * as L from 'leaflet';



@Component({
  selector: 'pnx-contact-create-form',
  templateUrl: './contact-create-form.component.html',
  styleUrls: ['./contact-create-form.component.scss'],
  providers: [FormService, ContactFormService]
})
export class ContactCreateFormComponent implements OnInit {
  public taxonsList: Array<any>;
  public releveForm: FormGroup;
  public occurrenceForm: FormGroup;
  public countingForm: FormArray;
  public contactForm: FormGroup;
  public releveFormData: any;
  @Input() id: number;

  constructor(public fs: FormService, private _ms: MapService,
     private _dateParser: NgbDateParserFormatter, private _dfs: DataFormService,
     private toastr: ToastrService, private _cfs: ContactFormService,
     private router: Router
    ) {  }

  ngOnInit() {
    // init the form
    this.releveForm = this.fs.initObservationForm();
    this.occurrenceForm = this.fs.initOccurrenceForm();
    this.countingForm = this.fs.initCountingArray();

    // if its edition mode
    if (!isNaN(this.id )) {
      // load one releve
      this._cfs.getReleve(this.id)
        .subscribe(data => {
          // pre fill the form
          this.releveForm = this.fs.initObservationForm(data);
          for (const occ of data.properties.t_occurrences_contact){
            // push the occ in releveForm
            this.releveForm.value.properties.t_occurrences_contact.push(occ);
            // push the taxon list
            this.taxonsList.push({'nom_valide': occ.nom_cite});
          }
          // push the geometry in releveForm
          this.releveForm.patchValue({geometry: data.geometry});
          // copy the form data
          this.releveFormData = this.releveForm.value;
          // load the geometry in the map
          this._ms.loadGeometryReleve(data);
          // get geoInfo to get municipalities
          this._dfs.getGeoInfo(data)
            .subscribe(data => { this.fs.municipalities = data.municipality.map(m => m.area_name).join(', ')})

      }); // end subscribe
    }
    // init the taxons list
    this.taxonsList = [];
  } // end ngOnInit

  addOccurence(index) {
    // push the current taxon in the taxon list and refresh the currentTaxon
    // FIX en attendant la vue avec l'objet taxon
    let taxon = {};
    if (this.fs.currentTaxon !== undefined) {
      taxon = {'nom_valide': this.fs.currentTaxon.nom_valide};
    } else {
      taxon = {'nom_valide': this.fs.currentTaxon};
    }
    this.taxonsList.push(taxon);
    // add an occurrence
    this.fs.addOccurence(this.occurrenceForm, this.releveForm, this.countingForm);
    // save the data of form
    // LAAAAAAAAAAA
    this.releveFormData = this.releveForm.value;
    // set the index occurence
    this.fs.indexOccurrence = this.releveForm.value.properties.t_occurrences_contact.length ;
    // reset occurrence form
    this.occurrenceForm = this.fs.initOccurrenceForm();
    // reset the counting
    this.countingForm = this.fs.initCountingArray();
  }

  editOccurence(index) {
    // set the current index
    this.fs.indexOccurrence = index;
    // get the occurrence data from releve form
    // LAAAAAAAAAA
    const occurenceData = this.releveFormData.properties.t_occurrences_contact[index];
    // const occurenceData = this.releveForm.value.properties.t_occurrences_contact[index];
    const countingData = occurenceData.cor_counting_contact;
    const nbCounting = countingData.length;
    // init occurence form with the data to edit
    this.occurrenceForm = this.fs.initOccurrenceForm(occurenceData);
    // init the counting form with the data to edit
    for (let i = 1; i < nbCounting; i++) {
      this.fs.nbCounting.push('');
     }
    this.countingForm = this.fs.initCountingArray(countingData);
    // set the current taxon
    // TODO post the all taxon object quand la vue le renverra
    this.fs.currentTaxon = occurenceData.nom_cite;
  }

  submitData() {
    // Format the final form
    // const finalForm = this.releveForm.value;
    const finalForm = this.releveFormData;
    finalForm.properties.date_min = this._dateParser.format(finalForm.properties.date_min);
    finalForm.properties.date_max = this._dateParser.format(finalForm.properties.date_max);
    // format cd_nom and update date
    finalForm.properties.t_occurrences_contact.forEach(occ => {
      occ.nom_cite = occ.cd_nom.nom_valide;
      occ.cd_nom = occ.cd_nom.cd_nom;
      occ.meta_update_date = new Date();
    });
    // format observers
    finalForm.properties.observers = finalForm.properties.observers
      .map(observer => observer.id_role);

    console.log(finalForm);
    // FIX
    finalForm.properties.municipalities = [74000];

    console.log(JSON.stringify(finalForm));

    // Post
    this._dfs.postContact(finalForm)
      .subscribe(
        (response) => {
          this.toastr.success('Relevé enregistré', '', {positionClass:'toast-top-center'});
        // resert the forms
        this.releveForm = this.fs.initObservationForm();
        this.occurrenceForm = this.fs.initOccurrenceForm();
        this.countingForm = this.fs.initCountingArray();
        this.taxonsList = [];
        this.fs.municipalities = "";
        // redirect
        this.router.navigate(['/contact']);
        },
        (error) => { this.toastr.error("Une erreur s'est produite!", '', {positionClass:'toast-top-center'});}
      );

  }


}
