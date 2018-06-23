#!/usr/bin/env bash

version="0.0.0.1"

#### Mes paramètres
token_app=""
destinataire_1=""
destinataire_2=""
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
ARKSERVER_ARK=$(curl -s "file://$icons_cache/ARK.png" | base64 -w 0)
ARKSERVER_ARK_SE=$(curl -s "file://$icons_cache/ARK-SE.png" | base64 -w 0)
ARKSERVER_ARK_Ab=$(curl -s "file://$icons_cache/ARK-Ab.png" | base64 -w 0)
ARKSERVER_TS=$(curl -s "file://$icons_cache/TS.png" | base64 -w 0)

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
cd /opt/scripts

#### vérification de la présence de 'rcon'
if [[ ! -f "/opt/script/rcon" ]] ; then
  wget http://www.dopefish.de/files/rcon.c > /dev/null
  gcc rcon.c -o rcon > /dev/null
  chmod ugo+rx rcon > /dev/null
  rm rcon.c > /dev/null
fi

#### Recherche de mes process
process_arkserver=`ps aux | grep "arkserver ./ShooterGameServer" | sed '/grep/d' | awk '{print $2}'`
process_teamspeak=`ps aux | grep "./ts3server" | sed '/grep/d' | awk '{print $2}'`
process_tsbot=`service tsbot status | grep "Main PID" | sed '/grep/d' | awk '{print $3}'`
if [[ "$process_tsbot" == "" ]]; then
  process_tsbot=`service tsbot status | grep "└─" | sed '/grep/d' | awk '{print $1}' | sed 's/└─//'`
fi
process_hackts=`ps aux | grep "AccountingServerEmulator-Linux" | sed '/grep/d' | awk '{print $2}'`
#process_arkserver=""
#process_teamspeak=""
#process_hackts=""
#process_tsbot=""

#### Utilisation CPU et MEM de ARK et TS
ark_cpu=`ps -p $process_arkserver -o %cpu | sed -n '2p' | awk '{print $1}'`
ark_mem=`ps -p $process_arkserver -o %mem | sed -n '2p' | awk '{print $1}'`
ts_cpu=`ps -p $process_teamspeak -o %cpu | sed -n '2p' | awk '{print $1}'`
ts_mem=`ps -p $process_teamspeak -o %mem | sed -n '2p' | awk '{print $1}'`

#### Récupération des paramètres ARK
if [[ "$process_arkserver" != "" ]]; then
  arkserver_chemin=`locate \/arkserver | sed '/\/usb_save\//d' | sed '/\/lgsm\//d' | sed '/\/log\//d' | grep "\/arkserver$" | xargs dirname`
  arkserver_ip=""
  arkserver_ip_locale=""
  arkserver_port=""
  arkserver_server_password=""
  arkserver_port_rcon=""
  arkserver_server_admin_password=""
  arkserver_activemods=""
  arkserver_max_players=""
  
  players_connected=""
  players=""
  list_players=""
  if [[ "$arkserver_chemin" != "" ]]; then
    arkserver_GameUserSettings=`echo $arkserver_chemin"/serverfiles/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini"`
    if [[ -f "$arkserver_GameUserSettings" ]]; then
      arkserver_ip_locale=`hostname -I | cut -d' ' -f1`
      #arkserver_ip_locale=`cat "$arkserver_GameUserSettings" | grep "MultiHome=" | sed -e "s/MultiHome=//g"`
      arkserver_ip=`dig -b $arkserver_ip_locale +short myip.opendns.com @resolver1.opendns.com`
      arkserver_port=`cat "$arkserver_GameUserSettings" | grep "^Port=" | sed -e "s/Port=//g"`
      arkserver_server_password=`cat "$arkserver_GameUserSettings" | grep "^ServerPassword=" | sed -e "s/ServerPassword=//g"`
      arkserver_port_rcon=`cat "$arkserver_GameUserSettings" | grep "^RCONPort=" | sed -e "s/RCONPort=//g"`
      arkserver_server_admin_password=`cat "$arkserver_GameUserSettings" | grep "^ServerAdminPassword=" | sed -e "s/ServerAdminPassword=//g"`
      arkserver_activemods=`cat "$arkserver_GameUserSettings" | grep "^ActiveMods=" | sed -e "s/ActiveMods=//g"`
      arkserver_max_players=`cat "$arkserver_GameUserSettings" | grep "^MaxPlayers=" | sed -e "s/MaxPlayers=//g"`
    fi
  fi
  if [[ "$arkserver_ip" != "" ]] && [[ "$arkserver_ip_locale" != "" ]] && [[ "$arkserver_port" != "" ]] && [[ "$arkserver_port_rcon" != "" ]]  && [[ "$arkserver_server_password" != "" ]]  && [[ "$arkserver_server_admin_password" != "" ]]; then
    mn_actuelle=`date +"%M"`
    if [[ "$mn_actuelle" == "00" ]] || [[ "$mn_actuelle" == "10" ]] || [[ "$mn_actuelle" == "20" ]] || [[ "$mn_actuelle" == "30" ]] || [[ "$mn_actuelle" == "40" ]] || [[ "$mn_actuelle" == "50" ]] || [[ ! -f "$HOME/ark_rcon.txt" ]]; then
      ./rcon -P$arkserver_server_admin_password -a$arkserver_ip_locale -p$arkserver_port_rcon listplayers > $HOME/ark_rcon.txt
    fi
    if [[ -f "$HOME/ark_rcon.txt" ]] ; then
      players_connected=`cat $HOME/ark_rcon.txt | grep "No Players Connected"`
      if [[ "$players_connected" == "" ]]; then
        cat $HOME/ark_rcon.txt | sed '/^$/d' | cut -c 4- | cut -d , -f 1 | sed '$d' > $HOME/list_players.txt
        players=`wc -l < $HOME/list_players.txt`
        list_players=`cat $HOME/list_players.txt | sed ':a;N;$!ba;s/\n/, /g'`
      fi
    fi
  fi

