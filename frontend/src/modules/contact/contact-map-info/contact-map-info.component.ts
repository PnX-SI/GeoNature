import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Subscription } from 'rxjs/Subscription';
import { ContactFormService } from '../contact-map-form/form/contact-form.service';
import { MapService } from '../../../core/GN2Common/map/map.service';
import { DataFormService } from '../../../core/GN2Common/form/data-form.service';
import { FormGroup, FormArray } from '@angular/forms';
import { ContactService } from '../services/contact.service';
import { ContactConfig } from '../contact.config';

@Component({
  selector: 'pnx-contact-map-info',
  templateUrl: 'contact-map-info.component.html',
  styleUrls: ['./contact-map-info.component.scss'],

})

export class ContactMapInfoComponent implements OnInit {
  private _sub: Subscription;
  public id: number;
  public releve: any;
  public observers: any;
  public selectedOccurrence: any;
  public occurrenceForm: FormGroup;
  public countingFormArray: FormArray;
  public disabled = true;
  public selectedIndex: number;
  public municipalities: string;
  public dateMin: string;
  public dateMax: string;
  public showSpinner = true;
  public geojson: any;
  constructor(public fs: ContactFormService, private _route: ActivatedRoute, private _ms: MapService,
    private _dfs: DataFormService, private _router: Router,
    private _contactService: ContactService) { }

  ngOnInit() {
    // init forms
    this.occurrenceForm = this.fs.initOccurrenceForm();
    // load nomenclatures
    this.loadNomenclaturesOccurrence();

    this._sub = this._route.params.subscribe(params => {
      this.id = +params['id'];
      if (!isNaN(this.id )) {
        // load one releve
        this._contactService.getReleve(this.id)
          .subscribe(data => {
            this.releve = data;
            if (!ContactConfig.observers_txt) {
              this.observers = data.properties.observers.map(obs => obs.nom_role + ' ' + obs.prenom_role).join(', ');
            }else {
              this.observers = data.properties.observers_txt;
            }
            this.dateMin = data.properties.date_min.substring(0, 10);
            this.dateMax = data.properties.date_max.substring(0, 10);

            this._ms.loadGeometryReleve(data, false);

            // load taxonomy info
            data.properties.t_occurrences_contact.forEach(occ => {
              this._dfs.getTaxonInfo(occ.cd_nom)
                .subscribe(taxon => {
                  occ['taxon'] = taxon;
                  this.showSpinner = false;
                 });
            });
        });
      }
  });
  }



  selectOccurrence(occ, index) {
    this.selectedIndex = index;
    this.selectedOccurrence = occ;
    this.occurrenceForm.patchValue(occ);
    this.countingFormArray = this.fs.initCountingArray(occ.cor_counting_contact);
    console.log(this.countingFormArray);
    
  }

  loadNomenclaturesOccurrence() {
    const arrayNomenclatures = [100, 14, 7, 13, 8, 101, 15];
    this._dfs.getNomenclatures(arrayNomenclatures)
      .subscribe(data => {
        console.log(data);
      });
  }
}
