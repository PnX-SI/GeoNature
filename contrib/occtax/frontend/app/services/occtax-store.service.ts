import { Injectable } from '@angular/core';
import { ActivatedRoute } from "@angular/router";
import { BehaviorSubject, Observable, of } from "rxjs";
import { GlobalSubService } from '@geonature/services/global-sub.service';


@Injectable({providedIn: 'root'})
export class OcctaxStoreService {
    public moduleDatasetId: BehaviorSubject<number> = new BehaviorSubject(null); // boolean to check if its editionMode
    constructor(private _route: ActivatedRoute, private _globalSub: GlobalSubService ) { 
        this._route.queryParams.subscribe(params => {            
            this._globalSub.currentModuleSubject.next({
                "module_label": params["module_label"]
            })
            let datasetId = params["id_dataset"];
            this.moduleDatasetId.next(datasetId || null);
            
          })
    }
    
}