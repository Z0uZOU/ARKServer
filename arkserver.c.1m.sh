#!/usr/bin/env bash

version="0.0.0.15"


#### Mes paramètres
asterisk=`cat $HOME/.config/argos/.arkserver-parameters | awk '{print $1}' FS="§"`
token_app=`cat $HOME/.config/argos/.arkserver-parameters | awk '{print $2}' FS="§"`
destinataire_1=`cat $HOME/.config/argos/.arkserver-parameters | awk '{print $3}' FS="§"`
destinataire_2=`cat $HOME/.config/argos/.arkserver-parameters | awk '{print $4}' FS="§"`
password_root=`cat $HOME/.config/argos/.arkserver-parameters | awk '{print $5}' FS="§"`
password_serveradmin_TS=`cat $HOME/.config/argos/.arkserver-parameters | awk '{print $6}' FS="§"`
check_users="non"

## Déclaration de ma fonction push
push-message() {
  push_title=$1
  push_content=$2
  for user in {1..10}; do
    destinataire=`eval echo "\\$destinataire_"$user`
    if [ -n "$destinataire" ]; then
      curl -s \
        --form-string "token=$token_app" \
        --form-string "user=$destinataire" \
        --form-string "title=$push_title" \
        --form-string "message=$push_content" \
        --form-string "html=1" \
        --form-string "priority=0" \
        https://api.pushover.net/1/messages.json > /dev/null
    fi
  done
}

#### Nettoyage
if [[ -f "~/arkserver-update.sh" ]]; then
  rm $HOME/arkserver-update.sh
fi

#### Vérification des dépendances
if [[ ! -f "/bin/yad" ]] && [[ ! -f "/usr/bin/yad" ]]; then yad_missing="1"; fi
if [[ ! -f "/bin/curl" ]] && [[ ! -f "/usr/bin/curl" ]]; then curl_missing="1"; fi
if [[ ! -f "/bin/gawk" ]] && [[ ! -f "/usr/bin/gawk" ]]; then gawk_missing="1"; fi
if [[ ! -f "/bin/wget" ]] && [[ ! -f "/usr/bin/wget" ]]; then wget_missing="1"; fi
if [[ ! -f "/bin/grep" ]] && [[ ! -f "/usr/bin/grep" ]]; then grep_missing="1"; fi
if [[ ! -f "/bin/sed" ]] && [[ ! -f "/usr/bin/sed" ]]; then sed_missing="1"; fi
if [[ ! -f "/bin/gcc" ]] && [[ ! -f "/usr/bin/gcc" ]]; then gcc_missing="1"; fi
if [[ "$yad_missing" == "1" ]] || [[ "$curl_missing" == "1" ]] || [[ "$gawk_missing" == "1" ]] || [[ "$wget_missing" == "1" ]] || [[ "$grep_missing" == "1" ]] || [[ "$sed_missing" == "1" ]] || [[ "$gcc_missing" == "1" ]]; then
  echo " Erreur(s)"
  echo "---"
  if [[ "$yad_missing" == "1" ]]; then echo -e "\e[1mDépendance manquante      :\e[0m sudo apt-get install yad | ansi=true font='Ubuntu Mono'"; fi
  if [[ "$curl_missing" == "1" ]]; then echo -e "\e[1mDépendance manquante      :\e[0m sudo apt-get install curl | ansi=true font='Ubuntu Mono'"; fi
  if [[ "$gawk_missing" == "1" ]]; then echo -e "\e[1mDépendance manquante      :\e[0m sudo apt-get install gawk | ansi=true font='Ubuntu Mono'"; fi
  if [[ "$wget_missing" == "1" ]]; then echo -e "\e[1mDépendance manquante      :\e[0m sudo apt-get install wget | ansi=true font='Ubuntu Mono'"; fi
  if [[ "$grep_missing" == "1" ]]; then echo -e "\e[1mDépendance manquante      :\e[0m sudo apt-get install grep | ansi=true font='Ubuntu Mono'"; fi
  if [[ "$sed_missing" == "1" ]]; then echo -e "\e[1mDépendance manquante      :\e[0m sudo apt-get install sed | ansi=true font='Ubuntu Mono'"; fi
  if [[ "$gcc_missing" == "1" ]]; then echo -e "\e[1mDépendance manquante      :\e[0m sudo apt-get install gcc | ansi=true font='Ubuntu Mono'"; fi
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
if [[ ! -f "$icons_cache/ARKServer.png" ]] ; then curl -o "$icons_cache/ARKServer.png" "https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/.cache-icons/ARKServer.png" ; fi
#if [[ ! -f "$icons_cache/ARKServer-big.png" ]] ; then curl -o "$icons_cache/ARKServer-big.png" "https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/.cache-icons/ARKServer-big.png" ; fi
if [[ ! -f "$icons_cache/updater.png" ]] ; then curl -o "$icons_cache/updater.png" "https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/.cache-icons/updater.png" ; fi
if [[ ! -f "$icons_cache/ARK.png" ]] ; then curl -o "$icons_cache/ARK.png" "https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/.cache-icons/ARK.png" ; fi
if [[ ! -f "$icons_cache/ARK-SE.png" ]] ; then curl -o "$icons_cache/ARK-SE.png" "https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/.cache-icons/ARK-SE.png" ; fi
if [[ ! -f "$icons_cache/ARK-Ab.png" ]] ; then curl -o "$icons_cache/ARK-Ab.png" "https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/.cache-icons/ARK-Ab.png" ; fi
if [[ ! -f "$icons_cache/ARK-Ragnarok.png" ]] ; then curl -o "$icons_cache/ARK-Ragnarok.png" "https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/.cache-icons/ARK-Ragnarok.png" ; fi
if [[ ! -f "$icons_cache/ARK-Extinction.png" ]] ; then curl -o "$icons_cache/ARK-Extinction.png" "https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/.cache-icons/ARK-Extinction.png" ; fi
if [[ ! -f "$icons_cache/TS.png" ]] ; then curl -o "$icons_cache/TS.png" "https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/.cache-icons/TS.png" ; fi
if [[ ! -f "$icons_cache/CrossArkChat.png" ]] ; then curl -o "$icons_cache/CrossArkChat.png" "https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/.cache-icons/CrossArkChat.png" ; fi
if [[ ! -f "$icons_cache/settings.png" ]] ; then curl -o "$icons_cache/settings.png" "https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/.cache-icons/settings.png" ; fi
if [[ ! -f "$icons_cache/add.png" ]] ; then curl -o "$icons_cache/add.png" "https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/.cache-icons/add.png" ; fi
if [[ ! -f "$icons_cache/refresh.png" ]] ; then curl -o "$icons_cache/refresh.png" "https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/.cache-icons/refresh.png" ; fi

