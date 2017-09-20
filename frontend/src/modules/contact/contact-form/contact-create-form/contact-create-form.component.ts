import { Component, OnInit, Input } from '@angular/core';
import { FormGroup, FormArray } from '@angular/forms';
import { FormService } from '../../../../core/GN2Common/form/form.service'
import { DataFormService } from '../../../../core/GN2Common/form/data-form.service'
import { MapService } from '../../../../core/GN2Common/map/map.service';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import { ContactFormService } from './contact-form.service';



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
     private toastr: ToastrService, private _cfs: ContactFormService
    ) {  }

  ngOnInit() {
    this.releveForm = this.fs.initObservationForm();
    this.occurrenceForm = this.fs.initOccurrenceForm();
    this.countingForm = this.fs.initCountingArray();
    console.log('id from route' + this.id);

    if (this.id !== undefined) {
      // load one releve
      this._cfs.getReleve(this.id)
        .subscribe(data => {
          this.releveForm = this.fs.initObservationForm(data);
          this.occurrenceForm = this.fs.initOccurrenceForm(data.occurrences);
      });
    }

    // init the taxons list
    this.taxonsList = [];
  }

  addOccurence(index) {
    // add an occurrence
    this.fs.addOccurence(this.occurrenceForm, this.releveForm, this.countingForm);
    // set the index occurence
    this.fs.indexOccurrence = this.releveForm.value.properties.t_occurrences_contact.length ;
    // reset occurrence form
    this.occurrenceForm = this.fs.initOccurrenceForm();
    // reset the counting
    this.countingForm = this.fs.initCountingArray();

    // push the current taxon in the taxon list and refresh the currentTaxon
    this.taxonsList.push(this.fs.currentTaxon);
  }

  editOccurence(index) {
    // set the current index
    this.fs.indexOccurrence = index;
    // get the occurrence data from releve form
    const occurenceData = this.releveForm.value.properties.t_occurrences_contact[index];
    const countingData = occurenceData.cor_counting_contact;

    const nbCounting = countingData.length;
    // init occurence form with the data to edit
    this.occurrenceForm = this.fs.initOccurrenceForm(occurenceData);
    // get counting data from occurence

    // init the counting form with the data to edit
    for (let i = 1; i < nbCounting; i++) {
      this.fs.nbCounting.push('');
     }
    this.countingForm = this.fs.initCountingArray(countingData);
    // set the current taxon
    this.fs.currentTaxon = occurenceData.cd_nom;
  }

  submitData() {
    // Format the final form
    const finalForm = this.releveForm.value;
    finalForm.geometry = finalForm.geometry.geometry;
    finalForm.properties.date_min = this._dateParser.format(finalForm.properties.date_min);
    finalForm.properties.date_max = this._dateParser.format(finalForm.properties.date_max);
    // format cd_nom
    finalForm.properties.t_occurrences_contact.forEach(occ => {
      occ.nom_cite = occ.cd_nom.nom_valide;
      occ.cd_nom = occ.cd_nom.cd_nom;
    });
    // format observers
    finalForm.properties.observers = finalForm.properties.observers
      .map(observer => observer.id_role )

    console.log(finalForm);
    
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
        },
        (error) => { this.toastr.error("Une erreur s'est produite!", '', {positionClass:'toast-top-center'});}
      );


    
  }


}
