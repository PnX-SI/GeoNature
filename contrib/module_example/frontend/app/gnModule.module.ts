import { NgModule } from "@angular/core";
import { GN2CommonModule } from "@geonature_common/GN2Common.module";
import { Routes, RouterModule } from "@angular/router";
import { TestComponent } from "./components/test.component";

// my module routing
const routes: Routes = [{ path: "", component: TestComponent }];

@NgModule({
  declarations: [TestComponent],
  imports: [GN2CommonModule, RouterModule.forChild(routes)],
  providers: [],
  bootstrap: []
})
export class GeonatureModule {}