#### Mise en variable des icones
SERVER_ICON=$(curl -s "file://$icons_cache/ARKServer.png" | base64 -w 0)
#SERVER_ICON_BIG=$(curl -s "file://$icons_cache/ARKServer-big.png" | base64 -w 0)
ARKSERVER_ARK=$(curl -s "file://$icons_cache/ARK.png" | base64 -w 0)
ARKSERVER_ARK_SE=$(curl -s "file://$icons_cache/ARK-SE.png" | base64 -w 0)
ARKSERVER_ARK_Ab=$(curl -s "file://$icons_cache/ARK-Ab.png" | base64 -w 0)
ARKSERVER_ARK_Ragnarok=$(curl -s "file://$icons_cache/ARK-Ragnarok.png" | base64 -w 0)
ARKSERVER_ARK_Extinction=$(curl -s "file://$icons_cache/ARK-Extinction.png" | base64 -w 0)
ARKSERVER_TS=$(curl -s "file://$icons_cache/TS.png" | base64 -w 0)
ARKSERVER_CROSSARKCHAT=$(curl -s "file://$icons_cache/CrossArkChat.png" | base64 -w 0)
SETTINGS_ICON=$(curl -s "file://$icons_cache/settings.png" | base64 -w 0)
ADD_ICON=$(curl -s "file://$icons_cache/add.png" | base64 -w 0)
REFRESH_ICON=$(curl -s "file://$icons_cache/refresh.png" | base64 -w 0)

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

#### emplacement des fichiers temporaire et rcon
cd $HOME/.config/argos/arkserver

#### vérification de la présence de 'rcon'
if [[ ! -f "$HOME/.config/argos/arkserver/rcon" ]] ; then
  wget -q http://www.dopefish.de/files/rcon.c -O $HOME/.config/argos/arkserver/rcon.c > /dev/null
  gcc rcon.c -o rcon > /dev/null
  chmod ugo+rx rcon > /dev/null
  rm rcon.c > /dev/null
fi

#### Recherche de mes process
process_teamspeak=`ps aux | grep "./ts3server" | sed '/grep/d' | awk '{print $2}'`
process_tsbot=`service tsbot status | grep "Main PID" | sed '/grep/d' | awk '{print $3}'`
if [[ "$process_tsbot" == "" ]]; then
  process_tsbot=`service tsbot status | grep "["$'\xe2\x94\x94'"-"$'\xe2\x94\x80'"]" | sed '/grep/d' | awk '{print $1}' | grep -Eo '[0-9]{1,5}'`