#### Recherche de la map ARK
  map_arkserver=`ps aux | grep "arkserver ./ShooterGameServer" | sed '/grep/d' | sed 's/.*"\(.*\)?listen.*/\1/'`
  ARK_SERVER_ICON=$ARKSERVER_ARK
  arkserver_nom_map="The Island"

  if [[ "$map_arkserver" == "TheCenter" ]]; then
    arkserver_nom_map="The Center"
  fi
  if [[ "$map_arkserver" == "ScorchedEarth_P" ]]; then
    ARK_SERVER_ICON=$ARKSERVER_ARK_SE
    arkserver_nom_map="Scorched Earth"
  fi
  if [[ "$map_arkserver" == "Ragnarok" ]]; then
    arkserver_nom_map="Ragnarok"
  fi
  if [[ "$map_arkserver" == "Aberration_P" ]]; then
    ARK_SERVER_ICON=$ARKSERVER_ARK_Ab
    arkserver_nom_map="Aberration"
  fi
fi

#### Recherche et affichage des utilisateurs TS
if [[ "$check_users" == "oui" ]] && [[ "$process_tsbot" != "" ]]; then
  mn_actuelle=`date +"%M"`
  if [[ "$mn_actuelle" == "00" ]] || [[ "$mn_actuelle" == "10" ]] || [[ "$mn_actuelle" == "20" ]] || [[ "$mn_actuelle" == "30" ]] || [[ "$mn_actuelle" == "40" ]] || [[ "$mn_actuelle" == "50" ]] || [[ ! -f "$HOME/clients.txt" ]]; then
    echo "login serveradmin password_serveradmin" > $HOME/commandes.txt
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














#### Affichage
#if [[ "$process_arkserver" == "" ]] || [[ "$process_hackts" == "" ]] || [[ "$process_teamspeak" == "" ]] || [[ "$process_tsbot" == "" ]]; then
if [[ "$process_hackts" == "" ]] || [[ "$process_teamspeak" == "" ]] || [[ "$process_tsbot" == "" ]]; then
  #echo -e "\e[41m  \e[0m Serveurs | image='$SERVER_ICON' imageWidth=25"
  echo -e "\e[41m   \e[0m Serveurs"
else
  #echo -e "\e[42m  \e[0m Serveurs | image='$SERVER_ICON' imageWidth=25"
  echo -e "\e[42m   \e[0m Serveurs"
