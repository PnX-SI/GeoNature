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

    //this.releveForm.value = this.releveForm.value;

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
          console.log(this.releveForm.value.properties.t_occurrences_contact);
          
          // set the occurrence
          this.fs.indexOccurrence = this.releveForm.value.properties.t_occurrences_contact.length;
          // push the geometry in releveForm
          this.releveForm.patchValue({geometry: data.geometry});
          // copy the form data
          //this.releveForm.value = this.releveForm.value;
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
    this.taxonsList.push(this.fs.currentTaxon);
    // push the counting
    this.occurrenceForm.controls.cor_counting_contact.patchValue(this.countingForm.value);
    // format the taxon
    this.occurrenceForm.value.cd_nom = this.occurrenceForm.value.cd_nom.cd_nom;  
    if (this.releveForm.value.properties.t_occurrences_contact.length === this.fs.indexOccurrence) {
      this.releveForm.value.properties.t_occurrences_contact.push(this.occurrenceForm.value);
    }else {
      this.releveForm.value.properties.t_occurrences_contact[this.fs.indexOccurrence] = this.occurrenceForm.value;
    }
    // set occurrence index  
    this.fs.indexOccurrence = this.releveForm.value.properties.t_occurrences_contact.length;
    // reset counting
    this.fs.nbCounting = [''];
    this.fs.indexCounting = 0;
    // reset current taxon
    this.fs.currentTaxon = {};
    // reset occurrence form
    this.occurrenceForm = this.fs.initOccurrenceForm();
    // reset the counting
    this.countingForm = this.fs.initCountingArray();
  }

  editOccurence(index) {
    this.taxonsList.splice(index, 1);
    // set the current index
    this.fs.indexOccurrence = index;
    // get the occurrence data from releve form
    let occurenceData = this.releveForm.value.properties.t_occurrences_contact[index];
    const countingData = occurenceData.cor_counting_contact;
    const nbCounting = countingData.length;
    // load the taxons info
    this._dfs.getTaxonInfo(occurenceData.cd_nom)
      .subscribe(taxon => {
        occurenceData['cd_nom'] = {
          'cd_nom': taxon.cd_nom,
          'group2_inpn': taxon.group2_inpn,
          'lb_nom': taxon.lb_nom,
          'nom_valide': taxon.nom_valide,
          'regne': taxon.regne,
          
        }
        // init occurence form with the data to edit
        this.occurrenceForm = this.fs.initOccurrenceForm(occurenceData);
        // set the current taxon
        this.fs.currentTaxon = occurenceData.cd_nom;
      });
    // init the counting form with the data to edit
    for (let i = 1; i < nbCounting; i++) {
      this.fs.nbCounting.push('');
     }
    this.countingForm = this.fs.initCountingArray(countingData);

  }

  removeOneOccurrence(index){
    this.taxonsList.splice(index, 1);
    this.releveForm.value.properties.t_occurrences_contact.splice(index, 1);
    this.fs.indexOccurrence = this.fs.indexOccurrence - 1 ;
  }

  submitData() {
    // set the releveForm
    const finalForm = this.releveForm.value;
    //format date
    finalForm.properties.date_min = this._dateParser.format(finalForm.properties.date_min);
    finalForm.properties.date_max = this._dateParser.format(finalForm.properties.date_max);
    // format nom_cite and update date
    finalForm.properties.t_occurrences_contact.forEach((occ, index) => {
      occ.nom_cite = this.taxonsList[index].nom_valide;
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