fi
process_hackts=`ps aux | grep "./AccountingServerEmulator-Linux" | sed '/grep/d' | awk '{print $2}'`
#process_teamspeak=""
#process_tsbot=""
#process_hackts=""

#### Utilisation CPU et MEM de TS
ts_cpu=`ps -p $process_teamspeak -o %cpu | sed -n '2p' | awk '{print $1}'`
ts_mem=`ps -p $process_teamspeak -o %mem | sed -n '2p' | awk '{print $1}'`

#### Recupération des infos serveur ARK
sh_serveurs=()
map_serveurs=()
sessionname_serveurs=()
ip_serveurs=()
port_serveurs=()
queryport_serveurs=()
rconport_serveurs=()
maxplayers_serveurs=()
modids_serveurs=()
players_serveurs=()
list_players_serveurs=()
crontab_serveurs=()
#server_admin_password_serveurs=()
ip_locale=`hostname -I | cut -d' ' -f1`
ip_distante=`dig -b $ip_locale +short myip.opendns.com @resolver1.opendns.com`
chemin_serveur=`locate \/arkserver | sed '/\/usb_save\//d' | sed '/\/lgsm\//d' | sed '/\/log\//d' | sed '/\/SAUVEGARDE\//d' | sed '/\/.config\/argos\//d' | grep "\/arkserver$" | xargs dirname`
if [[ "$chemin_serveur" != "" ]]; then 
  liste_serveurs=`locate \/arkserver | grep "$chemin_serveur" | sed '/\/usb_save\//d' | sed '/\/lgsm\//d' | sed '/\/log\//d' | sed "s|$chemin_serveur\/||g"`
  arkserver_GameUserSettings=`echo $chemin_serveur"/serverfiles/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini"`
  server_password=`cat "$arkserver_GameUserSettings" | grep "^ServerPassword=" | sed "s/ServerPassword=//g"`
  server_admin_password=`cat "$arkserver_GameUserSettings" | grep "^ServerAdminPassword=" | sed "s/ServerAdminPassword=//g"`
  if [[ "$asterisk" == "TRUE" ]]; then
    server_admin_password_affichage=`echo $server_admin_password | tr "[[:print:]]" "#"`
  else
    server_admin_password_affichage=$server_admin_password
  fi
  server_version=`cat "$chemin_serveur/serverfiles/version.txt" | sed 's/ //g'`
  activemods=`cat "$arkserver_GameUserSettings" | grep "^ActiveMods=" | sed "s/ActiveMods=//g"`
  
  numero_serveur=0
  for sh_actuel in $liste_serveurs ; do
    sh_serveurs+=("$sh_actuel")
    if [[ -f "$chemin_serveur/lgsm/config-lgsm/arkserver/$sh_actuel.cfg" ]]; then
      map_serveurs+=(`cat "$chemin_serveur/lgsm/config-lgsm/arkserver/$sh_actuel.cfg" | grep "^defaultmap=" | sed "s/defaultmap=\"//g" | sed "s/\"//g"`)
      serveur_name=`cat "$chemin_serveur/lgsm/config-lgsm/arkserver/$sh_actuel.cfg" | grep 'SessionName=' | sed 's/.*SessionName=//g' | sed 's/?.*//g' | sed 's/\\\"//g'`
      sessionname_serveurs+=("$serveur_name")
      ip_serveurs+=(`cat "$chemin_serveur/lgsm/config-lgsm/arkserver/$sh_actuel.cfg" | grep "^ip=" | sed "s/ip=\"//g" | sed "s/\"//g"`)
      port_serveurs+=(`cat "$chemin_serveur/lgsm/config-lgsm/arkserver/$sh_actuel.cfg" | grep "^port=" | sed "s/port=\"//g" | sed "s/\"//g"`)
      queryport_serveurs+=(`cat "$chemin_serveur/lgsm/config-lgsm/arkserver/$sh_actuel.cfg" | grep "^queryport=" | sed "s/queryport=\"//g" | sed "s/\"//g"`)
      rconport_serveurs+=(`cat "$chemin_serveur/lgsm/config-lgsm/arkserver/$sh_actuel.cfg" | grep "^rconport=" | sed "s/rconport=\"//g" | sed "s/\"//g"`)
      maxplayers_serveurs+=(`cat "$chemin_serveur/lgsm/config-lgsm/arkserver/$sh_actuel.cfg" | grep "^maxplayers=" | sed "s/maxplayers=\"//g" | sed "s/\"//g"`)
      modids=`cat "$chemin_serveur/lgsm/config-lgsm/arkserver/$sh_actuel.cfg" | grep "GameModIds=" | sed 's/.*GameModIds=//g' | sed 's/?.*//g'`
      if [[ "$modids" != "" ]]; then
        modids_serveurs+=("$modids")
      else
        modids_serveurs+=("0")
      fi

      test_crontab=`crontab -l | grep "$sh_actuel start"`
      if [[ "$test_crontab" == "" ]]; then
        crontab_serveurs+=("Off")
      else
        test_crontab=`crontab -l | grep "$sh_actuel start" | grep "#"`
        if [[ "$test_crontab" == "" ]]; then
          crontab_serveurs+=("On")
        else
          crontab_serveurs+=("Off")
        fi
      fi
      #server_admin_password_serveurs+=("$server_admin_password")
      process_arkserver=`ps aux | sed '/tmux/d' | grep "./ShooterGameServer -i \(/Game/Mods/.*/${map_serveurs[$numero_serveur]}\|${map_serveurs[$numero_serveur]}\)" | grep "?Port=${port_serveurs[$numero_serveur]}?" | sed '/grep/d' | awk '{print $2}'`
      if [[ "$process_arkserver" != "" ]]; then
        mn_actuelle=`date +"%M"`
        if [[ "$mn_actuelle" == "00" ]] || [[ "$mn_actuelle" == "10" ]] || [[ "$mn_actuelle" == "20" ]] || [[ "$mn_actuelle" == "30" ]] || [[ "$mn_actuelle" == "40" ]] || [[ "$mn_actuelle" == "50" ]] || [[ ! -f "$HOME/.config/argos/arkserver/rcon_$numero_serveur.txt" ]]; then
          ./rcon -P$server_admin_password -a$ip_locale -p${rconport_serveurs[$numero_serveur]} listplayers > $HOME/.config/argos/arkserver/rcon_$numero_serveur.txt
        fi
        players_connected=`cat $HOME/.config/argos/arkserver/rcon_$numero_serveur.txt | grep "No Players Connected"`
        if [[ "$players_connected" == "" ]]; then
          cat $HOME/.config/argos/arkserver/rcon_$numero_serveur.txt | sed '/^$/d' | cut -c 4- | cut -d , -f 1 | sed '$d' > $HOME/.config/argos/arkserver/list_players.txt
          players=`wc -l < $HOME/.config/argos/arkserver/list_players.txt`
          list_players=`cat $HOME/.config/argos/arkserver/list_players.txt | sed ':a;N;$!ba;s/\n/, /g'`
          players_serveurs+=("$players")
          list_players_serveurs+=("$list_players")
        else
          players_serveurs+=("0")
          list_players_serveurs+=("0")
        fi
      else
        rm $HOME/.config/argos/arkserver/rcon_$numero_serveur.txt
        players_serveurs+=("0")
        list_players_serveurs+=("0")
      fi
    else
      map_serveurs+=("0")
      serveur_name="Serveur non configuré"
      sessionname_serveurs+=("$serveur_name")
      ip_serveurs+=("0")
      port_serveurs+=("0")
      queryport_serveurs+=("0")
      rconport_serveurs+=("0")
      maxplayers_serveurs+=("0")
      modids_serveurs+=("0")
      test_crontab=`crontab -l | grep "$sh_actuel start"`
      if [[ "$test_crontab" == "" ]]; then
        crontab_serveurs+=("Off")
      else
        test_crontab=`crontab -l | grep "$sh_actuel start" | grep "#"`
        if [[ "$test_crontab" == "" ]]; then
          crontab_serveurs+=("On")
        else
          crontab_serveurs+=("Off")
        fi
      fi
      #server_admin_password_serveurs+=("0")
      players_serveurs+=("0")
      list_players_serveurs+=("0")
    fi
    numero_serveur=$(expr $numero_serveur + 1)
  done
