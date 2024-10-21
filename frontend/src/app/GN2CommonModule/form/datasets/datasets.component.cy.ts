import { DatasetsComponent } from './datasets.component';
import { IterableDiffers } from '@angular/core';
import { DataFormService } from '../data-form.service';
import { from } from 'rxjs';
import { FormControl, FormGroup } from '@angular/forms';
import { NgSelectModule } from '@ng-select/ng-select';
export class DataFormServiceMock {
    constructor() { }
    getDatasets(params, queryStrings = {}, fields = []) {
        return from([{ dataset_name: 'test', id_dataset: 1, id_acquisition_framework: 1 }]);
    }
}

describe('Dataset Component', () => {
    it('show component', () => {
        let p = new FormGroup({
            id_dataset: new FormControl(null),
        });
        cy.mount(DatasetsComponent, {
            componentProperties: {
                parentFormControl: new FormControl(),
                label: 'Jeux de données',
                //multiSelect: true,
                idAcquisitionFramework: 1,
            },
            declarations: [DatasetsComponent],
            providers: [IterableDiffers, { provide: DataFormService, useClass: DataFormServiceMock }],
        });
    });
});
