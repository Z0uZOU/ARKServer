#!/bin/bash
 
########################
## Script de Z0uZOU
########################
## Installation: wget -q https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/updatemods.sh -O updatemods.sh && sed -i -e 's/\r//g' updatemods.sh && shc -f updatemods.sh -o updatemods.bin && chmod +x updatemods.bin && rm -f *.x.c && rm -f updatemods.sh
## Installation: wget -q https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/updatemods.sh -O updatemods.sh && sed -i -e 's/\r//g' updatemods.sh && chmod +x updatemods.sh
## Micro-config
version="Version: 0.0.0.59" #base du système de mise à jour
description="Téléchargeur de Mods pour ARK: Survival Evolved" #description pour le menu
script_github="https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/updatemods.sh" #emplacement du script original
changelog_github="https://pastebin.com/raw/vJpabVtT" #emplacement du changelog de ce script
icone_imgur="http://i.imgur.com/dasbwhC.png" #emplacement de l'icône du script
required_repos="ppa:neurobin/ppa" #ajout de repository
required_tools="curl shc steamcmd" #dépendances du script
required_tools_pip="" #dépendances du script (PIP)
script_cron="0 6 * * *" #ne définir que la planification
verification_process="" #si ces process sont détectés on ne notifie pas (ou ne lance pas en doublon)
########################
 
#### Vérification que le script possède les droits root
## NE PAS TOUCHER
if [[ "$EUID" != "0" ]]; then
  if [[ "$CRON_SCRIPT" == "oui" ]]; then
    exit 1
  else
    echo "Vous devrez impérativement utiliser le compte root"
    exit 1
  fi
fi
 
#### Vérification de process pour éviter les doublons (commandes externes)
for process_travail in $verification_process ; do
  process_important=`ps aux | grep $process_travail | sed '/grep/d'`
  if [[ "$process_important" != "" ]] ; then
    if [[ "$CRON_SCRIPT" != "oui" ]] ; then
      echo $process_important" est en cours de fonctionnement, arrêt du script"
      fin_script=`date`
      echo -e "\e[43m-- FIN DE SCRIPT: $fin_script --\e[0m"
    fi
    exit 1
  fi
done
 
#### Déduction des noms des fichiers (pour un portage facile)
mon_script_fichier=`basename "$0"`
mon_script_base=`echo ''$mon_script_fichier | cut -f1 -d'.'''`
mon_script_base_maj=`echo ${mon_script_base^^}`
mon_script_config=`echo "/root/.config/"$mon_script_base"/"$mon_script_base".conf"`
mon_script_ini=`echo "/root/.config/"$mon_script_base"/"$mon_script_base".ini"`
mon_script_log=`echo $mon_script_base".log"`
mon_script_desktop=`echo $mon_script_base".desktop"`
mon_script_updater=`echo $mon_script_base"-update.sh"`
 
#### Tests des arguments
if [[ "$1" == "--version" ]]; then
  echo "$version"
  exit 1
fi
if [[ "$1" == "--debug" ]] || [[ "$2" == "--debug" ]]; then
  debug="yes"
fi
if [[ "$1" == "--edit-config" ]]; then
  nano $mon_script_config
  exit 1
fi
if [[ "$1" == "--debug" ]] || [[ "$2" == "--debug" ]]; then
  debug="yes"
fi
if [[ "$1" == "--efface-lock" ]]; then
  mon_lock=`echo "/root/.config/"$mon_script_base"/lock-"$mon_script_base`
  rm -f "$mon_lock"
  echo "Fichier lock effacé"
  exit 1
fi
if [[ "$1" == "--statut-lock" ]]; then
  statut_lock=`cat $mon_script_config | grep "maj_force=\"oui\""`
  if [[ "$statut_lock" == "" ]]; then
    echo "Système de lock activé"
  else
    echo "Système de lock désactivé"
  fi
  exit 1
fi
if [[ "$1" == "--active-lock" ]]; then
  sed -i 's/maj_force="oui"/maj_force="non"/g' $mon_script_config
  echo "Système de lock activé"
  exit 1
fi
if [[ "$1" == "--desactive-lock" ]]; then
  sed -i 's/maj_force="non"/maj_force="oui"/g' $mon_script_config
  echo "Système de lock désactivé"
  exit 1
fi
if [[ "$1" == "--extra-log" ]] || [[ "$2" == "--extra-log" ]]; then
  date_log=`date +%Y%m%d`
  heure_log=`date +%H%M`
  path_log=`echo "/root/.config/"$mon_script_base"/log/"$date_log`
  mkdir -p $path_log 2>/dev/null
  fichier_log_perso=`echo $path_log"/"$heure_log".log"`
  mon_log_perso="| tee -a $fichier_log_perso"
fi
if [[ "$1" == "--purge-process" ]]; then
  ps aux | grep $mon_script_base | awk '{print $2}' | xargs kill -9
  echo "Les processus de ce script ont été tués"