fi
nombre_serveur=`echo ${#map_serveurs[@]}`

#### Recherche et affichage des utilisateurs TS
if [[ "$check_users" == "oui" ]] && [[ "$process_tsbot" != "" ]]; then
  mn_actuelle=`date +"%M"`
  if [[ "$mn_actuelle" == "00" ]] || [[ "$mn_actuelle" == "10" ]] || [[ "$mn_actuelle" == "20" ]] || [[ "$mn_actuelle" == "30" ]] || [[ "$mn_actuelle" == "40" ]] || [[ "$mn_actuelle" == "50" ]] || [[ ! -f "$HOME/clients.txt" ]]; then
    echo "login serveradmin $password_serveradmin_TS" > $HOME/commandes.txt
    echo "use 1" >> $HOME/commandes.txt
    #echo "clientupdate client_nickname=ARKServer_Script" >> $HOME/commandes.txt
    echo "clientlist" >> $HOME/commandes.txt
    echo "quit" >> $HOME/commandes.txt
    
    netcat 127.0.0.1 10011 < $HOME/commandes.txt > $HOME/telnet.txt
    
    clients=`cat $HOME/telnet.txt | grep -Po '(?<=client_nickname=)[^ ]*' | sed '/\\sfrom\\s/d' | sed '/GARDiEN/d' | sed '$d' | wc -l`
    cat $HOME/telnet.txt | grep -Po '(?<=client_nickname=)[^ ]*' | sed '/\\sfrom\\s/d' | sed '/GARDiEN/d' | sed 's/\\s/ /g' > $HOME/clients.txt
  fi
  
  ts_users=()
  while IFS= read -r -d $'\n'; do
    ts_users+=("$REPLY")
  done <$HOME/clients.txt
  
  ### Nombre d'utilisateurs de TS
  ts_clients=`echo ${#ts_users[@]}`
