#!/bin/sh
# Amorçage de l'installation de GeoNature :
#
#   curl -LsSf https://raw.githubusercontent.com/PnX-SI/GeoNature/X.Y.Z/install/get-geonature.sh | sh
#
# Ce script clone le dépôt, prépare install/install.toml (questions interactives) puis vérifie les prérequis. Toute la logique
# d'installation est dans install/install.py (Python) : ce fichier ne fait que l'amener sur la machine.
#
# Les principaux paramètres sont demandés dans le terminal (GEONATURE_NO_PROMPT=1 pour les ignorer).
#
# Le clone est superficiel (--depth 1) : seul le commit de la version est téléchargé.
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

    # couleurs seulement sur un terminal (la sortie standard reste le terminal même avec `curl | sh`)
    if [ -t 1 ]; then
        bold='\033[1m'; gray='\033[90m'; red='\033[31m'; green='\033[32m'; cyan='\033[36m'; off='\033[0m'
        rocket='🚀 '; box='📦 '
    else
        bold=''; gray=''; red=''; green=''; cyan=''; off=''; rocket=''; box=''
    fi
    say() { printf '%s\n' "$*"; }
    title() { printf '%b%s%s%b\n' "$bold" "$1" "$2" "$off"; }
    die() { printf '%b✘ Erreur : %s%b\n' "$red" "$*" "$off" >&2; exit 1; }
    have() { command -v "$1" >/dev/null 2>&1; }

    [ "$(id -u)" -ne 0 ] || die "ne lancez pas ce script en root (utilisez l'utilisateur dédié, avec sudo)."
    [ ! -e "$dir" ] || die "$dir existe déjà. Pour mettre à jour : cd $dir && python3 install/install.py update X.Y.Z"

    # Prérequis minimaux pour récupérer le code et lancer l'installateur
    missing=""
    have git || missing="$missing git"
    have python3 || missing="$missing python3"
    if [ -n "$missing" ]; then
        have apt-get || die "installez :$missing"
        title "$box" "Installation de :$missing"
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

    title "$rocket" "Récupération de GeoNature $version dans $dir"
    git clone --quiet --depth 1 --branch "$version" "$repo" "$dir" || die "échec du clonage ($repo, $version)."
    # certains sous-modules imbriqués ont une URL SSH : réécrite en HTTPS (sans clé GitHub, le clonage échouerait)
    git -C "$dir" -c url.https://github.com/.insteadOf=git@github.com: \
        submodule update --init --recursive --depth 1 --quiet || die "échec de la récupération des sous-modules."

    if [ ! -f "$dir/install/install.toml" ]; then
        cp "$dir/install/install.sample.toml" "$dir/install/install.toml"
        chmod 600 "$dir/install/install.toml"
    fi

    # `curl | sh` occupe l'entrée standard : les questions passent par le terminal (/dev/tty).
    configured=0
    if [ -z "${GEONATURE_NO_PROMPT:-}" ] && [ -r /dev/tty ] && [ -w /dev/tty ]; then
        say ""
        python3 "$dir/install/install.py" --configure --config "$dir/install/install.toml" \
            </dev/tty && configured=1
    fi

    say ""
    title "" "Vérification des prérequis…"
    precheck=0
    python3 "$dir/install/install.py" --check --config "$dir/install/install.toml" || precheck=$?

    say ""
    printf '%b✔ Prêt.%b\n' "$green" "$off"
    title "" "Étapes suivantes :"
    step=1
    if [ "$configured" -eq 0 ]; then
        printf '  %s. Adaptez la configuration :  %bnano %s/install/install.toml%b   %b(au minimum my_url)%b\n' "$step" "$cyan" "$dir" "$off" "$gray" "$off"
        step=$((step + 1))
    fi
    if [ "$precheck" -ne 0 ]; then
        say "  $step. Corrigez les prérequis signalés ci-dessus"
        step=$((step + 1))
    fi
    printf "  %s. Lancez l'installation :  %bpython3 %s/install/install.py --config %s/install/install.toml%b\n" "$step" "$cyan" "$dir" "$dir" "$off"
}

main "$@"
