#!/bin/sh
# Amorçage de l'installation de GeoNature :
#
#   curl -LsSf https://raw.githubusercontent.com/PnX-SI/GeoNature/X.Y.Z/install/get-geonature.sh | sh
#
# Ce script clone le dépôt, prépare install/install.toml puis vérifie les prérequis. Toute la logique
# d'installation est dans install/install.py (Python) : ce fichier ne fait que l'amener sur la machine.
#
# Variables : GEONATURE_VERSION (tag ou branche, défaut : dernière version stable),
#             GEONATURE_DIR (défaut : ~/geonature), GEONATURE_REPO (défaut : le dépôt GitHub).
#
# Tout le code est dans main(), appelée à la dernière ligne : un téléchargement tronqué n'exécute rien.

main() {
    set -eu

    repo="${GEONATURE_REPO:-https://github.com/PnX-SI/GeoNature}"
    dir="${GEONATURE_DIR:-$HOME/geonature}"
    version="${GEONATURE_VERSION:-}"

    say() { printf '%s\n' "$*"; }
    die() { printf 'Erreur : %s\n' "$*" >&2; exit 1; }
    have() { command -v "$1" >/dev/null 2>&1; }

    [ "$(id -u)" -ne 0 ] || die "ne lancez pas ce script en root (utilisez l'utilisateur dédié, avec sudo)."
    [ ! -e "$dir" ] || die "$dir existe déjà. Pour mettre à jour : cd $dir && python3 install/install.py update X.Y.Z"

    # Prérequis minimaux pour récupérer le code et lancer l'installateur
    missing=""
    have git || missing="$missing git"
    have python3 || missing="$missing python3"
    if [ -n "$missing" ]; then
        have apt-get || die "installez :$missing"
        say "Installation de :$missing"
        sudo apt-get install -y $missing
    fi
    python3 -c 'import sys; sys.exit(sys.version_info < (3, 11))' \
        || die "Python 3.11 ou plus est requis pour lancer l'installateur ($(python3 --version 2>&1))."

    if [ -z "$version" ]; then
        # dernière version stable : tags numériques X.Y.Z, sans suffixe (rc, beta…)
        version="$(git ls-remote --tags --refs --sort=-v:refname "$repo" 'refs/tags/*' \
            | sed 's|.*refs/tags/||' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | head -n 1)"
        [ -n "$version" ] || die "impossible de déterminer la dernière version de $repo."
    fi

    say "Récupération de GeoNature $version dans $dir"
    git clone --quiet --branch "$version" "$repo" "$dir" || die "échec du clonage ($repo, $version)."
    # certains sous-modules imbriqués ont une URL SSH : réécrite en HTTPS (sans clé GitHub, le clonage échouerait)
    git -C "$dir" -c url.https://github.com/.insteadOf=git@github.com: \
        submodule update --init --recursive --quiet || die "échec de la récupération des sous-modules."

    if [ ! -f "$dir/install/install.toml" ]; then
        cp "$dir/install/install.sample.toml" "$dir/install/install.toml"
        chmod 600 "$dir/install/install.toml"
    fi

    say ""
    say "Vérification des prérequis…"
    precheck=0
    python3 "$dir/install/install.py" --check --config "$dir/install/install.toml" || precheck=$?

    say ""
    say "Étapes suivantes :"
    say "  1. Adaptez la configuration :  nano $dir/install/install.toml   (au minimum my_url)"
    step=2
    if [ "$precheck" -ne 0 ]; then
        say "  2. Corrigez les prérequis signalés ci-dessus"
        step=3
    fi
    say "  $step. Lancez l'installation :  python3 $dir/install/install.py --config $dir/install/install.toml"
}

main "$@"