fi

#### CrossArkChat
chemin_crossarkchat=`locate \/CrossArkChat | sed '/\/usb_save\//d' | grep "\/CrossArkChat$" | xargs dirname`
if [[ "$chemin_crossarkchat" != "" ]]; then
  #map_serveurs=`cat "$chemin_crossarkchat/Config/_configuration.json" | grep "\"NameTag\"" | sed "s/.*: \"//g" | sed "s/\",//g"`
  process_crossarkchat=`ps aux | grep "/CrossArkChat$" | sed '/grep/d' | awk '{print $2}'`
#  if [[ "$chemin_serveur" == "" ]]; then
#    source "$HOME/.config/argos/.crossarkchat.ini"
#    numero_serveur=1
#    nom_du_serveur=`cat "$HOME/.config/argos/.crossarkchat.ini" | grep "^map_$numero_serveur=" | sed "s/=\"//g" | sed "s/\"//g"`
#    while [[ "$nom_du_serveur" != "" ]]; do
#      sessionname_serveurs+=(`cat "$HOME/.config/argos/.crossarkchat.ini" | grep "^nom_$numero_serveur=" | sed "s/.*=\"//g" | sed "s/\"//g"`)
#      map_serveurs+=(`cat "$HOME/.config/argos/.crossarkchat.ini" | grep "^map_$numero_serveur=" | sed "s/.*=\"//g" | sed "s/\"//g"`)
#      ip_serveurs+=(`eval echo "\\$ip_"$sernumero_serveurveur`)
#      rconport_serveurs+=(`eval echo "\\$port_"$numero_serveur`)
#      server_admin_password_serveurs+=(`eval echo "\\$password_"$numero_serveur`)
#      #list_players_serveurs+=(`eval echo "\\$map_"$serveur`)
#      numero_serveur=$(expr $numero_serveur + 1)
#      nom_du_serveur=`cat "$HOME/.config/argos/.crossarkchat.ini" | grep "^map_$numero_serveur=" | sed "s/=\"//g" | sed "s/\"//g"`
#    done
#  fi
fi













#### Affichage
if [[ "$process_hackts" == "" ]] || [[ "$process_teamspeak" == "" ]] || [[ "$process_tsbot" == "" ]]; then
  echo "Serveurs | image='$SERVER_ICON' imageWidth=20"
else
  echo "Serveurs | image='$SERVER_ICON' imageWidth=20"
fi
echo "---"

