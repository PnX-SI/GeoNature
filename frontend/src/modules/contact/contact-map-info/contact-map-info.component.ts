import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Subscription } from 'rxjs/Subscription';
import { ContactFormService } from '../contact-map-form/form/contact-form.service';
import { MapService } from '../../../core/GN2Common/map/map.service';
import { DataFormService } from '../../../core/GN2Common/form/data-form.service';
import { FormGroup, FormArray } from '@angular/forms';

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
  constructor(private _cfs: ContactFormService, private _route: ActivatedRoute, private _ms: MapService,
    private _dfs: DataFormService, private _router: Router) { }

  ngOnInit() {
    this._sub = this._route.params.subscribe(params => {
      this.id = +params['id'];
      if (!isNaN(this.id )) {
        // load one releve
        this._cfs.getReleve(this.id)
          .subscribe(data => {
            this.releve = data;
            this.observers = data.properties.observers.map(obs => obs.nom_role + ' ' + obs.prenom_role).join(', ');
            this.municipalities = data.properties.municipalities.map(muni => muni.area_name).join(', ');
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

            console.log(data.properties);

        });
      }
  });
  }

  onEditReleve(id) {
    this._router.navigate(['contact-form', id]);
  }
  backToList() {
    this._router.navigate(['contact']);
  }

  selectOccurrence(occ, index) {
    this.selectedIndex = index;
    this.selectedOccurrence = occ;
    this.loadNomenclaturesOccurrence();
    this.occurrenceForm = this._cfs.initOccurrenceForm(occ);
    this.countingFormArray = this._cfs.initCountingArray(occ.cor_counting_contact);
  }

  loadNomenclaturesOccurrence() {
    const arrayNomenclatures = [100, 14, 7, 13, 8, 101, 15];
    this._dfs.getNomenclatures(arrayNomenclatures)
      .subscribe(data => {
        console.log(data);
      });
  }
}
