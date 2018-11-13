import { Injectable } from '@angular/core';
import { DataService } from '@geonature_common/service/data.service';
import { ModuleConfig } from "../module.config";
import { AppConfig } from "@geonature_config/app.config";

@Injectable()
export class OcctaxStoreService {
    public userCruved: any;

    constructor(private _api: DataService) {
        if (! this.userCruved) {
            this._api.getCruvedForUserInApp(ModuleConfig.ID_MODULE, AppConfig.ID_APPLICATION_GEONATURE)
            .subscribe(data => {
                this.userCruved = data;
                return data;
            })
         }
         else {
             return this.userCruved;
         }
    }
}