## ARK
numero_serveur=0
while [[ $numero_serveur != $nombre_serveur ]]; do
  ARK_SERVER_ICON=$ARKSERVER_ARK
  arkserver_nom_map="The Island"
  if [[ "${map_serveurs[$numero_serveur]}" == "TheCenter" ]]; then
    arkserver_nom_map="The Center"
  fi
  if [[ "${map_serveurs[$numero_serveur]}" == "ScorchedEarth_P" ]]; then
    ARK_SERVER_ICON=$ARKSERVER_ARK_SE
    arkserver_nom_map="Scorched Earth"
  fi
  if [[ "${map_serveurs[$numero_serveur]}" == "Ragnarok" ]]; then
    ARK_SERVER_ICON=$ARKSERVER_ARK_Ragnarok
    arkserver_nom_map="Ragnarok"
  fi
  if [[ "${map_serveurs[$numero_serveur]}" == "Aberration_P" ]]; then
    ARK_SERVER_ICON=$ARKSERVER_ARK_Ab
    arkserver_nom_map="Aberration"
  fi
  if [[ "${map_serveurs[$numero_serveur]}" == "Extinction" ]]; then
    ARK_SERVER_ICON=$ARKSERVER_ARK_Extinction
    arkserver_nom_map="Extinction"
  fi
  if [[ "${map_serveurs[$numero_serveur]}" == "Valguero_P" ]]; then
    arkserver_nom_map="Valguero"
  fi
  if [[ "${map_serveurs[$numero_serveur]}" == "Viking_P" ]]; then
    arkserver_nom_map="Fjordur"
  fi
  process_arkserver=`ps aux | sed '/tmux/d' | grep -i "./ShooterGameServer \(/Game/Mods/.*/${map_serveurs[$numero_serveur]}\|${map_serveurs[$numero_serveur]}\)" | grep "?Port=${port_serveurs[$numero_serveur]}?" | sed '/grep/d' | awk '{print $2}'`
  if [[ "$process_arkserver" != "" ]]; then
    ark_cpu=`ps -p $process_arkserver -o %cpu | sed -n '2p' | awk '{print $1}'`
    ark_mem=`ps -p $process_arkserver -o %mem | sed -n '2p' | awk '{print $1}'`
    if [[ "${players_serveurs[$numero_serveur]}" != "0" ]]; then
      if [[ "${maxplayers_serveurs[$numero_serveur]}" != "" ]]; then
        printf "\e[1m%-15s %-5s :\e[0m %-3s | image='$ARK_SERVER_ICON' ansi=true font='Ubuntu Mono' trim=false imageWidth=18 \n" "$arkserver_nom_map" "${players_serveurs[$numero_serveur]}/${maxplayers_serveurs[$numero_serveur]}" ":heavy_check_mark:"
      else
        printf "\e[1m%-15s %-5s :\e[0m %-3s | image='$ARK_SERVER_ICON' ansi=true font='Ubuntu Mono' trim=false imageWidth=18 \n" "$arkserver_nom_map" "${players_serveurs[$numero_serveur]}" ":heavy_check_mark:"
      fi
    else
      if [[ "${maxplayers_serveurs[$numero_serveur]}" != "" ]]; then
        printf "\e[1m%-15s %-5s :\e[0m %-3s | image='$ARK_SERVER_ICON' ansi=true font='Ubuntu Mono' trim=false imageWidth=18 \n" "$arkserver_nom_map" "0/${maxplayers_serveurs[$numero_serveur]}" ":heavy_check_mark:"
      else
        printf "\e[1m%-15s %-5s :\e[0m %-3s | image='$ARK_SERVER_ICON' ansi=true font='Ubuntu Mono' trim=false imageWidth=18 \n" "$arkserver_nom_map" "0" ":heavy_check_mark:"
      fi
    fi
    printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":abc:" "Nom" "${sessionname_serveurs[$numero_serveur]}"
    printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":earth_africa:" "Adresse IP" "$ip_distante:${port_serveurs[$numero_serveur]}"
    if [[ "$server_password" != "" ]]; then printf "%-2s \u2514\u2500 \e[1m%-10s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" "Password" "$server_password"; fi
    printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":construction:" "Port RCON" "${rconport_serveurs[$numero_serveur]}"
    printf "%-2s \u2514\u2500 \e[1m%-10s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" "Password" "$server_admin_password_affichage"
    if [[ "${modids_serveur[$numero_serveurs]}" != "0" ]]; then printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":construction:" "Mods" "${modids_serveurs[$numero_serveur]}"; fi
    if [[ "${players_serveurs[$numero_serveur]}" != "0" ]]; then
      printf "%-2s %-3s \e[1m%-18s : | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":information_source:" "Joueurs connectes"
      printf "%-2s \u2514\u2500\e[0m %-s | ansi=true font='Ubuntu Mono' trim=false \n" "--" "${list_players_serveurs[$numero_serveur]}"
    fi
    printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":arrow_forward:" "Numero du process" "$process_arkserver"
    printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":arrow_forward:" "Utilisation CPU" "$ark_cpu"
    printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":arrow_forward:" "Utilisation MEM" "$ark_mem"
    if [[ "${crontab_serveurs[$numero_serveur]}" == "On" ]]; then
      printf "%-2s %-3s %s | ansi=true font='Ubuntu Mono' trim=false bash='/opt/scripts/crontab-arkserver.sh Off $chemin_serveur ${sh_serveurs[$numero_serveur]}' terminal=true \n" "--" ":repeat_one:" "Désactiver le redémarrage automatique du serveur"
    else
      printf "%-2s %-3s %s | ansi=true font='Ubuntu Mono' trim=false bash='/opt/scripts/crontab-arkserver.sh On $chemin_serveur ${sh_serveurs[$numero_serveur]}' terminal=true \n" "--" ":repeat_one:" "Activer le redémarrage automatique du serveur"
    fi
    printf "%-2s %-3s %s | ansi=true font='Ubuntu Mono' trim=false bash='$chemin_serveur/${sh_serveurs[$numero_serveur]} restart' terminal=true \n" "--" ":arrows_counterclockwise:" "Redémarrage du serveur"
    printf "%-2s %-3s %s | ansi=true font='Ubuntu Mono' trim=false bash='$chemin_serveur/${sh_serveurs[$numero_serveur]} stop' terminal=true \n" "--" ":no_entry_sign:" "Arrêt du serveur"
    printf "%-2s %-3s %s | ansi=true font='Ubuntu Mono' trim=false bash='echo $password_root | sudo -kS /opt/scripts/updatemods.sh --extra-log' terminal=true \n" "--" ":repeat:" "Mise à jour des mods"
  else
    if [[ "${map_serveurs[$numero_serveur]}" == "0" ]]; then
      printf "\e[1m%-21s :\e[0m %-3s | image='$ARK_SERVER_ICON' ansi=true font='Ubuntu Mono' trim=false imageWidth=18 \n" "Serveur non configuré" ":interrobang:"
    else
      printf "\e[1m%-21s :\e[0m %-3s | image='$ARK_SERVER_ICON' ansi=true font='Ubuntu Mono' trim=false imageWidth=18 \n" "$arkserver_nom_map" ":x:"
      printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":abc:" "Nom" "${sessionname_serveurs[$numero_serveur]}"
      if [[ "${crontab_serveurs[$numero_serveur]}" == "On" ]]; then
        printf "%-2s %-3s %s | ansi=true font='Ubuntu Mono' trim=false bash='/opt/scripts/crontab-arkserver.sh Off $chemin_serveur ${sh_serveurs[$numero_serveur]}' terminal=true \n" "--" ":repeat_one:" "Désactiver le redémarrage automatique du serveur"
      else
        printf "%-2s %-3s %s | ansi=true font='Ubuntu Mono' trim=false bash='/opt/scripts/crontab-arkserver.sh On $chemin_serveur ${sh_serveurs[$numero_serveur]}' terminal=true \n" "--" ":repeat_one:" "Activer le redémarrage automatique du serveur"
      fi
      printf "%-2s %-3s %s | ansi=true font='Ubuntu Mono' trim=false bash='$chemin_serveur/${sh_serveurs[$numero_serveur]} start' terminal=true \n" "--" ":arrow_forward:" "Démarrage du serveur"
    fi
  fi
  numero_serveur=$(expr $numero_serveur + 1)