fi
if [[ "$1" == "--purge-log" ]]; then
  path_global_log=`echo "/root/.config/"$mon_script_base"/log"`
  cd $path_global_log
  mon_chemin=`echo $PWD`
  if [[ "$mon_chemin" == "$path_global_log" ]]; then
    printf "Êtes-vous sûr de vouloir effacer l'intégralité des logs de --extra-log? (oui/non) : "
    read question_effacement
    if [[ "$question_effacement" == "oui" ]]; then
      rm -rf *
      echo "Les logs ont été effacés"
    fi
  else
    echo "Une erreur est survenue, veuillez contacter le développeur"
  fi
  exit 1
fi
if [[ "$1" == "--changelog" ]]; then
  wget -q -O- $changelog_github
  echo ""
  exit 1
fi
if [[ "$1" == --message=* ]]; then
  source $mon_script_config
  message=`echo "$1" | sed 's/--message=//g'`
  curl -s \
    --form-string "token=acy83vqos6h76yzpp3mhrt6saf25b4" \
    --form-string "user=uauyi2fdfiu24k7xuwiwk92ovimgto" \
    --form-string "title=$mon_script_base_maj MESSAGE" \
    --form-string "message=$message" \
    --form-string "html=1" \
    --form-string "priority=0" \
    https://api.pushover.net/1/messages.json > /dev/null
  exit 1
fi
if [[ "$1" == "--help" ]]; then
  path_log=`echo "/root/.config/"$mon_script_base"/log/"$date_log`
  echo -e "\e[1m$mon_script_base_maj\e[0m ($version)"
  echo "Objectif du programme: $description"
  echo "Auteur: ZouZOU <zouzou.is.reborn@hotmail.fr>"
  echo ""
  echo "Utilisation: \"$mon_script_fichier [--option]\""
  echo ""
  echo -e "\e[4mOptions:\e[0m"
  echo "  --version               Affiche la version de ce programme"
  echo "  --edit-config           Édite la configuration de ce programme"
  echo "  --extra-log             Génère un log à chaque exécution dans "$path_log
  echo "  --debug                 Lance ce programme en mode debug"
  echo "  --efface-lock           Supprime le fichier lock qui empêche l'exécution"
  echo "  --statut-lock           Affiche le statut de la vérification de process doublon"
  echo "  --active-lock           Active le système de vérification de process doublon"
  echo "  --desactive-lock        Désactive le système de vérification de process doublon"
  echo "  --maj-uniquement        N'exécute que la mise à jour"
  echo "  --changelog             Affiche le changelog de ce programme"
  echo "  --help                  Affiche ce menu"
  echo ""
  echo "Les options \"--debug\" et \"--extra-log\" sont cumulables"
  echo ""
  echo -e "\e[4mUtilisation avancée:\e[0m"
  echo "  --message=\"...\"         Envoie un message push au développeur (urgence uniquement)"
  echo "  --purge-log             Purge définitivement les logs générés par --extra-log"
  echo "  --purge-process         Tue tout les processus générés par ce programme"
  echo ""
  echo -e "\e[3m ATTENTION: CE PROGRAMME DOIT ÊTRE EXÉCUTÉ AVEC LES PRIVILÈGES ROOT \e[0m"
  echo "Des commandes comme les installations de dépendances ou les recherches nécessitent de tels privilèges."
  echo ""
  exit 1
fi
 
#### je dois charger le fichier conf ici ou trouver une solution (script_url et maj_force)
dossier_config=`echo "/root/.config/"$mon_script_base`
if [[ -d "$dossier_config" ]]; then
  useless="1"
else
  mkdir -p $dossier_config
fi
 
if [[ -f "$mon_script_config" ]] ; then
  source $mon_script_config
else
    if [[ "$script_url" != "" ]] ; then
      script_github=$script_url
    fi
    if [[ "$maj_force" == "" ]] ; then
      maj_force="non"
    fi
fi
 
#### Vérification qu'au reboot les lock soient bien supprimés
## attention si pas de rc.local il faut virer les lock par cron (a faire)
if [[ -f "/etc/rc.local" ]]; then
  test_rc_local=`cat /etc/rc.local | grep -e 'find /root/.config -name "lock-\*" | xargs rm -f'`
  if [[ "$test_rc_local" == "" ]]; then
   sed -i -e '$i \find /root/.config -name "lock-*" | xargs rm -f\n' /etc/rc.local >/dev/null
  fi
fi
 
#### Vérification qu'une autre instance de ce script ne s'exécute pas
computer_name=`hostname`
pid_script=`echo "/root/.config/"$mon_script_base"/lock-"$mon_script_base`
if [[ "$maj_force" == "non" ]] ; then
  if [[ -f "$pid_script" ]] ; then
    echo "Il y a au moins un autre process du script en cours"
    message_alerte=`echo -e "Un process bloque mon script sur $computer_name"`
    ## petite notif pour ZouZOU
    curl -s \
    --form-string "token=arocr9cyb3x5fdo7i4zy7e99da6hmx" \
    --form-string "user=uauyi2fdfiu24k7xuwiwk92ovimgto" \
    --form-string "title=$mon_script_base_maj HS" \
    --form-string "message=$message_alerte" \
    --form-string "html=1" \
    --form-string "priority=1" \
    https://api.pushover.net/1/messages.json > /dev/null
    exit 1
  fi
fi
touch $pid_script
 
#### Chemin du script
## necessaire pour le mettre dans le cron
cd /opt/scripts
 
#### Indispensable aux messages de chargement
mon_printf="\r                                                                                           "
 
