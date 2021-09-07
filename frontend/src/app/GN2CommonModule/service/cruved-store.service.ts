import { Injectable } from '@angular/core';
import { DataFormService } from '@geonature_common/form/data-form.service';

import { from, Observable, of } from 'rxjs';
import {map, startWith} from "rxjs/operators";

import { ModuleService } from "@geonature/services/module.service"

@Injectable()
export class CruvedStoreService {
  public cruved: any = {};

  constructor(private _moduleService: ModuleService) {
    this.fetchCruved().subscribe(cruved => this.cruved = cruved);
   }

  fetchCruved(){
      // The cruved service is deprecated (doublon of moduleService which provice cruved)
      // for retrocompat, it return the modules from modules service      
       this._moduleService.modules.forEach(mod => {
          this.cruved[mod.module_code] = mod;     
        });        
      return of(this.cruved);
    
  }

  clearCruved(): void {
    this.cruved = null;
  }
}
