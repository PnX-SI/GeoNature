import { Component, Input } from '@angular/core';

// ////////////////////////////////////////////////////////////////////////////
// helper method
// ////////////////////////////////////////////////////////////////////////////

function isHexadecimalColor(color: string) {
  return /^#[0-9A-F]{6}$/i.test(color);
}

function computeContrastColor(backgroundColor: string) {
  // Convertir la couleur en un format RGB
  const r = parseInt(backgroundColor.slice(1, 3), 16);
  const g = parseInt(backgroundColor.slice(3, 5), 16);
  const b = parseInt(backgroundColor.slice(5, 7), 16);

  // Calculer la luminosité
  const luminance = 0.299 * r + 0.587 * g + 0.114 * b;

  // Retourner une couleur claire ou foncée selon la luminosité
  return luminance < 128 ? '#ffffff' : '#444';
}

function colorToCSS(color: string) {
  return `--badgeColor: ${color}; --textColor: ${computeContrastColor(color)};`;
}

// ////////////////////////////////////////////////////////////////////////////
// Badge parameters
// ////////////////////////////////////////////////////////////////////////////

export interface BadgeSymbology {
  color?: string;
}

// ////////////////////////////////////////////////////////////////////////////
// helper method
// ////////////////////////////////////////////////////////////////////////////

@Component({
  selector: 'gn-badge',
  templateUrl: 'badge.component.html',
  styleUrls: ['badge.component.scss'],
})
export class BadgeComponent {
  @Input()
  text: string;

  @Input()
  tooltip: string;

  symbologyAsCSS: string;

  @Input()
  set symbology(symbology: BadgeSymbology | null) {
    this.symbologyAsCSS = '';
    if (!symbology) {
      return;
    }
    if (!isHexadecimalColor(symbology.color)) {
      console.warn(`[badge] ${symbology.color} is not a valid hexadecimal color`);
      return;
    }
    this.symbologyAsCSS = colorToCSS(symbology.color);
  }
}