#### Nettoyage obligatoire et push pour annoncer la maj
if [[ -f "$mon_script_updater" ]] ; then
  rm "$mon_script_updater"
  source $mon_script_config 2>/dev/null
  version_maj=`echo $version | awk '{print $2}'`
  message_maj=`echo -e "Le progamme $mon_script_base est désormais en version $version_maj"`
  for user in {1..10}; do
    destinataire=`eval echo "\\$destinataire_"$user`
    if [ -n "$destinataire" ]; then
      curl -s \
      --form-string "token=$token_app" \
      --form-string "user=$destinataire" \
      --form-string "title=Mise à jour installée" \
      --form-string "message=$message_maj" \
      --form-string "html=1" \
      --form-string "priority=-1" \
      https://api.pushover.net/1/messages.json > /dev/null
    fi
  done
fi
 
#### Vérification de version pour éventuelle mise à jour
version_distante=`wget -O- -q "$script_github" | grep "Version:" | awk '{ print $2 }' | sed -n 1p | awk '{print $1}' | sed -e 's/\r//g' | sed 's/"//g'`
version_locale=`echo $version | awk '{print $2}'`
 
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
compare=`testvercomp $version_locale $version_distante '<' | grep Pass`
if [[ "$compare" != "" ]] ; then
  echo "une mise à jour est disponible ($version_distante) - version actuelle: $version_locale"
  echo "téléchargement de la mise à jour et installation..."
  touch $mon_script_updater
  chmod +x $mon_script_updater
  echo "#!/bin/bash" >> $mon_script_updater
  mon_script_fichier_temp=`echo $mon_script_fichier"-temp"`
  echo "wget -q $script_github -O $mon_script_fichier_temp" >> $mon_script_updater
  echo "sed -i -e 's/\r//g' $mon_script_fichier_temp" >> $mon_script_updater
  if [[ "$mon_script_fichier" =~ \.sh$ ]]; then
    echo "mv $mon_script_fichier_temp $mon_script_fichier" >> $mon_script_updater
    echo "chmod +x $mon_script_fichier" >> $mon_script_updater
    echo "bash $mon_script_fichier $1 $2" >> $mon_script_updater
  else
    echo "shc -f $mon_script_fichier_temp -o $mon_script_fichier" >> $mon_script_updater
    echo "rm -f $mon_script_fichier_temp" >> $mon_script_updater
    compilateur=`echo $mon_script_fichier".x.c"`
    echo "rm -f *.x.c" >> $mon_script_updater
    echo "chmod +x $mon_script_fichier" >> $mon_script_updater
    echo "echo mise à jour mise en place" >> $mon_script_updater
    echo "./$mon_script_fichier $1 $2" >> $mon_script_updater
  fi
  echo "exit 1" >> $mon_script_updater
  rm "$pid_script"
  bash $mon_script_updater
  exit 1
else
  eval 'echo -e "\e[43m-- $mon_script_base_maj - VERSION: $version_locale --\e[0m"' $mon_log_perso
fi
 
#### Nécessaire pour l'argument --maj-uniquement
if [[ "$1" == "--maj-uniquement" ]]; then
  rm "$pid_script"
  exit 1
fi
 
#### Vérification de la conformité du cron
crontab -l > mon_cron.txt
cron_path=`cat mon_cron.txt | grep "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"`
if [[ "$cron_path" == "" ]]; then
  sed -i '1iPATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin' mon_cron.txt
  cron_a_appliquer="oui"
fi
cron_lang=`cat mon_cron.txt | grep "LANG=fr_FR.UTF-8"`
if [[ "$cron_lang" == "" ]]; then
  sed -i '1iLANG=fr_FR.UTF-8' mon_cron.txt
  cron_a_appliquer="oui"
fi
cron_variable=`cat mon_cron.txt | grep "CRON_SCRIPT=\"oui\""`
if [[ "$cron_variable" == "" ]]; then
  sed -i '1iCRON_SCRIPT="oui"' mon_cron.txt
  cron_a_appliquer="oui"
fi
if [[ "$cron_a_appliquer" == "oui" ]]; then
  crontab mon_cron.txt
  rm -f mon_cron.txt
  eval 'echo "-- Cron mis en conformité"' $mon_log_perso
else
  rm -f mon_cron.txt
fi
 
#### Mise en place éventuelle d'un cron
if [[ "$script_cron" != "" ]]; then
  mon_cron=`crontab -l`
  verif_cron=`echo "$mon_cron" | grep "$mon_script_fichier"`
  if [[ "$verif_cron" == "" ]]; then
    eval 'echo -e "\e[41mAUCUNE ENTRÉE DANS LE CRON\e[0m"' $mon_log_perso
    eval 'echo "-- Création..."' $mon_log_perso
    ajout_cron=`echo -e "$script_cron\t\t/opt/scripts/$mon_script_fichier > /var/log/$mon_script_log 2>&1"`
    eval 'echo "-- Mise en place dans le cron..."' $mon_log_perso
    crontab -l > mon_cron.txt
    echo -e "$ajout_cron" >> mon_cron.txt
    crontab mon_cron.txt
    rm -f mon_cron.txt
    eval 'echo "-- Cron mis à jour"' $mon_log_perso
  else
    eval 'echo -e "\e[101mLE SCRIPT EST PRÉSENT DANS LE CRON\e[0m"' $mon_log_perso
  fi
