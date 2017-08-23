import { Injectable } from '@angular/core';
import { HttpModule } from '@angular/http';

@Injectable()
export class FormService {
  taxonomy: any;
  constructor(private _http: HttpModule,) {
    this.taxonomy = [
      {
        cd_nom: 5422,
        taxonName: 'Abietinella abietina (Hedw.) M.Fleisch.',
        groupe2INPN: 'Algues'
      },
      {
        cd_nom: 1111,
        taxonName: 'Geotriton fuscus Bonaparte, 1837',
        groupe2INPN: 'Amphibiens'
      },
        {
        cd_nom: 2222,
        taxonName: 'Hemitriton asper Dugès, 1852',
        groupe2INPN: 'Amphibiens'
      }
    ];
  }

  getNomenclature(id_nomenclature:number, regne?:string, group2_inpn?:string){
    // const params = {id: id_nomenclature, regne: regne, group2_inpn:group2_inpn};
    // if (regne){
    //   params.regne = regne
    // };
    // if (group2_inpn){
    //   params.group2_inpn = group2_inpn
    // }
    // return this._http.get(`${AppSetting.API_ENDPOINT}/nomenclatures/`, params)
    //   .subscribe(response=>{
    //     console.log(response.data)
    //      return response.data;
    //   })
    return [{'id':1, 'name': 'lala' }, {'id':2, 'name': 'lolo' }, {'id':3, 'name': 'toto' } ]
  }

  getTaxonomy () {
    return this.taxonomy;
  }

}