done

#numero_serveur=0
#nombre_serveur=2
#while [[ $numero_serveur != $nombre_serveur ]]; do
#  ARK_SERVER_ICON=$ARKSERVER_ARK
#  if [[ "${map_serveurs[$numero_serveur]}" == "Scorched Earth" ]]; then
#    ARK_SERVER_ICON=$ARKSERVER_ARK_SE
#  fi
#  if [[ "${map_serveurs[$numero_serveur]}" == "Ragnarok" ]]; then
#    ARK_SERVER_ICON=$ARKSERVER_ARK_Ragnarok
#  fi
#  if [[ "${map_serveurs[$numero_serveur]}" == "Aberration" ]]; then
#    ARK_SERVER_ICON=$ARKSERVER_ARK_Ab
#  fi
#  if [[ "${map_serveurs[$numero_serveur]}" == "Extinction" ]]; then
#    ARK_SERVER_ICON=$ARKSERVER_ARK_Extinction
#  fi
#  printf "\e[1m%-15s %-5s :\e[0m %-3s | image='$ARK_SERVER_ICON' ansi=true font='Ubuntu Mono' trim=false imageWidth=18 \n" "${map_serveurs[$numero_serveur]}" "${players_serveurs[$numero_serveur]}" ":heavy_check_mark:"
#
#  numero_serveur=$(expr $numero_serveur + 1)
#done


