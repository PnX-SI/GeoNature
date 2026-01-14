import { Component, Inject, OnInit, OnDestroy } from '@angular/core';
import { UntypedFormBuilder, UntypedFormGroup, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { ActorFormService } from '../services/actor-form.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { Subject } from 'rxjs';
import { takeUntil, debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { distance } from 'fastest-levenshtein';

@Component({
  selector: 'pnx-organism-form-dialog',
  templateUrl: './organism-form-dialog.component.html',
  styleUrls: ['./organism-form-dialog.component.scss'],
})
export class OrganismFormDialogComponent implements OnInit, OnDestroy {
  organismForm: UntypedFormGroup;
  private destroy$ = new Subject<void>();
  similarOrganisms: any[] = [];
  showSimilarWarning: boolean = false;
  selectedOrganism: any = null;
  loadingOrganismDetails: boolean = false;

  // Pagination for similar organisms
  currentPage: number = 0;
  pageSize: number = 3;

  get paginatedSimilarOrganisms(): any[] {
    const startIndex = this.currentPage * this.pageSize;
    return this.similarOrganisms.slice(startIndex, startIndex + this.pageSize);
  }

  get totalPages(): number {
    return Math.ceil(this.similarOrganisms.length / this.pageSize);
  }

  get hasPreviousPage(): boolean {
    return this.currentPage > 0;
  }

  get hasNextPage(): boolean {
    return this.currentPage < this.totalPages - 1;
  }

  nextPage(): void {
    if (this.hasNextPage) {
      this.currentPage++;
      this.selectedOrganism = null; // Close any open details when changing page
    }
  }

  previousPage(): void {
    if (this.hasPreviousPage) {
      this.currentPage--;
      this.selectedOrganism = null; // Close any open details when changing page
    }
  }

  // Make Math available in template
  Math = Math;

  constructor(
    public dialogRef: MatDialogRef<OrganismFormDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: any,
    private fb: UntypedFormBuilder,
    private actorFormService: ActorFormService,
    private dataFormService: DataFormService
  ) {
    this.organismForm = this.fb.group({
      nom_organisme: ['', Validators.required],
      adresse_organisme: [''],
      cp_organisme: [''],
      ville_organisme: [''],
      tel_organisme: [''],
      fax_organisme: [''],
      email_organisme: ['', Validators.email],
      url_organisme: [''],
      url_logo: [''],
    });
  }

  ngOnInit(): void {
    // Load saved form values if they exist
    const savedValues = this.actorFormService.getSavedOrganismFormValues();
    if (savedValues) {
      this.organismForm.patchValue(savedValues);
    }

    // Save form values on every change (debounced)
    this.organismForm.valueChanges
      .pipe(takeUntil(this.destroy$), debounceTime(300))
      .subscribe((values) => {
        this.actorFormService.saveOrganismFormValues(values);
      });

    // Check for similar organism names
    this.organismForm
      .get('nom_organisme')
      .valueChanges.pipe(takeUntil(this.destroy$), debounceTime(500), distinctUntilChanged())
      .subscribe((name) => {
        this.checkSimilarNames(name);
      });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  /**
   * Check if the entered name is similar to existing organism names
   */
  checkSimilarNames(inputName: string): void {
    if (!inputName) {
      this.similarOrganisms = [];
      this.showSimilarWarning = false;
      return;
    }

    this.dataFormService.getOrganisms(false, { search: inputName }).subscribe((response) => {
      this.similarOrganisms = response;
      // Reset to first page when results change
      this.currentPage = 0;

      this.showSimilarWarning = this.similarOrganisms.length > 0;
    });
  }

  /**
   * Normalize string for comparison (lowercase, trim, remove extra spaces)
   */
  private normalizeString(str: string): string {
    return str.toLowerCase().trim().replace(/\s+/g, ' ');
  }

  /**
   * View details of a similar organism - fetches complete details from backend
   */
  viewOrganismDetails(organism: any): void {
    // Toggle: if clicking the same organism, collapse it
    if (this.selectedOrganism?.id_organisme === organism.id_organisme) {
      this.selectedOrganism = null;
      return;
    }

    // Fetch complete organism details from backend
    this.loadingOrganismDetails = true;
    this.dataFormService
      .getOrganism(organism.id_organisme)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (fullOrganismData) => {
          this.selectedOrganism = fullOrganismData;
          this.loadingOrganismDetails = false;
        },
        error: (error) => {
          console.error('Error fetching organism details:', error);
          // Fallback to basic data if API fails
          this.selectedOrganism = organism;
          this.loadingOrganismDetails = false;
        },
      });
  }

  /**
   * Check if the selected organism has any additional information beyond the name
   */
  hasAdditionalInfo(): boolean {
    if (!this.selectedOrganism) {
      return false;
    }

    return !!(
      this.selectedOrganism.adresse_organisme ||
      this.selectedOrganism.cp_organisme ||
      this.selectedOrganism.ville_organisme ||
      this.selectedOrganism.tel_organisme ||
      this.selectedOrganism.fax_organisme ||
      this.selectedOrganism.email_organisme ||
      this.selectedOrganism.url_organisme ||
      this.selectedOrganism.url_logo
    );
  }

  onCancel(): void {
    // Don't clear saved values on cancel
    this.dialogRef.close();
  }

  onSubmit(): void {
    if (this.organismForm.valid) {
      // Clear saved values only on successful submit
      this.actorFormService.clearSavedOrganismFormValues();
      this.dialogRef.close(this.organismForm.value);
    }
  }
}
