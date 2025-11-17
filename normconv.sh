#!/bin/bash
# wav_to_mp3_ou_ogg.sh – Version ultime 17 novembre 2025
clear
echo "╔══════════════════════════════════════════════════════════════╗"
echo "           Convertisseur WAV → MP3 ou OGG Vorbis 2025          "
echo "╚══════════════════════════════════════════════════════════════╝"
echo

# 1. Dossier source
read -p "Dossier contenant les .wav (Entrée = dossier courant) : " src_dir
[[ -z "$src_dir" ]] && src_dir="."
src_dir="$(cd "$src_dir" && pwd)"
[[ ! -d "$src_dir" ]] && { echo "Dossier inexistant !"; exit 1; }

# 2. Niveau peak cible
read -p "Niveau peak cible en dB (ex: 0.0  -0.1  -0.3  -1.0) [0.0] : " peak_db
[[ -z "$peak_db" ]] && peak_db="0.0"

# 3. MP3 ou OGG Vorbis ?
while true; do
    echo
    echo "Format de sortie :"
    echo "  1) MP3 (libmp3lame – VBR)"
    echo "  2) OGG Vorbis"
    read -p "Choix (1 ou 2) [1] : " format
    [[ -z "$format" ]] && format=1
    case $format in
        1) codec="mp3"; break;;
        2) codec="ogg"; break;;
        *) echo "1 ou 2 stp";;
    esac
done

# 4. Choix de la qualité avec tableau
if [[ "$codec" == "mp3" ]]; then
    echo
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                   Qualité MP3 VBR (-q:a)                 ║"
    echo "╠══════╦══════════════╦═══════════════════════════════════╣"
    echo "║ Valeur ║ Bitrate moyen ║ Commentaire                      ║"
    echo "╠══════╬══════════════╬═══════════════════════════════════╣"
    echo "║ 0    ║ 220–260 kbps ║ Quasi-transparent (fichiers gros) ║"
    echo "║ 1    ║ 200–240 kbps ║ Excellent (mon choix 2025)        ║"
    echo "║ 2    ║ 170–210 kbps ║ Très bon compromis               ║"
    echo "║ 3    ║ 150–190 kbps ║ Bon                              ║"
    echo "║ 4    ║ 130–170 kbps ║ Acceptable                       ║"
    echo "╚══════╩══════════════╩═══════════════════════════════════╝"
    read -p "Qualité MP3 (-q:a 0-4) [1] : " qual
    [[ -z "$qual" ]] && qual=1
    encoding="-c:a libmp3lame -q:a $qual"
    suffix="MP3_V$qual"

else
    echo
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "                   Qualité OGG Vorbis (-q:a)              "
    echo "╠══════╦══════════════╦═══════════════════════════════════╣"
    echo "║ Valeur ║ Bitrate moyen ║ Commentaire                      ║"
    echo "╠══════╬══════════════╬═══════════════════════════════════╣"
    echo "║ 5    ║ ~160 kbps    ║ Très bon                         ║"
    echo "║ 6    ║ ~192 kbps    ║ Excellent                        ║"
    echo "║ 7    ║ ~224 kbps    ║ Superbe                          ║"
    echo "║ 8    ║ ~256 kbps    ║ Quasi-transparent                ║"
    echo "║ 10   ║ ~400+ kbps   ║ Overkill total                   ║"
    echo "╚══════╩══════════════╩═══════════════════════════════════╝"
    read -p "Qualité OGG Vorbis (-q:a 0-10) [7] : " qual
    [[ -z "$qual" ]] && qual=7
    encoding="-c:a libvorbis -q:a $qual"
    suffix="OGG_Vorbis_q$qual"
fi

# 5. Dossier de sortie
parent="$(dirname "$src_dir")"
name="$(basename "$src_dir")"
dest_dir="${parent}/${name}_${suffix}_peak${peak_db//./,}dB"
mkdir -p "$dest_dir"

# Résumé
clear
echo "╔══════════════════════════════════════════════════════════════╗"
echo "                        RÉCAPITULATIF                           "
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║ Source       : $src_dir"
echo "║ Destination  : $dest_dir"
echo "║ Peak cible   : $peak_db dB"
echo "║ Format       : $codec  →  $suffix"
echo "╚══════════════════════════════════════════════════════════════╝"
read -p "Lancer la conversion ? (Entrée = oui  /  n = non) " go
[[ "$go" == "n" || "$go" == "N" ]] && exit 0

# Conversion
compteur=0
echo
for f in "$src_dir"/*.wav "$src_dir"/*.WAV; do
    [[ -f "$f" ]] || continue
    base="$(basename "$f" | sed 's/\.[Ww][Aa][Vv]$//')"
    if [[ "$codec" == "mp3" ]]; then
        ext="mp3"
    else
        ext="ogg"
    fi
    output="$dest_dir/${base}.$ext"

    echo "→ $base"

    ffmpeg -hide_banner -loglevel error -i "$f" \
           -af "acompressor=threshold=-0.1dB:ratio=20:1:attack=5:release=50,volume=${peak_db}dB" \
           $encoding \
           "$output"

    [[ $? -eq 0 ]] && echo "   ✔ $(basename "$output")" || echo "   ✘ Erreur"
    ((compteur++))
done

echo
echo "╔══════════════════════════════════════════════════════════════╗"
echo "                   TERMINÉ ! $compteur fichier(s) traité(s)            "
echo "           Dossier → $dest_dir            "
echo "╚══════════════════════════════════════════════════════════════╝"