fi
 
#### Vérification/création du fichier conf
if [[ -f $mon_script_config ]] ; then
  eval 'echo -e "\e[42mLE FICHIER CONF EST PRESENT\e[0m"' $mon_log_perso
else
  eval 'echo -e "\e[41mLE FICHIER CONF EST ABSENT\e[0m"' $mon_log_perso
  eval 'echo "-- Création du fichier conf..."' $mon_log_perso
  touch "$mon_script_config"
  chmod 777 "$mon_script_config"
cat <<EOT >> "$mon_script_config"
####################################
## Configuration
####################################
 
#### Mise à jour forcée
## à n'utiliser qu'en cas de soucis avec la vérification de process (oui/non)
maj_force="non"
 
#### Chemin complet vers le script source (pour les maj)
script_url=""
 
#### Informations
nom_serveur="ARK: Survival Evolved"
 
#### Version des mods à installer : Windows ou Linux
mod_branch="Windows"
 
#### Compte utilisateur à utiliser
user_arkserver=""
 
#### Paramètre du push
## ces réglages se trouvent sur le site http://www.pushover.net
token_app=""
destinataire_1=""
destinataire_2=""
titre_push=""
 
####################################
## Fin de configuration
####################################
EOT
  eval 'echo "-- Fichier conf créé"'
  eval 'echo "Vous dever éditer le fichier \"$mon_script_config\" avant de poursuivre"'
  eval 'echo "Vous pouvez utiliser: ./"$mon_script_fichier" --edit-config"'
  rm $pid_script
  exit 1
fi
 
echo "------"
 
#### VERIFICATION DES DEPENDANCES
##########################
eval 'echo -e "\e[44m\u2263\u2263  \e[0m \e[44m \e[1mVÉRIFICATION DE(S) DÉPENDANCE(S)  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m"' $mon_log_perso
 
#### Vérification et installation des repositories (apt)
for repo in $required_repos ; do
  ppa_court=`echo $repo | sed 's/.*ppa://' | sed 's/\/ppa//'`
  check_repo=`grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/* | grep "$ppa_court"`
    if [[ "$check_repo" == "" ]]; then
      add-apt-repository $repo -y
      update_a_faire="1"
    else
      eval 'echo -e "[\e[42m\u2713 \e[0m] Le dépôt apt: "$repo" est installé"' $mon_log_perso
    fi
done
if [[ "$update_a_faire" == "1" ]]; then
  apt update
fi
 
#### Vérification et installation des outils requis si besoin (apt)
for tools in $required_tools ; do
  check_tool=`dpkg --get-selections | grep -w "$tools"`
    if [[ "$check_tool" == "" ]]; then
      apt-get install $tools -y
    else
      eval 'echo -e "[\e[42m\u2713 \e[0m] La dépendance: "$tools" est installée"' $mon_log_perso
    fi
done
 
#### Vérification et installation des outils requis si besoin (pip)
for tools_pip in $required_tools_pip ; do
  check_tool=`pip freeze | grep "$tools_pip"`
    if [[ "$check_tool" == "" ]]; then
      pip install $tools_pip
    else
      eval 'echo -e "[\e[42m\u2713 \e[0m] La dépendance: "$tools_pip" est installée"' $mon_log_perso
    fi
done
 
#### Ajout de ce script dans le menu
if [[ -f "/etc/xdg/menus/applications-merged/scripts-scoony.menu" ]] ; then
  useless=1
else
  echo "... création du menu"
  mkdir -p /etc/xdg/menus/applications-merged
  touch "/etc/xdg/menus/applications-merged/scripts-scoony.menu"
  cat <<EOT >> /etc/xdg/menus/applications-merged/scripts-scoony.menu
<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
"http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
<Menu>
<Name>Applications</Name>
 
<Menu> <!-- scripts-scoony -->
<Name>scripts-scoony</Name>
<Directory>scripts-scoony.directory</Directory>
<Include>
<Category>X-scripts-scoony</Category>
</Include>
</Menu> <!-- End scripts-scoony -->
 
</Menu> <!-- End Applications -->
EOT
  echo "... menu créé"
fi
 
if [[ -f "/usr/share/desktop-directories/scripts-scoony.directory" ]] ; then
  useless=1
else
## je met l'icone en place
  wget -q http://i.imgur.com/XRCxvJK.png -O /usr/share/icons/scripts.png
  echo "... création du dossier du menu"
  if [[ ! -d "/usr/share/desktop-directories" ]] ; then
    mkdir -p /usr/share/desktop-directories
  fi
  touch "/usr/share/desktop-directories/scripts-scoony.directory"
  cat <<EOT >> /usr/share/desktop-directories/scripts-scoony.directory
[Desktop Entry]
Type=Directory
Name=Scripts Scoony
Icon=/usr/share/icons/scripts.png
EOT
fi
 
if [[ -f "/usr/local/share/applications/$mon_script_desktop" ]] ; then
  useless=1