## TS
if [[ "$process_teamspeak" != "" ]] || [[ "$process_hackts" != "" ]]; then
  echo "---"
  if [[ "$process_teamspeak" != "" ]]; then
    printf "\e[1m%-21s :\e[0m %-3s | image='$ARKSERVER_TS' ansi=true font='Ubuntu Mono' trim=false imageWidth=18 \n" "Serveur TS" ":heavy_check_mark:"
    printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":arrow_forward:" "Numero du process" "$process_teamspeak"
    printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":arrow_forward:" "Utilisation CPU" "$ts_cpu"
    printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":arrow_forward:" "Utilisation MEM" "$ts_mem"
  else
    echo "---"
    printf "\e[1m%-21s :\e[0m %-3s | image='$ARKSERVER_TS' ansi=true font='Ubuntu Mono' trim=false imageWidth=18 \n" "Serveur TS" ":x:"
  fi
  if [[ "$process_hackts" != "" ]]; then
    printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":heavy_check_mark:" "Hack TS" "PID $process_hackts"
  else
    printf "%-2s %-3s \e[1m%-18s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":x:" "Hack TS"
  fi
  if [[ "$process_tsbot" != "" ]]; then
    printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":heavy_check_mark:" "Bot TS" "PID $process_tsbot"
  else
    printf "%-2s %-3s \e[1m%-18s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":x:" "Bot TS"
  fi
fi

## Users TS
if [[ "$check_users" == "oui" ]] && [[ "$process_tsbot" != "" ]]; then
  printf "\e[1m%-21s :\e[0m %-3s | image='$TS_USERS_ICON' ansi=true font='Ubuntu Mono' trim=false imageWidth=18 \n" "Utilisateurs TS" "$ts_clients"
  for user_num in "${!ts_users[@]}"; do
    if [[ "$user_num" != $((ts_clients-1)) ]]; then
      printf "%-2s \u251c\u2500 %-17s : %-20s %s | ansi=true font='Ubuntu Mono' trim=false \n" "--" "Client" "${ts_users[$user_num]}"
    else
      printf "%-2s \u2514\u2500 %-17s : %-20s %s | ansi=true font='Ubuntu Mono' trim=false \n" "--" "Client" "${ts_users[$user_num]}"
    fi
  done
fi

## CrossArkChat
if [[ "$chemin_crossarkchat" != "" ]]; then
  echo "---"
  if [[ "$process_crossarkchat" != "" ]]; then
    printf "\e[1m%-21s :\e[0m %-3s | image='$ARKSERVER_CROSSARKCHAT' ansi=true font='Ubuntu Mono' trim=false imageWidth=18 \n" "CrossArkChat" ":heavy_check_mark:"
  else
    printf "\e[1m%-21s :\e[0m %-3s | image='$ARKSERVER_CROSSARKCHAT' ansi=true font='Ubuntu Mono' trim=false imageWidth=18 \n" "CrossArkChat" ":x:"
    #printf "%-2s %-3s %s | ansi=true font='Ubuntu Mono' trim=false bash='$chemin_crossarkchat/CrossArkChat' terminal=true \n" "--" ":arrow_forward:" "Démarrage du bot"
  fi
fi


#### Préparation des paramètres
parametres=`echo -e "yad --fixed --undecorated --no-escape --skip-taskbar --width=\"700\" --height=\"300\" --center --borders=20 --window-icon=\"$HOME/.config/argos/.cache-icons/ARKServer.png\" --title=\"Paramètres généraux\" --text=\"<big>\r\rVeuillez entrer vos informations de compte(s).\rCes informations ne sont pas stockées sur internet.\r\r</big>\" --text-align=center --image=\"$HOME/.config/argos/.cache-icons/ARKServer.png\" --form --separator=\"§\" --field=\"Ne pas afficher les mots de passe en clair:CHK\" --field=\"API Key\" --field=\"User_1 Key\" --field=\"User_2 Key\" --field=\"Mot de passe root\" --field=\"Mot de passe Admin du TS\" \"$asterisk\" \"$token_app\" \"$destinataire_1\" \"$destinataire_2\" \"$password_root\" \"$password_serveradmin_TS\" --button=gtk-ok:0 2>/dev/null > ~/.config/argos/.arkserver-parameters"`

echo "---"
printf "%-15s | image='$SETTINGS_ICON' imageWidth=18 ansi=true font='Ubuntu Mono' trim=false bash='$parametres' terminal=false \n" "Paramètres de l'extension"
#printf "%-15s | image='$ADD_ICON' imageWidth=18 ansi=true font='Ubuntu Mono' trim=false bash='$chemin_serveur/linuxgsm.sh arkserver' terminal=true \n" "Ajouter un serveur"
printf "%-15s | image='$REFRESH_ICON' imageWidth=18 ansi=true font='Ubuntu Mono' trim=false bash='echo $password_root | sudo -kS updatedb' terminal=false refresh=true \n" "Rafraichir"
#echo "Rafraichir | refresh=true"

echo "---"
if [[ "$server_version" != "" ]]; then
  printf "%s | ansi=true font='Ubuntu Mono' trim=false size=8 \n" "Version: $version / Serveur: $server_version"
else
  printf "%s | ansi=true font='Ubuntu Mono' trim=false size=8 \n" "Version: $version"
fi