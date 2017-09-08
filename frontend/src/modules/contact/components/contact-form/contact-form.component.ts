import { Component, OnInit } from '@angular/core';
import { FormGroup, FormArray } from '@angular/forms';
import { FormService }  from '../../../../core/GN2Common/form/form.service'
import { DataFormService }  from '../../../../core/GN2Common/form/data-form.service'
import { MapService } from '../../../../core/GN2Common/map/map.service';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';



@Component({
  selector: 'pnx-contact-form',
  templateUrl: './contact-form.component.html',
  styleUrls: ['./contact-form.component.scss'],
  providers: [FormService]
})
export class ContactFormComponent implements OnInit {
  public taxonsList: Array<any>;
  public releveForm: FormGroup;
  public occurrenceForm: FormGroup;
  public countingForm: FormArray;
  public contactForm: FormGroup;

  constructor(public fs: FormService, private _ms: MapService,
     private _dateParser: NgbDateParserFormatter, private _dfs: DataFormService
    ) {  }

  ngOnInit() {
    // init the formsGroups
    this.releveForm = this.fs.initObservationForm();
    this.occurrenceForm = this.fs.initOccurrenceForm();
    this.countingForm = this.fs.initCountingArray();
    // init the taxons list
    this.taxonsList = [];
  }

  addOccurence() {
    // add an occurrence
    this.fs.addOccurence(this.occurrenceForm, this.releveForm, this.countingForm);
    // reset the occurence
    this.occurrenceForm = this.fs.initOccurrenceForm();
    // reset the counting
    this.countingForm = this.fs.initCountingArray();

    // push the current taxon in the taxon list and refresh the currentTaxon
    this.taxonsList.push(this.fs.currentTaxon);
    this.fs.currentTaxon = {};
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

    //provisoire test
    delete finalForm.properties.id_municipality;
    console.log(JSON.stringify(finalForm));
    

    // Post
    this._dfs.postContact(finalForm)
      .subscribe(response => console.log(response));

    // resert the forms
    this.releveForm = this.fs.initObservationForm();
    this.occurrenceForm = this.fs.initOccurrenceForm();
    this.countingForm = this.fs.initCountingArray();
    
    this.fs.municipalities = "";

    
  }


}
