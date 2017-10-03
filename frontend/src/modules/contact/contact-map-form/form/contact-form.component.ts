import { Component, OnInit, Input } from '@angular/core';
import { FormGroup, FormArray } from '@angular/forms';
import { DataFormService } from '../../../../core/GN2Common/form/data-form.service'
import { MapService } from '../../../../core/GN2Common/map/map.service';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import { ContactFormService } from './contact-form.service';
import { Router } from '@angular/router';
import * as L from 'leaflet';



@Component({
  selector: 'pnx-contact-form',
  templateUrl: './contact-form.component.html',
  styleUrls: ['./contact-form.component.scss'],
  providers: []
})
export class ContactFormComponent implements OnInit {
  public taxonsList: Array<any>;
  public contactForm: FormGroup;
  @Input() id: number;

  constructor(public fs: ContactFormService, private _ms: MapService,
     private _dateParser: NgbDateParserFormatter, private _dfs: DataFormService,
     private toastr: ToastrService,
     private router: Router
    ) {  }

  ngOnInit() {
    // init the form
    this.fs.releveForm = this.fs.initObservationForm();
    this.fs.occurrenceForm = this.fs.initOccurrenceForm();
    this.fs.countingForm = this.fs.initCountingArray();


    // if its edition mode
    if (!isNaN(this.id )) {
      // load one releve
      this.fs.getReleve(this.id)
        .subscribe(data => {
          console.log(data);

          // pre fill the form
          this.fs.releveForm = this.fs.initObservationForm(data);
          for (const occ of data.properties.t_occurrences_contact){
            // push the occ in releveForm
            this.fs.releveForm.value.properties.t_occurrences_contact.push(occ);
            // push the taxon list
            this.taxonsList.push({'nom_valide': occ.nom_cite});
          }
          // set the occurrence
          this.fs.indexOccurrence = this.fs.releveForm.value.properties.t_occurrences_contact.length;
          // push the geometry in releveForm
          this.fs.releveForm.patchValue({geometry: data.geometry});
          // load the geometry in the map
          this._ms.loadGeometryReleve(data);
          // get geoInfo to get municipalities
          this._dfs.getGeoInfo(data)
            .subscribe(data => { this.fs.municipalities = data.municipality.map(m => m.area_name).join(', ')});
      }); // end subscribe
    }
    // init the taxons list
    this.taxonsList = [];
  } // end ngOnInit

  addOccurence(index) {
    // push the current taxon in the taxon list and refresh the currentTaxon
    this.taxonsList.push(this.fs.currentTaxon);
    // push the counting
    this.fs.occurrenceForm.controls.cor_counting_contact.patchValue(this.fs.countingForm.value);
    // format the taxon
    this.fs.occurrenceForm.value.cd_nom = this.fs.occurrenceForm.value.cd_nom.cd_nom;
    if (this.fs.releveForm.value.properties.t_occurrences_contact.length === this.fs.indexOccurrence) {
      this.fs.releveForm.value.properties.t_occurrences_contact.push(this.fs.occurrenceForm.value);
    }else {
      this.fs.releveForm.value.properties.t_occurrences_contact[this.fs.indexOccurrence] = this.fs.occurrenceForm.value;
    }
    // set occurrence index
    this.fs.indexOccurrence = this.fs.releveForm.value.properties.t_occurrences_contact.length;
    // reset counting
    this.fs.nbCounting = [''];
    this.fs.indexCounting = 0;
    // reset current taxon
    this.fs.currentTaxon = {};
    // reset occurrence form
    this.fs.occurrenceForm = this.fs.initOccurrenceForm();
    // reset the counting
    this.fs.countingForm = this.fs.initCountingArray();
  }

  editOccurence(index) {
    this.taxonsList.splice(index, 1);
    // set the current index
    this.fs.indexOccurrence = index;
    // get the occurrence data from releve form
    let occurenceData = this.fs.releveForm.value.properties.t_occurrences_contact[index];
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
        this.fs.occurrenceForm = this.fs.initOccurrenceForm(occurenceData);
        // set the current taxon
        this.fs.currentTaxon = occurenceData.cd_nom;
      });
    // init the counting form with the data to edit
    for (let i = 1; i < nbCounting; i++) {
      this.fs.nbCounting.push('');
     }
    this.fs.countingForm = this.fs.initCountingArray(countingData);

  }

  removeOneOccurrence(index){
    this.taxonsList.splice(index, 1);
    this.fs.releveForm.value.properties.t_occurrences_contact.splice(index, 1);
    this.fs.indexOccurrence = this.fs.indexOccurrence - 1 ;
  }

  submitData() {
    // set the releveForm
    const finalForm = this.fs.releveForm.value;
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
        this.fs.releveForm = this.fs.initObservationForm();
        this.fs.occurrenceForm = this.fs.initOccurrenceForm();
        this.fs.countingForm = this.fs.initCountingArray();
        this.taxonsList = [];
        this.fs.municipalities = "";
        // redirect
        this.router.navigate(['/contact']);
        },
        (error) => { this.toastr.error("Une erreur s'est produite!", '', {positionClass:'toast-top-center'});}
      );

  }


}
