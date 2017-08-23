import { Injectable } from '@angular/core';

@Injectable()
export class FormService {

  constructor() { }

  getNomenclature(id_nomenclature:number, regne:string, group2_inpn:string){
    return [{'id':1, 'name': 'lala' }, {'id':2, 'name': 'lolo' }, {'id':3, 'name': 'toto' } ]
  }

}