else
  wget -q $icone_imgur -O /usr/share/icons/$mon_script_base.png
  if [[ -d "/usr/local/share/applications" ]]; then
    useless="1"
  else
    mkdir -p /usr/local/share/applications
  fi
  touch "/usr/local/share/applications/$mon_script_base.desktop"
  cat <<EOT >> /usr/local/share/applications/$mon_script_base.desktop
#!/usr/bin/env xdg-open
[Desktop Entry]
Type=Application
Terminal=true
Name=Script $mon_script_base
Icon=/usr/share/icons/$mon_script_base.png
Exec=/opt/scripts/$mon_script_fichier --menu
Comment[fr_FR]=$description
Comment=$description
Categories=X-scripts-scoony;
EOT
fi
 
####################
## On commence enfin
####################
 
cd /opt/scripts
 
### Déclaration des variables pour les couleurs des textes
GREEN="\\033[1;32m"
RED="\\033[1;31m"
YELLOW="\\e[0;33m"
NORMAL="\\033[0;39m"
restart_necessaire="" # Variable permettant le restart du serveur
 
eval 'echo -e "\e[44m\u2263\u2263  \e[0m \e[44m \e[1mINFORMATIONS SERVEUR  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m"' $mon_log_perso

updatedb &
pid=$!
spin='-\|/'
i=0
while kill -0 $pid 2>/dev/null
do
  i=$(( (i+1) %4 ))
  printf "\r[  ] Vérification de la version du serveur ... ${spin:$i:1}"
  sleep .1
done
printf "$mon_printf" && printf "\r"
chemin_serveur=`locate \/arkserver | sed '/\/usb_save\//d' | sed '/\/lgsm\//d' | sed '/\/log\//d' | sed '/\/.config\/argos\//d' | grep "\/arkserver$" | xargs dirname`
liste_serveurs=`locate \/arkserver | grep "$chemin_serveur" | sed '/\/usb_save\//d' | sed '/\/lgsm\//d' | sed '/\/log\//d' | sed -e "s|$chemin_serveur\/||g"`

rm -rf ~/.steam/appcache
steamcmd +login anonymous +app_info_update 1 +app_info_print 376030 +quit > $dossier_config/availablebuild.log &
pid=$!
spin='-\|/'
i=0
while kill -0 $pid 2>/dev/null
do
  i=$(( (i+1) %4 ))
  printf "\r[  ] Vérification de la version du serveur ... ${spin:$i:1}"
  sleep .1
done
printf "$mon_printf" && printf "\r"
availablebuild=`cat $dossier_config/availablebuild.log | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3`
rm $dossier_config/availablebuild.log

if [ -n "$nom_serveur" ] && [ -n "$chemin_serveur" ]; then
  currentbuild=`grep buildid "$chemin_serveur/serverfiles/steamapps/appmanifest_376030.acf" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d\  -f3`
  
  compare=`testvercomp $currentbuild $availablebuild '<' | grep Pass`
  if [[ "$compare" != "" ]] ; then
    restart_necessaire="oui"
    eval 'echo -e "[\e[42m\u2713 \e[0m] Une mise à jour du serveur $nom_serveur est disponible:"' $mon_log_perso
    eval 'echo -e " ... Build actuelle: $RED$currentbuild$NORMAL"' $mon_log_perso
    eval 'echo -e " ... Build disponible: $GREEN$availablebuild$NORMAL"' $mon_log_perso
    message_maj=`echo -e "Une mise à jour du serveur $nom_serveur est disponible.\n<b>Version actuelle:</b> "$currentbuild"\n<b>Version disponible:</b> "$availablebuild`
    for user in {1..10}; do
      destinataire=`eval echo "\\$destinataire_"$user`
      if [ -n "$destinataire" ]; then
        curl -s \
          --form-string "token=$token_app" \
          --form-string "user=$destinataire" \
          --form-string "title=Mise à jour disponible" \
          --form-string "message=$message_maj" \
          --form-string "html=1" \
          --form-string "priority=-1" \
          https://api.pushover.net/1/messages.json > /dev/null
      fi
    done
  else
    eval 'echo -e "[\e[42m\u2713 \e[0m] Serveur à jour $nom_serveur:"' $mon_log_perso
    eval 'echo -e " ... Build actuelle: $GREEN$currentbuild$NORMAL"' $mon_log_perso
  fi
fi

eval 'echo -e "\e[44m\u2263\u2263  \e[0m \e[44m \e[1mTÉLÉCHARGEMENTS DES MODS  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m"' $mon_log_perso

if [[ "$mod_branch" == "Linux" ]]; then
  eval 'echo -e "[\e[43m\u2713 \e[0m] Les mods seront téléchargés en version Linux. Il est conseillé de les prendre en version Windows, la version Linux peut causer des plantages du server."' $mon_log_perso
else
  if [[ "$mod_branch" == "Windows" ]]; then
    eval 'echo -e "[\e[42m\u2713 \e[0m] Les mods seront téléchargés en version Windows."' $mon_log_perso
  else
    eval 'echo -e "[\e[41m\u2717 \e[0m] Le paramètre mod_branch est à configurer. Il est conseillé de les prendre en version Windows, la version Linux peut causer des plantages du server."' $mon_log_perso
    eval 'echo -e "[\e[42m\u2713 \e[0m] Les mods seront téléchargés en version Windows."' $mon_log_perso
    mod_branch="Windows"
  fi
