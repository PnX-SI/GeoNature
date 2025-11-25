import { Component, Inject, OnInit, OnDestroy } from '@angular/core';
import { UntypedFormBuilder, UntypedFormGroup, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { ActorFormService } from '../services/actor-form.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { Subject } from 'rxjs';
import { takeUntil, debounceTime, distinctUntilChanged } from 'rxjs/operators';

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
    if (!inputName || inputName.trim().length < 3) {
      this.similarOrganisms = [];
      this.showSimilarWarning = false;
      return;
    }

    const normalizedInput = this.normalizeString(inputName);
    const organisms = this.actorFormService.organisms;

    // Filter and calculate distance for each organism
    const organismsWithDistance = organisms
      .map((org) => {
        const normalizedOrgName = this.normalizeString(org.nom_organisme);

        // Check for exact match (case-insensitive)
        if (normalizedOrgName === normalizedInput) {
          return { organism: org, distance: 0 };
        }

        // Check if one contains the other
        if (normalizedOrgName.includes(normalizedInput)) {
          return { organism: org, distance: normalizedOrgName.length - normalizedInput.length };
        }

        if (normalizedInput.includes(normalizedOrgName)) {
          return { organism: org, distance: normalizedInput.length - normalizedOrgName.length };
        }

        // Calculate Levenshtein distance for similar names
        const distance = this.levenshteinDistance(normalizedInput, normalizedOrgName);
        const maxLength = Math.max(normalizedInput.length, normalizedOrgName.length);
        const similarity = 1 - distance / maxLength;

        // Consider similar if similarity is above 70%
        if (similarity > 0.7) {
          return { organism: org, distance: distance };
        }

        return null;
      })
      .filter((item) => item !== null);

    // Sort by distance (ascending - most similar first)
    organismsWithDistance.sort((a, b) => a.distance - b.distance);

    // Extract just the organisms
    this.similarOrganisms = organismsWithDistance.map((item) => item.organism);

    // Reset to first page when results change
    this.currentPage = 0;

    this.showSimilarWarning = this.similarOrganisms.length > 0;
  }

  /**
   * Normalize string for comparison (lowercase, trim, remove extra spaces)
   */
  private normalizeString(str: string): string {
    return str.toLowerCase().trim().replace(/\s+/g, ' ');
  }

  /**
   * Calculate Levenshtein distance between two strings
   */
  private levenshteinDistance(str1: string, str2: string): number {
    const len1 = str1.length;
    const len2 = str2.length;
    const matrix: number[][] = [];

    for (let i = 0; i <= len1; i++) {
      matrix[i] = [i];
    }

    for (let j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    for (let i = 1; i <= len1; i++) {
      for (let j = 1; j <= len2; j++) {
        const cost = str1[i - 1] === str2[j - 1] ? 0 : 1;
        matrix[i][j] = Math.min(
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost // substitution
        );
      }
    }

    return matrix[len1][len2];
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
