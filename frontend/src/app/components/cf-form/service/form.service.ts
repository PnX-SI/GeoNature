import { Injectable } from '@angular/core';
import { HttpModule } from '@angular/http';

@Injectable()
export class FormService {

  constructor(private _http: HttpModule) { }

  getNomenclature(id_nomenclature:number, regne:string, group2_inpn:string){
    // let params = {id: id_nomenclature, regne: regne, group2_inpn:group2_inpn};
    // this._http.get(`${baseUrl}/nomenclature/${id_nomenclature}`, params)
    //   .subscribe(response=>{
    //     console.log(response.data)
    //   })
    return [{'id':1, 'name': 'lala' }, {'id':2, 'name': 'lolo' }, {'id':3, 'name': 'toto' } ]
  }

}