fi
echo "---"
## ARK
if [[ "$process_arkserver" != "" ]]; then
  printf "\e[1m%-15s :\e[0m %-3s | image='$ARK_SERVER_ICON' ansi=true font='Ubuntu Mono' trim=false imageWidth=30 \n" "Serveur ARK" ":heavy_check_mark:"
  printf "%-2s \u2514\u2500 \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" "Map" "$arkserver_nom_map"
  if [[ "$arkserver_ip" != "" ]] && [[ "$arkserver_ip_locale" != "" ]] && [[ "$arkserver_port" != "" ]] && [[ "$arkserver_port_rcon" != "" ]]  && [[ "$arkserver_server_password" != "" ]]  && [[ "$arkserver_server_admin_password" != "" ]]; then
    printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":earth_africa:" "Adresse IP" "$arkserver_ip:$arkserver_port"
    printf "%-2s \u251c\u2500 \e[1m%-10s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" "IP Locale" "$arkserver_ip_locale"
    printf "%-2s \u2514\u2500 \e[1m%-10s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" "Password" "$arkserver_server_password"
    printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":construction:" "Port RCON" "$arkserver_port_rcon"
    printf "%-2s \u2514\u2500 \e[1m%-10s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" "Password" "$arkserver_server_admin_password"
  else
    printf "%-2s %-3s \e[1m%-40s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":earth_africa:" "configuration inconnue"
  fi
  if [[ "$arkserver_activemods" != "" ]]; then
    printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":construction:" "Mods" "$arkserver_activemods"
  fi
  printf "%-2s %-3s %s | ansi=true font='Ubuntu Mono' trim=false bash='$arkserver_chemin/arkserver restart' terminal=true \n" "--" ":repeat:" "Redémarrage du serveur"
  printf "%-2s %-3s %s | ansi=true font='Ubuntu Mono' trim=false bash='echo route123 | sudo -kS /opt/scripts/updatemods.sh --extra-log' terminal=true \n" "--" ":repeat:" "Mise à jour des mods"
  printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":arrow_forward:" "Numero du process" "$process_arkserver"
  printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":arrow_forward:" "Utilisation CPU" "$ark_cpu"
  printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":arrow_forward:" "Utilisation MEM" "$ark_mem"
  if [[ -f "$HOME/ark_rcon.txt" ]] ; then
    if [[ "$players_connected" != "" ]]; then
      if [[ "$arkserver_max_players" != "" ]]; then
        printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":arrow_forward:" "Joueurs connectes" "0/$arkserver_max_players"
      else
        printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":arrow_forward:" "Joueurs connectes" "0"
      fi
    else
      if [[ "$arkserver_max_players" != "" ]]; then
        printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":arrow_forward:" "Joueurs connectes" "$players/$arkserver_max_players"
        printf "%-2s \u2514\u2500\e[0m %-s | ansi=true font='Ubuntu Mono' trim=false \n" "--" "$list_players"
      else
        printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":arrow_forward:" "Joueurs connectes" "$players"
        printf "%-2s \u2514\u2500\e[0m %-s | ansi=true font='Ubuntu Mono' trim=false \n" "--" "$list_players"
      fi
    fi
  fi
else
  printf "\e[1m%-15s :\e[0m %-3s | image='$ARKSERVER_ARK' ansi=true font='Ubuntu Mono' trim=false imageWidth=30 \n" "Serveur ARK" ":x:"
  printf "%-2s %-3s %s | ansi=true font='Ubuntu Mono' trim=false bash='$arkserver_chemin/arkserver restart' terminal=true \n" "--" ":repeat:" "Redémarrage du serveur"
fi

## TS
if [[ "$process_teamspeak" != "" ]]; then
  printf "\e[1m%-15s :\e[0m %-3s | image='$ARKSERVER_TS' ansi=true font='Ubuntu Mono' trim=false imageWidth=30 \n" "Serveur TS" ":heavy_check_mark:"
  printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":arrow_forward:" "Numero du process" "$process_teamspeak"
  printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":arrow_forward:" "Utilisation CPU" "$ts_cpu"
  printf "%-2s %-3s \e[1m%-18s :\e[0m %-22s | ansi=true font='Ubuntu Mono' trim=false \n" "--" ":arrow_forward:" "Utilisation MEM" "$ts_mem"
else
  printf "\e[1m%-15s :\e[0m %-3s | image='$ARKSERVER_TS' ansi=true font='Ubuntu Mono' trim=false imageWidth=30 \n" "Serveur TS" ":x:"
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

## Users TS
if [[ "$check_users" == "oui" ]] && [[ "$process_tsbot" != "" ]]; then
  printf "\e[1m%-15s :\e[0m %-3s | image='$TS_USERS_ICON' ansi=true font='Ubuntu Mono' trim=false imageWidth=30 \n" "Utilisateurs TS" "$ts_clients"
  for user_num in "${!ts_users[@]}"; do
    if [[ "$user_num" != $((ts_clients-1)) ]]; then
      printf "%-2s \u251c\u2500 %-17s : %-20s %s | ansi=true font='Ubuntu Mono' trim=false \n" "--" "Client" "${ts_users[$user_num]}"
    else
      printf "%-2s \u2514\u2500 %-17s : %-20s %s | ansi=true font='Ubuntu Mono' trim=false \n" "--" "Client" "${ts_users[$user_num]}"
    fi
  done
fi
