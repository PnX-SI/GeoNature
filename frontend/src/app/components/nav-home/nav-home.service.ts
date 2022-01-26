import { Injectable } from '@angular/core';
import { distinctUntilChanged } from 'rxjs/operators';
import { GlobalSubService } from '../../services/global-sub.service';

@Injectable({providedIn: 'root'})
export class NavHomeService {
    public moduleName: string;
    public currentDocUrl: string;
    constructor(private globalSubService: GlobalSubService) { 
        this.onModuleChange()
    }
    
    private onModuleChange() {
        this.globalSubService.currentModuleSub.pipe(
          ).subscribe(module => {
              console.log("MODULE ON REFRESH", module);
                                                          
            this.globalSubService.clearTheme();
            if (module) {
              this.moduleName = module.module_label;
              if (module.module_doc_url) {
                this.currentDocUrl = module.module_doc_url;
              }
              // set theme
              const appRoot = document.getElementById("app-root");
              appRoot.className = "";
              appRoot.classList.add(module.theme);

            } else {
              this.moduleName = 'Accueil';
            }
          })
      }
    
}