import { DatasetsComponent } from "./datasets.component"
import {
    IterableDiffers,
} from '@angular/core';
import { DataFormService } from "../data-form.service";
import { EMPTY, Observable, from } from 'rxjs';
import * as gerard from '../../GN2Common.module';
import { UntypedFormControl } from "@angular/forms";
export class DataFormServiceMock {

    constructor() { }
    getDatasets(params, queryStrings = {}, fields = []) {
        console.log("pouet")
        return from([{ dataset_name: "test" }])
    }
}

describe("Dataset Component", () => {
    it("show component", () => {
        cy.mount(DatasetsComponent, {
            componentProperties: {
                idAcquisitionFramework: 0,
                displayOnlyActive: true,
                parentFormControl: new UntypedFormControl()
            },
            imports: [],
            declarations: [DatasetsComponent],
            providers: [
                IterableDiffers,
                { provide: DataFormService, useClass: DataFormServiceMock }
            ]
        })
    })
})