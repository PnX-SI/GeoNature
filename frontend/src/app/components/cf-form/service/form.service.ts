import { Injectable } from '@angular/core';
import { HttpModule } from '@angular/http';

@Injectable()
export class FormService {

  constructor(private _http: HttpModule) { }

  getNomenclature(id_nomenclature:number, regne?:string, group2_inpn?:string){
    // const params = {id: id_nomenclature, regne: regne, group2_inpn:group2_inpn};
    // if (regne){
    //   params.regne = regne
    // };
    // if (group2_inpn){
    //   params.group2_inpn = group2_inpn
    // }
    // return this._http.get(`${baseUrl}/nomenclature/${id_nomenclature}`, params)
    //   .subscribe(response=>{
    //     console.log(response.data)
    //      return response.data;
    //   })
    return [{'id':1, 'name': 'lala' }, {'id':2, 'name': 'lolo' }, {'id':3, 'name': 'toto' } ]
  }

}
