#! /bin/bash
# Renomme une émission TNT enregistrée avec un CGV Etimo 2T
# en modifiant le fichier info3.dvr
# Paramètres: $1 "nom de l'émission" , $2 nom du fichier.dvr
# Paquets nécessaires : jacksum bbe
# Vincent MAGNIN, 31-10-2016
# Article publié dans GLMF (http://www.gnulinuxmag.com/)

# Nombre maximum de caractères dans le titre :
readonly TAILLE=17

# On récupère les arguments :
if [ ${#} -eq 0 ]; then
  echo "utilisation : ${0} \"titre\" [fichier.dvr]"
  exit 1
else
  # On tronque le titre pour avoir 17 caractères maximum :
  titre=${1:0:${TAILLE}}
  # Le fichier par défaut est info3.dvr :
  fichier=${2:-"info3.dvr"}
fi

# Pour obtenir un codage UTF16 et dans un format acceptable par bbe :
octets=$(echo -n "${titre}" | iconv -t utf-16be//TRANSLIT | hexdump -e '"\\\x" 1/1 "%02X" ""')
# On complète avec des octets nuls à la fin pour avoir exactement 34 octets :
i=${#titre}  # Longueur de la chaîne
while [ ${i} -lt ${TAILLE} ]; do
    i=$((i+1))
    octets=${octets}"\x00\x00"
done

# On fait une copie de sauvegarde du fichier .dvr :
cp "${fichier}" "${fichier}.backup"
# On écrit les octets dans le fichier à l'offset 0x2ba6 (11174 en décimal)
# et on efface les quatre derniers octets à l'offset 32764 :
bbe -e "r 11174 ${octets} ; d 32764 4" "${fichier}.backup" -o "${fichier}.tmp"
# On calcule la somme de contrôle Adler32 du fichier temporaire
# et on insère des \x devant chaque octet :
somme=$(jacksum -a adler32 -E hex -F "#CHECKSUM" "${fichier}.tmp" | sed -r 's/(..)/\\x\1/g')
# On ajoute cette somme de contrôle à la fin du fichier temporaire :
bbe -e "A ${somme}" "${fichier}.tmp" -o "${fichier}"

# On fait le ménage :
rm "${fichier}.tmp"
# On stocke le nom complet de l'enregistrement :
echo "${1}" > titre.txt
