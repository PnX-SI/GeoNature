import { Component, OnInit, Input, ViewChild } from '@angular/core';
import { FormArray, FormBuilder, Validators } from '@angular/forms';
import { MatTable } from '@angular/material/table';
import { DataFormService } from '@geonature_common/form/data-form.service';

interface IStrate {
    id_vegetation_stratum: number | null;
    id_nomenclature_vegetation_stratum?: number;
    percentage_cover_vegetation_stratum: number | null;
    average_height: number | null;
    min_height: number | null;
    max_height: number | null;
}

@Component({
    selector: 'phyto-vegetation-stratum',
    templateUrl: './strate.component.html',
    styleUrls: ['./strate.component.scss']
})
export class PhytoStratumComponent implements OnInit {
    @ViewChild('strateTable', { static: true }) table: MatTable<any>;
    @Input() parentFormControl: FormArray;

    stratesLabels: { [index: string]: string } = {};
    displayedColumns: string[] = [
        'label_default',
        'percentage_cover_vegetation_stratum',
        'average_height',
        'min_height',
        'max_height'
    ];

    constructor(
        private fb: FormBuilder,
        private dataFormS: DataFormService
    ) { }

    ngOnInit(): void {
        this.loadStrateTable();
        this.parentFormControl.valueChanges.subscribe(() => {
            this.loadStrateTable();
        });
    }

    loadStrateTable() {
        this.dataFormS.getNomenclature('STRATE_VEGETATION')
            .subscribe(strateNomenclatures => {
                const backendStrates = (this.parentFormControl.value || []) as IStrate[];

                const strateFormGroups = strateNomenclatures.values.map((strate: any) => {
                    this.stratesLabels[strate.id_nomenclature] = strate.label_default;

                    const currentStrate = backendStrates.find(
                        s => s.id_nomenclature_vegetation_stratum === strate.id_nomenclature
                    ) || { // If not found, create empty strate
                        id_vegetation_stratum: null,
                        id_nomenclature_vegetation_stratum: strate.id_nomenclature,
                        percentage_cover_vegetation_stratum: null,
                        average_height: null,
                        min_height: null,
                        max_height: null
                    };

                    return this.fb.group({
                        id_vegetation_stratum: [currentStrate.id_vegetation_stratum],
                        id_nomenclature_vegetation_stratum: [currentStrate.id_nomenclature_vegetation_stratum],
                        percentage_cover_vegetation_stratum: [currentStrate.percentage_cover_vegetation_stratum, [Validators.min(0), Validators.max(100)]],
                        average_height: [currentStrate.average_height, [Validators.min(0)]],
                        min_height: [currentStrate.min_height, [Validators.min(0)]],
                        max_height: [currentStrate.max_height, [Validators.min(0)]]
                    });
                });

                // Put emitEvent to false to avoid infinite loop, as valueChanges subscription on parentFormControl
                this.parentFormControl.clear({ emitEvent: false });
                strateFormGroups.forEach(strate => this.parentFormControl.push(strate, { emitEvent: false }));
                // 
                this.table.renderRows();
            });
    }
}
