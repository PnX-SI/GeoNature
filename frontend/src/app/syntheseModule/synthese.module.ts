import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Routes, RouterModule } from '@angular/router';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { SyntheseComponent } from './synthese.component';
import { SyntheseListComponent } from './synthese-results/synthese-list/synthese-list.component';
import { SyntheseCarteComponent } from './synthese-results/synthese-carte/synthese-carte.component';
import { SyntheseSearchComponent } from './synthese-search/synthese-search.component';
import { SearchService } from './search.service';

const routes: Routes = [
    { path: '', component: SyntheseComponent }
];

@NgModule({
    imports: [
        RouterModule.forChild(routes),
        GN2CommonModule,
        CommonModule
    ],
    declarations: [
        SyntheseComponent,
        SyntheseListComponent,
        SyntheseCarteComponent,
        SyntheseSearchComponent
    ],
    providers: [
        SearchService
    ]
})
export class SyntheseModule {
}