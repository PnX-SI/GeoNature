import { Component, OnInit, OnDestroy } from '@angular/core';
import { FormControl, FormGroup, FormArray } from '@angular/forms';
import { DataFormService } from '../../../../core/GN2Common/form/data-form.service';
import { FormService }  from '../../../../core/GN2Common/form/form.service'
import { MapService } from '../../../../core/GN2Common/map/map.service';
import { Subscription } from 'rxjs/Subscription';
import 'rxjs/add/operator/startWith';
import 'rxjs/add/operator/map';



@Component({
  selector: 'pnx-contact-form',
  templateUrl: './contact-form.component.html',
  styleUrls: ['./contact-form.component.scss'],
  providers: [FormService]
})
export class ContactFormComponent implements OnInit, OnDestroy {
  public dataForm: any;
  public dataSets: any;
  public taxonsList: Array<any>;
  public observationForm:FormGroup;
  public occurrenceForm:FormGroup;
  public countingForm: FormArray;
  public contactForm: FormGroup;
  public geojson: any;
  private geojsonSubscription: Subscription;
  constructor(private _dfService: DataFormService, public fs: FormService, private _ms: MapService) {  }

  ngOnInit() {
    // releve get dataSet
    this._dfService.getDatasets()
      .subscribe(res => this.dataSets = res);
    // provisoire:
    this.dataSets = [1, 2, 3];

    // init the formsGroups
    this.observationForm = this.fs.initObservationForm();
    this.occurrenceForm = this.fs.initOccurrenceForm();
    this.countingForm = this.fs.initCountingArray();
    
    // init the taxons list
    this.taxonsList = [];

    // subscription to the coord observable
    this.geojsonSubscription = this._ms.gettingCoord$
      .subscribe(geojson => {
        this.geojson = geojson;
        this.observationForm.value.geometry = geojson.geometry;
      });

  }

  addOccurence(){
    // add an occurrence
    this.fs.addOccurence(this.occurrenceForm, this.observationForm, this.countingForm);
    // reset the occurence
    this.occurrenceForm = this.fs.initOccurrenceForm();
    //reset the counting
    this.countingForm = this.fs.initCountingArray()

    // push the current taxon in the taxon list and refresh the currentTaxon
    this.taxonsList.push(this.fs.currentTaxon);
    this.fs.currentTaxon = {};
  }

  submitData() {
    // resert the forms
    this.observationForm = this.fs.initObservationForm();
    this.occurrenceForm = this.fs.initOccurrenceForm();
    this.countingForm = this.fs.initCountingArray();
  }

  ngOnDestroy(){
    this.geojsonSubscription.unsubscribe();
  }

}