fi

chemin_GameUserSettings=`echo $chemin_serveur"/serverfiles/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini"`
if [[ -f "$chemin_GameUserSettings" ]]; then
  activemods=`cat "$chemin_GameUserSettings" | grep "ActiveMods=" | sed -e "s/ActiveMods=//g"`
  if [[ -n "$activemods" ]]; then
    eval 'echo -e "[\e[42m\u2713 \e[0m] Mods présent dans le fichier de configuration du serveur :\n ... "$activemods' $mon_log_perso
  fi
fi

modinfo_db="/root/.config/updatemods/modinfo.db"
if [[ -f "$modinfo_db" ]] ; then
  source "$modinfo_db"
else
  touch "$modinfo_db"
  chmod 777 "$modinfo_db"
fi 
 
for modId in ${activemods//,/ }; do
  modDestDir=`echo $chemin_serveur"/serverfiles/ShooterGame/Content/Mods/"$modId`
  modExtractDir=`echo "/opt/scripts/SteamDL/Mods/"$modId`
  modName=`eval echo "\\$Mod_"$modId`
  if [[ ! -n "$modName" ]]; then
    printf "\r[  ] Téléchargement du nom du Mod "$modId" ..."
    modName="$(curl -s "https://steamcommunity.com/sharedfiles/filedetails/?id=${modId}" | sed -n 's|^.*<div class="workshopItemTitle">\([^<]*\)</div>.*|\1|p')"  
    printf "$mon_printf" && printf "\r"
    echo "Mod_"$modId"=\""$modName"\"" >> /root/.config/updatemods/modinfo.db
  fi
  
  info_version_mod_disponible=`curl -s "https://steamcommunity.com/sharedfiles/filedetails/?id=$modId" | sed -n 's|^.*<div class="detailsStatRight">\([^<]*\)</div>.*|\1|p'`
  info_version_mod_disponible=`echo $info_version_mod_disponible | cut -d" " -f8-`
  info_version_mod_local=""
  if [[ -f "$modExtractDir/.updatemods.info" ]];then 
    info_version_mod_local=`cat "$modExtractDir/.updatemods.info"`
  fi
  if [ "$info_version_mod_disponible" != "$info_version_mod_local" ]; then
    eval 'echo -e "[\e[41m\u2717 \e[0m] Mise à jour du mod $modName ($modId) nécessaire"' $mon_log_perso
    steamcmd +login anonymous +workshop_download_item 346110 $modId +quit > steamdl.log &
    pid=$!
    spin='-\|/'
    i=0
    while kill -0 $pid 2>/dev/null
    do
      i=$(( (i+1) %4 ))
      printf "\r[  ] Téléchargement du mod $modName ($modId) ... ${spin:$i:1}"
      sleep .1
    done
    printf "$mon_printf" && printf "\r"
    echo -e "\nEnd of downloading." >> steamdl.log
    modSrcDir=""
    while IFS= read -r -d $'\n'; do
      modDir=`echo "$REPLY" | sed -n 's@^Success. Downloaded item '$modId' to "\([^"]*\)" .*@\1@p'`
      if [[ "$modDir" != "" ]]; then
      modSrcDir=$modDir
      fi
    done <steamdl.log
    rm steamdl.log
    
    if [[ "$modSrcDir" != "" ]]; then
      message="[\e[42m\u2713 \e[0m] Mod $modName ($modId) téléchargé"
      if [[ "$debug" == "oui" ]]; then
        message=$message": "$modSrcDir
      fi
      eval 'echo -e $message' $mon_log_perso
      
      if [ -f "$modSrcDir/mod.info" ]; then
        message="\r[  ] Extraction des fichiers"
        if [[ "$debug" == "oui" ]]; then
          message=$message" vers "$modExtractDir
        fi
        printf $message
        
        if [ -f "$modSrcDir/${mod_branch}NoEditor/mod.info" ]; then
          modSrcDir="$modSrcDir/${mod_branch}NoEditor"
        fi
        
        find "$modSrcDir" -type d -printf "$modExtractDir/%P\0" | xargs -0 -r mkdir -p
        
        find "$modExtractDir" -type f ! -name '.*' -printf "%P\n" | while read f; do
          if [ \( ! -f "$modSrcDir/$f" \) -a \( ! -f "$modSrcDir/${f}.z" \) ]; then
            rm "$modExtractDir/$f"
          fi
        done
        
        find "$modExtractDir" -depth -type d -printf "%P\n" | while read d; do
          if [ ! -d "$modSrcDir/$d" ]; then
            rmdir "$modExtractDir/$d"
          fi
        done
        
        find "$modSrcDir" -type f ! \( -name '*.z' -or -name '*.z.uncompressed_size' \) -printf "%P\n" | while read f; do
          if [ \( ! -f "$modExtractDir/$f" \) -o "$modSrcDir/$f" -nt "$modExtractDir/$f" ]; then
            #printf "%10d  %s  " "`stat -c '%s' "$modSrcDir/$f"`" "$f"
            cp "$modSrcDir/$f" "$modExtractDir/$f"
            #echo -ne "\r\\033[K"
          fi
        done
        
        find "$modSrcDir" -type f -name '*.z' -printf "%P\n" | while read f; do
          if [ \( ! -f "$modExtractDir/${f%.z}" \) -o "$modSrcDir/$f" -nt "$modExtractDir/${f%.z}" ]; then
            #printf "%10d  %s  " "`stat -c '%s' "$modSrcDir/$f"`" "${f%.z}"
            perl -M'Compress::Raw::Zlib' -e '
              my $sig;
              read(STDIN, $sig, 8) or die "Unable to read compressed file: $!";
              if ($sig != "\xC1\x83\x2A\x9E\x00\x00\x00\x00"){
                die "Bad file magic";
              }
              my $data;
              read(STDIN, $data, 24) or die "Unable to read compressed file: $!";
              my ($chunksizelo, $chunksizehi,
                $comprtotlo,  $comprtothi,
                $uncomtotlo,  $uncomtothi)  = unpack("(LLLLLL)<", $data);
              my @chunks = ();
              my $comprused = 0;
              while ($comprused < $comprtotlo) {
                read(STDIN, $data, 16) or die "Unable to read compressed file: $!";
                my ($comprsizelo, $comprsizehi,
                  $uncomsizelo, $uncomsizehi) = unpack("(LLLL)<", $data);
                push @chunks, $comprsizelo;
                $comprused += $comprsizelo;
              }
              foreach my $comprsize (@chunks) {
                read(STDIN, $data, $comprsize) or die "File read failed: $!";
                my ($inflate, $status) = new Compress::Raw::Zlib::Inflate();
                my $output;
                $status = $inflate->inflate($data, $output, 1);
                if ($status != Z_STREAM_END) {
                  die "Bad compressed stream; status: " . ($status);
                }
                if (length($data) != 0) {
                  die "Unconsumed data in input"
                }
                print $output;
              }
            ' <"$modSrcDir/$f" >"$modExtractDir/${f%.z}"
            touch -c -r "$modSrcDir/$f" "$modExtractDir/${f%.z}"
            #echo -ne "\r\\033[K"
          fi
        done
        
        if [ -f "${modExtractDir}/.mod" ]; then
          rm "${modExtractDir}/.mod"
        fi
        
        perl -e '
          my $data;
          { local $/; $data = <STDIN>; }
          my $mapnamelen = unpack("@0 L<", $data);
          my $mapname = substr($data, 4, $mapnamelen - 1);
          my $nummaps = unpack("@" . ($mapnamelen + 4) . " L<", $data);
          my $pos = $mapnamelen + 8;
          my $modname = ($ARGV[1] || $mapname) . "\x00";
          my $modnamelen = length($modname);
          my $modpath = "../../../ShooterGame/Content/Mods/" . $ARGV[0] . "\x00";
          my $modpathlen = length($modpath);
          print pack("L< L< L< Z$modnamelen L< Z$modpathlen L<",
            $ARGV[0], 0, $modnamelen, $modname, $modpathlen, $modpath,
            $nummaps);
          for (my $mapnum = 0; $mapnum < $nummaps; $mapnum++){
            my $mapfilelen = unpack("@" . ($pos) . " L<", $data);
            my $mapfile = substr($data, $mapnamelen + 12, $mapfilelen);
            print pack("L< Z$mapfilelen", $mapfilelen, $mapfile);
            $pos = $pos + 4 + $mapfilelen;
          }
          print "\x33\xFF\x22\xFF\x02\x00\x00\x00\x01";
        ' $modId "$modName" <"$modExtractDir/mod.info" >"${modExtractDir}.mod"
        
        if [ -f "$modExtractDir/modmeta.info" ]; then
          cat "$modExtractDir/modmeta.info" >>"${modExtractDir}.mod"
        else
          echo -ne '\x01\x00\x00\x00\x08\x00\x00\x00ModType\x00\x02\x00\x00\x001\x00' >>"${modExtractDir}.mod"
        fi
        
        info_version_mod=`curl -s "https://steamcommunity.com/sharedfiles/filedetails/?id=$modId" | sed -n 's|^.*<div class="detailsStatRight">\([^<]*\)</div>.*|\1|p'`
        info_version_mod=`echo $info_version_mod | cut -d" " -f8-`
        echo $info_version_mod > "$modExtractDir/.updatemods.info"
        
        message="\r[\e[42m\u2713 \e[0m] Extraction des fichiers"
        if [[ "$debug" == "oui" ]]; then
          message=$message" vers "$modExtractDir
        fi
        restart_necessaire="oui"
        eval 'echo -e $message' $mon_log_perso
        
        ## Copie vers le dossier MOD d'ARK
        if [[ "$modExtractDir" != "$modDestDir" ]]; then
          message="\r[  ] Copie des fichiers"
          if [[ "$debug" == "oui" ]]; then
            message=$message" vers "$modExtractDir
          fi
          printf $message
          if [ ! -d "${modDestDir}" ]; then
            mkdir -p "${modDestDir}"
          fi
          cp -au --remove-destination "${modExtractDir}/." "${modDestDir}"
          find "${modDestDir}" -type f ! -name '.*' -printf "%P\n" | while read f; do
            if [ ! -f "${modExtractDir}/${f}" ]; then
              rm "${modDestDir}/${f}"
            fi
          done
          find "$modExtractDir" -depth -type d -printf "%P\n" | while read d; do
            if [ ! -d "$modSrcDir/$d" ]; then
              rmdir "$modExtractDir/$d"
            fi
          done
          cp -u "${modExtractDir}.mod" "${modDestDir}.mod"
          message="\r[\e[42m\u2713 \e[0m] Copie des fichiers"
          if [[ "$debug" == "oui" ]]; then
            message=$message" vers "$modDestDir
          fi
          eval 'echo -e $message' $mon_log_perso
        fi
      fi
    echo " ---"
    else
      eval 'echo -e "[\e[41m\u2717 \e[0m] Erreur lors du téléchargement du mod $modName ($modId)."' $mon_log_perso
    fi
  else
    eval 'echo -e "[\e[42m\u2713 \e[0m] Mod $modName ($modId) à jour"' $mon_log_perso
  fi
done

eval 'echo -e "\e[44m\u2263\u2263  \e[0m \e[44m \e[1mREDÉMARRAGE DU SERVEUR  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m"' $mon_log_perso
if [[ "$restart_necessaire" == "oui" ]]; then
  restart="non"
  #### Recupération des infos serveur ARK
  sh_serveurs=()
  map_serveurs=()
  sessionname_serveurs=()
  port_serveurs=()
  for sh_actuel in $liste_serveurs ; do
    sh_serveurs+=("$sh_actuel")
    if [[ -f "$chemin_serveur/lgsm/config-lgsm/arkserver/$sh_actuel.cfg" ]]; then
      map_serveurs+=(`cat "$chemin_serveur/lgsm/config-lgsm/arkserver/$sh_actuel.cfg" | grep "^defaultmap=" | sed -e "s/defaultmap=\"//g" | sed -e "s/\"//g"`)
      serveur_name=`cat "$chemin_serveur/lgsm/config-lgsm/arkserver/$sh_actuel.cfg" | grep "SessionName=" | sed 's/.*SessionName=//g' | sed 's/?.*//g'`
      sessionname_serveurs+=("$serveur_name")
      port_serveurs+=(`cat "$chemin_serveur/lgsm/config-lgsm/arkserver/$sh_actuel.cfg" | grep "^port=" | sed -e "s/port=\"//g" | sed -e "s/\"//g"`)
    fi
  done
  nombre_serveur=`echo ${#map_serveurs[@]}`
  
  ### Création du script de reboot du serveur
  chmod 777 -R "$chemin_serveur"
  chown $user_arkserver:$user_arkserver -R "$chemin_serveur"
  echo "#!/bin/bash" > /opt/scripts/ark-restart.sh
  echo "mon_printf=\"\\r                                                                                           \"" >> /opt/scripts/ark-restart.sh
  numero_serveur=0
  while [[ $numero_serveur != $nombre_serveur ]]; do  
    process_arkserver=`ps aux | grep "./ShooterGameServer ${map_serveurs[$numero_serveur]}" | grep "?Port=${port_serveurs[$numero_serveur]}?" | sed '/grep/d' | awk '{print $2}'`
    if [[ "$process_arkserver" != "" ]]; then
      echo "bash \"$chemin_serveur/${sh_serveurs[$numero_serveur]}\" restart > /opt/scripts/ark-restart.log &" >> /opt/scripts/ark-restart.sh
      echo "pid=\$!" >> /opt/scripts/ark-restart.sh
      echo "spin='-\|/'" >> /opt/scripts/ark-restart.sh
      echo "i=0" >> /opt/scripts/ark-restart.sh
      echo "while kill -0 \$pid 2>/dev/null" >> /opt/scripts/ark-restart.sh
      echo "do" >> /opt/scripts/ark-restart.sh
      echo "  i=\$(( (i+1) %4 ))" >> /opt/scripts/ark-restart.sh
      echo "  printf \"\\r[  ] Redémarrage du serveur ${sessionname_serveurs[$numero_serveur]} ... \${spin:\$i:1}\"" >> /opt/scripts/ark-restart.sh
      echo "  sleep .1" >> /opt/scripts/ark-restart.sh
      echo "done" >> /opt/scripts/ark-restart.sh
      echo "printf \"\$mon_printf\" && printf \"\\r\"" >> /opt/scripts/ark-restart.sh
      echo "echo -e \"\\r[\\e[42m\\u2713 \e[0m] Redémarrage du serveur ${sessionname_serveurs[$numero_serveur]}\"" >> /opt/scripts/ark-restart.sh
      restart="oui"
    fi
    numero_serveur=$(expr $numero_serveur + 1)
  done
  chmod +x /opt/scripts/ark-restart.sh
  if [[ "$restart" == "oui" ]]; then
su $user_arkserver <<'EOF'
bash /opt/scripts/ark-restart.sh
EOF
  else
    eval 'echo -e "\r[\e[42m\u2713 \e[0m] Pas de nécessité de redémarrer le serveur"' $mon_log_perso
  fi
  rm -f /opt/scripts/ark-restart.*
else
  eval 'echo -e "\r[\e[42m\u2713 \e[0m] Pas de nécessité de redémarrer le serveur"' $mon_log_perso
fi

rm "$pid_script"
fin_script=`date`
eval 'echo -e "\e[43m-- FIN DE SCRIPT: $fin_script --\e[0m"' $mon_log_perso
