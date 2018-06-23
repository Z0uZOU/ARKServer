#!/usr/bin/env bash

version="0.0.0.1"

#### Nettoyage
if [[ -f "~/arkserver-update.sh" ]]; then
  rm $HOME/arkserver-update.sh
fi

#### Vérification des dépendances
if [[ ! -f "/bin/wget" ]] && [[ ! -f "/usr/bin/wget" ]]; then wget_missing="1"; fi
if [[ "$wget_missing" == "1" ]]; then
  echo " Erreur(s)"
  echo "---"
  if [[ "$wget_missing" == "1" ]]; then echo -e "\e[1mDépendance manquante      :\e[0m sudo apt-get install wget | ansi=true font='Ubuntu Mono'"; fi
  echo "---"
  echo "Rafraichir | refresh=true"
  exit 1
fi

#### Création du dossier de notre extension (si il n'existe pas)
if [[ ! -d "$HOME/.config/argos/arkserver" ]]; then
  mkdir -p $HOME/.config/argos/arkserver
fi

#### Récupération des versions (locale et distante)
script_github="https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/arkserver.c.1m.sh"
local_version=$version
github_version=`wget -O- -q "$script_github" | grep "^version=" | sed '/grep/d' | sed 's/.*version="//' | sed 's/".*//'`

#### Comparaison des version et mise à jour si nécessaire
vercomp () {
  if [[ $1 == $2 ]]
  then
    return 0
  fi
  local IFS=.
  local i ver1=($1) ver2=($2)
  for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
  do
    ver1[i]=0
  done
  for ((i=0; i<${#ver1[@]}; i++))
  do
    if [[ -z ${ver2[i]} ]]
    then
      ver2[i]=0
    fi
    if ((10#${ver1[i]} > 10#${ver2[i]}))
    then
      return 1
    fi
    if ((10#${ver1[i]} < 10#${ver2[i]}))
    then
      return 2
    fi
  done
  return 0
}
testvercomp () {
  vercomp $1 $2
  case $? in
    0) op='=';;
    1) op='>';;
    2) op='<';;
  esac
  if [[ $op != $3 ]]
  then
    echo "FAIL: Expected '$3', Actual '$op', Arg1 '$1', Arg2 '$2'"
  else
    echo "Pass: '$1 $op $2'"
  fi
}
compare=`testvercomp $local_version $github_version '<' | grep Pass`
if [[ "$compare" != "" ]] ; then
  update_required="Mise à jour disponible"
  (
  echo "0"
  echo "# Creation de l'updater." ; sleep 2
  touch ~/arkserver-update.sh
  echo "25"
  echo "# Chmod de l'updater." ; sleep 2
  chmod +x ~/arkserver-update.sh
  echo "50"
  echo "# Edition de l'updater." ; sleep 2
  echo "#!/bin/bash" > ~/arkserver-update.sh
  echo "(" >> ~/arkserver-update.sh
  echo "echo \"75\"" >> ~/arkserver-update.sh
  echo "echo \"# Mise à jour en cours.\" ; sleep 2" >> ~/arkserver-update.sh
  echo "curl -o ~/.config/argos/arkserver.c.1m.sh $script_github" >> ~/arkserver-update.sh
  echo "sed -i -e 's/\r//g' ~/.config/argos/arkserver.c.1s.sh" >> ~/arkserver-update.sh
  echo "echo \"100\"" >> ~/arkserver-update.sh
  echo ") |" >> ~/arkserver-update.sh
  echo "yad --undecorated --width=500 --progress --center --no-buttons --no-escape --skip-taskbar --image=\"$HOME/.config/argos/.cache-icons/updater.png\" --text-align=\"center\" --text=\"\rUne mise à jour de <b>arkserver.c.1m.sh</b> a été detectée.\r\rVersion locale: <b>$local_version</b>\rVersion distante: <b>$github_version</b>\r\r<b>Installation de la mise à jour...</b>\r\" --auto-kill --auto-close" >> ~/arkserver-update.sh  echo "75"
  echo "# Lancement de l'updater." ; sleep 2
  bash ~/arkserver-update.sh
  exit 1
) |
yad --undecorated --width=500 --progress --center --no-buttons --no-escape --skip-taskbar --image="$HOME/.config/argos/.cache-icons/updater.png" --text-align="center" --text="\rUne mise à jour de <b>arkserver.c.1m.sh</b> a été detectée.\r\rVersion locale: <b>$local_version</b>\rVersion distante: <b>$github_version</b>\r\r<b>Installation de la mise à jour...</b>\r" --auto-kill --auto-close
fi

#### Vérification du cache des icones (ou création)
icons_cache=`echo $HOME/.config/argos/.cache-icons`
if [[ ! -f "$icons_cache" ]]; then
  mkdir -p $icons_cache
fi
if [[ ! -f "$icons_cache/updater.png" ]] ; then curl -o "$icons_cache/updater.png" "https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/.cache-icons/updater.png" ; fi
if [[ ! -f "$icons_cache/ARK.png" ]] ; then curl -o "$icons_cache/ARK.png" "https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/.cache-icons/ARK.png" ; fi
if [[ ! -f "$icons_cache/ARK-SE.png" ]] ; then curl -o "$icons_cache/ARK-SE.png" "https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/.cache-icons/ARK-SE.png" ; fi
if [[ ! -f "$icons_cache/ARK-Ab.png" ]] ; then curl -o "$icons_cache/ARK-Ab.png" "https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/.cache-icons/ARK-Ab.png" ; fi
if [[ ! -f "$icons_cache/TS.png" ]] ; then curl -o "$icons_cache/TS.png" "https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/.cache-icons/TS.png" ; fi

#### Mise en variable des icones
ARKSERVR_ARK=$(curl -s "file://$icons_cache/ARK.png" | base64 -w 0)
ARKSERVR_ARK-SE=$(curl -s "file://$icons_cache/ARK-SE.png" | base64 -w 0)
ARKSERVR_ARK-Ab=$(curl -s "file://$icons_cache/ARK-Ab.png" | base64 -w 0)
ARKSERVR_TS=$(curl -s "file://$icons_cache/TS.png" | base64 -w 0)

#### Fonction: dehumanize
dehumanise() {
  for v in "$@"
  do  
    echo $v | awk \
      'BEGIN{IGNORECASE = 1}
       function printpower(n,b,p) {printf "%u\n", n*b^p; next}
       /[0-9]$/{print $1;next};
       /K(iB)?$/{printpower($1,  2, 10)};
       /M(iB)?$/{printpower($1,  2, 20)};
       /G(iB)?$/{printpower($1,  2, 30)};
       /T(iB)?$/{printpower($1,  2, 40)};
       /KB$/{    printpower($1, 10,  3)};
       /MB$/{    printpower($1, 10,  6)};
       /GB$/{    printpower($1, 10,  9)};
       /TB$/{    printpower($1, 10, 12)}'
  done
}

#### Fonction: humanize
humanise() {
  b=${1:-0}; d=''; s=0; S=(Bytes {K,M,G,T,E,P,Y,Z}o)
  while ((b > 1024)); do
    d="$(printf ".%02d" $((b % 1000 * 100 / 1000)))"
    b=$((b / 1000))
    let s++
  done
  echo "$b$d ${S[$s]}"
}

