#!/bin/bash

########################
## Script de Z0uZOU
########################
## Installation: wget -q https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/updatemods.sh -O updatemods.sh && sed -i -e 's/\r//g' updatemods.sh && shc -f updatemods.sh -o updatemods.bin && chmod +x updatemods.bin && rm -f *.x.c && rm -f updatemods.sh
## Installation: wget -q https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/updatemods.sh -O updatemods.sh && sed -i -e 's/\r//g' updatemods.sh && chmod +x updatemods.sh
## Micro-config
version="Version: 1.0.0.0" #base du système de mise à jour
description="Téléchargeur de Mods pour ARK: Survival Evolved" #description pour le menu
script_github="https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/updatemods.sh" #emplacement du script original
changelog_github="https://pastebin.com/raw/vJpabVtT" #emplacement du changelog de ce script
icone_imgur="http://i.imgur.com/dasbwhC.png" #emplacement de l'icône du script
required_repos="ppa:neurobin/ppa" #ajout de repository
required_tools="curl shc steamcmd" #dépendances du script
required_tools_pip="" #dépendances du script (PIP)
script_cron="0 * * * *" #ne définir que la planification
verification_process="" #si ces process sont détectés on ne notifie pas (ou ne lance pas en doublon)
########################

#### Initialisation des variables
debug="non"
force_dl="non"
force_update="non"
force_copy="non"
no_update="non"


#### Vérification de la langue du system
if [[ "$@" =~ "--langue=" ]]; then
  affichage_langue=`echo "$@" | sed 's/.*--langue=//' | sed 's/ .*//' | tr '[:upper:]' '[:lower:]'`
else
  affichage_langue=$(locale | grep LANG | sed -n '1p' | cut -d= -f2 | cut -d_ -f1)
fi
verif_langue=`curl -s "https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/MUI/$affichage_langue.lang"`
if [[ "$verif_langue" == "404: Not Found" ]]; then
  affichage_langue="en"
fi


#### Déduction des noms des fichiers (pour un portage facile)
mon_script_fichier=`basename "$0"`
mon_script_base=`echo ''$mon_script_fichier | cut -f1 -d'.'''`
mon_script_base_maj=`echo ${mon_script_base^^}`
mon_dossier_config=`echo "/root/.config/"$mon_script_base`
mon_script_config=`echo $mon_dossier_config"/"$mon_script_base".conf"`
mon_script_langue=`echo $mon_dossier_config"/MUI/"$affichage_langue".lang"`
mon_script_desktop=`echo $mon_script_base".desktop"`
mon_script_updater=`echo $mon_script_base"-update.sh"`
mon_script_pid=`echo $mon_dossier_config"/lock-"$mon_script_base`
mon_path_log=`echo $mon_dossier_config"/log"`
date_log=`date +%Y%m%d`
heure_log=`date +%H%M`
mon_fichier_log=`echo $mon_path_log"/"$date_log"/"$heure_log".log"`


#### Vérification que le script possède les droits root
## NE PAS TOUCHER
if [ "$(whoami)" != "root" ]; then
  if [[ "$CRON_SCRIPT" == "oui" ]]; then
    exit 1
  else
    source <(curl -s https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/MUI/$affichage_langue.lang)
    echo "$mui_root_check"
    exit 1
  fi
fi


#### Chargement du fichier pour la langue (ou installation)
if [[ -f "$mon_script_langue" ]]; then
  distant_md5=`curl -s "https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/MUI/$affichage_langue.lang" | md5sum | cut -f1 -d" "`
  local_md5=`md5sum "$mon_script_langue" 2>/dev/null | cut -f1 -d" "`
  if [[ $distant_md5 != $local_md5 ]]; then
    wget --quiet "https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/MUI/$affichage_langue.lang" -O "$mon_script_langue"
    chmod +x "$mon_script_langue"
  fi
else
  wget --quiet "https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/MUI/$affichage_langue.lang" -O "$mon_script_langue"
  chmod +x "$mon_script_langue"
fi
source $mon_script_langue


#### Fonction pour envoyer des push
push-message() {
  push_title=$1
  push_content=$2
  push_priority=$3
  for user in {1..10}; do
    destinataire=`eval echo "\\$destinataire_"$user`
    if [ -n "$destinataire" ]; then
      curl -s \
        --form-string "token=$token_app" \
        --form-string "user=$destinataire" \
        --form-string "title=$push_title" \
        --form-string "message=$push_content" \
        --form-string "html=1" \
        --form-string "priority=$push_priority" \
        https://api.pushover.net/1/messages.json > /dev/null
    fi
  done
}


#### Vérification de process pour éviter les doublons (commandes externes)
for process_travail in $verification_process ; do
  process_important=`ps aux | grep $process_travail | sed '/grep/d'`
  if [[ "$process_important" != "" ]] ; then
    if [[ "$CRON_SCRIPT" != "oui" ]] ; then
      echo "$process_travail $mui_prevent_dupe_task"
      end_of_script=`date`
      source $mon_script_langue
      my_title_count=`echo -n "$mui_end_of_script" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | sed 's/é/e/g' | wc -c`
      line_lengh="78"
      before_count=$((($line_lengh-$my_title_count)/2))
      after_count=$(((($line_lengh-$my_title_count)%2)+$before_count))
      before=`eval printf "%0.s-" {1..$before_count}`
      after=`eval printf "%0.s-" {1..$after_count}`
      printf "\e[43m%s%s%s\e[0m\n" "$before" "$mui_end_of_script" "$after"
    fi
    exit 1
  fi
done


#### Tests des arguments
for parametre in $@; do
  if [[ "$parametre" == "--debug" ]]; then
    debug="yes"
  fi
  if [[ "$parametre" == "--edit-config" ]]; then
    nano $mon_script_config
    exit 1
  fi
  if [[ "$parametre" == "--efface-lock" ]]; then
    mon_lock=`echo $mon_dossier_config"/lock-"$mon_script_base`
    rm -f "$mon_lock"
    echo -e "$mui_lock_removed"
    exit 1
  fi
  if [[ "$parametre" == "--statut-lock" ]]; then
    statut_lock=`cat $mon_script_config | grep "maj_force=\"oui\""`
    if [[ "$statut_lock" == "" ]]; then
      echo -e "$mui_lock_status_on"
    else
      echo -e "$mui_lock_status_off"
    fi
    exit 1
  fi
  if [[ "$parametre" == "--active-lock" ]]; then
    sed -i 's/maj_force="oui"/maj_force="non"/g' $mon_script_config
    echo -e "$mui_lock_status_on"
    exit 1
  fi
  if [[ "$parametre" == "--desactive-lock" ]]; then
    sed -i 's/maj_force="non"/maj_force="oui"/g' $mon_script_config
    echo -e "$mui_lock_status_off"
    exit 1
  fi
  if [[ "$parametre" == "--extra-log" ]]; then
    mon_log_perso="| tee -a $mon_fichier_log"
  fi
  if [[ "$parametre" == "--purge-process" ]]; then
    pgrep -x "$mon_script_fichier" | xargs kill -9
    echo -e "$mui_purge_process"
    exit 1
  fi
  if [[ "$parametre" == "--purge-log" ]]; then
    cd $mon_path_log
    mon_chemin=`echo $PWD`
    if [[ "$mon_chemin" == "$mon_path_log" ]]; then
      printf "$mui_purge_log_question : "
      read question_effacement
      reponse_effacement=`echo $question_effacement | tr '[:upper:]' '[:lower:]'`
      if [[ "$reponse_effacement" == "$mui_purge_log_answer_yes" ]]; then
        rm -rf *
        echo -e "$mui_purge_log_done"
      fi
    else
      echo -e "$mui_purge_log_ko"
    fi
    exit 1
  fi
  if [[ "$parametre" == "--help" ]]; then
    i=""
    for i in _ {a..z} {A..Z}; do eval "echo \${!$i@}" ; done | xargs printf "%s\n" | grep mui_menu_help > variables
    help_lignes=`wc -l variables | awk '{print $1}'`
    rm -f variables
    j=""
    mui_menu_help="mui_menu_help_"
    for j in $(seq 1 $help_lignes); do
      source $mon_script_langue
      mui_menu_help_display=`echo -e "$mui_menu_help$j"`
      echo -e "${!mui_menu_help_display}"
    done
    exit 1
  fi
  if [[ "$parametre" == "--force-dl" ]]; then
    force_dl="oui"
  fi
  if [[ "$parametre" == "--force-update" ]]; then
    force_update="oui"
  fi
  if [[ "$parametre" == "--force-copy" ]]; then
    force_copy="oui"
  fi
  if [[ "$parametre" == "--no-update" ]]; then
    no_update="oui"
  fi
done


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

#### Chargement du fichier conf si présent
if [[ -f "$mon_script_config" ]] ; then
  source $mon_script_config
fi


#### Vérification qu'au reboot les lock soient bien supprimés
test_crontab=`crontab -l | grep "clean-lock"`
if [[ "$test_crontab" == "" ]]; then
  crontab -l > $dossier_config/mon_cron.txt
  sed -i '5i@reboot\t\t\tsleep 10 && /opt/scripts/clean-lock.sh' $dossier_config/mon_cron.txt
  crontab $dossier_config/mon_cron.txt
  rm -f $dossier_config/mon_cron.txt
fi


#### Vérification qu'une autre instance de ce script ne s'exécute pas
if [[ "$maj_force" == "non" ]] ; then
  if [[ -f "$mon_script_pid" ]] ; then
    computer_name=`hostname`
    source $mon_script_langue
    echo "$mui_pid_check"
    push-message "$mui_pid_check_title" "$mui_pid_check" "1"
    exit 1
  fi
fi
touch $mon_script_pid


#### Chemin du script
## necessaire pour le mettre dans le cron
cd /opt/scripts

#### Indispensable aux messages de chargement
mon_printf="\r                                                                                                                                "

#### Nettoyage obligatoire et push pour annoncer la maj
if [[ -f "$mon_script_updater" ]] ; then
  rm "$mon_script_updater"
  computer_name=`hostname`
  source $mon_script_langue
  push-message "$mui_pushover_updated_title" "$mui_pushover_updated_msg" "1"
fi


#### Vérification de version pour éventuelle mise à jour
distant_md5=`curl -s "$script_github" | md5sum | cut -f1 -d" "`
local_md5=`md5sum "$0" 2>/dev/null | cut -f1 -d" "`
if [[ $distant_md5 != $local_md5 ]]; then
  eval 'echo -e "$mui_update_available"' $mon_log_perso
  if [[ "$no_update" == "non" ]]; then
    eval 'echo -e "$mui_update_download"' $mon_log_perso
    touch $mon_script_updater
    chmod +x $mon_script_updater
    echo "#!/bin/bash" >> $mon_script_updater
    mon_script_fichier_temp=`echo $mon_script_fichier"-temp"`
    echo "wget -q $script_github -O $mon_script_fichier_temp" >> $mon_script_updater
    echo "sed -i -e 's/\r//g' $mon_script_fichier_temp" >> $mon_script_updater
    echo "mv $mon_script_fichier_temp $mon_script_fichier" >> $mon_script_updater
    echo "chmod +x $mon_script_fichier" >> $mon_script_updater
    echo "chmod 777 $mon_script_fichier" >> $mon_script_updater
    echo "$mui_update_done" >> $mon_script_updater
    echo "bash $mon_script_fichier $@" >> $mon_script_updater
    echo "exit 1" >> $mon_script_updater
    rm "$mon_script_pid"
    bash $mon_script_updater
    exit 1
  else
    eval 'echo -e "$mui_update_not_downloaded"' $mon_log_perso
  fi
fi
source $mon_script_langue
my_title_count=`echo -n "$mui_title" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | wc -c`
line_lengh="78"
before_count=$((($line_lengh-$my_title_count)/2))
after_count=$(((($line_lengh-$my_title_count)%2)+$before_count))
before=`eval printf "%0.s-" {1..$before_count}`
after=`eval printf "%0.s-" {1..$after_count}`
eval 'printf "\e[43m%s%s%s\e[0m\n" "$before" "$mui_title" "$after"' $mon_log_perso


#### Nécessaire pour l'argument --update
if [[ "$@" == "--update" ]]; then
  rm "$mon_script_pid"
  exit 1
fi


#### Vérification de la conformité du cron
crontab -l > $dossier_config/mon_cron.txt
cron_path=`cat $dossier_config/mon_cron.txt | grep "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"`
if [[ "$cron_path" == "" ]]; then
  sed -i '1iPATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin' $dossier_config/mon_cron.txt
  cron_a_appliquer="oui"
fi
cron_lang=`cat $dossier_config/mon_cron.txt | grep "LANG=fr_FR.UTF-8"`
if [[ "$cron_lang" == "" ]]; then
  sed -i '1iLANG=fr_FR.UTF-8' $dossier_config/mon_cron.txt
  cron_a_appliquer="oui"
fi
cron_variable=`cat $dossier_config/mon_cron.txt | grep "CRON_SCRIPT=\"oui\""`
if [[ "$cron_variable" == "" ]]; then
  sed -i '1iCRON_SCRIPT="oui"' $dossier_config/mon_cron.txt
  cron_a_appliquer="oui"
fi
if [[ "$cron_a_appliquer" == "oui" ]]; then
  crontab $dossier_config/mon_cron.txt
  rm -f $dossier_config/mon_cron.txt
  eval 'echo -e "$mui_cron_path_updated"' $mon_log_perso
else
  rm -f $dossier_config/mon_cron.txt
fi

#### Mise en place éventuelle d'un cron
if [[ "$script_cron" != "" ]]; then
  mon_cron=`crontab -l`
  verif_cron=`echo "$mon_cron" | grep "$mon_script_fichier"`
  if [[ "$verif_cron" == "" ]]; then
    my_title_count=`echo -n "$mui_no_cron_entry" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | wc -c`
    line_lengh="78"
    before_count=$((($line_lengh-$my_title_count)/2))
    after_count=$(((($line_lengh-$my_title_count)%2)+$before_count))
    before=`eval printf "%0.s-" {1..$before_count}`
    after=`eval printf "%0.s-" {1..$after_count}`
    eval 'printf "\e[41m%s%s%s\e[0m\n" "$before" "$mui_no_cron_entry" "$after"' $mon_log_perso
    eval 'echo "$mui_no_cron_creating"' $mon_log_perso
    ajout_cron=`echo -e "$script_cron\t\t/opt/scripts/$mon_script_fichier > /var/log/$mon_script_log 2>&1"`
    eval 'echo "$mui_no_cron_adding"' $mon_log_perso
    crontab -l > $dossier_config/mon_cron.txt
    echo -e "$ajout_cron" >> $dossier_config/mon_cron.txt
    crontab $dossier_config/mon_cron.txt
    rm -f $dossier_config/mon_cron.txt
    eval 'echo "$mui_no_cron_updated"' $mon_log_perso
  else
    if [[ "${verif_cron:0:1}" == "#" ]]; then	
      my_title_count=`echo -n "$mui_script_in_cron_disable" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | wc -c`
      line_lengh="78"
      before_count=$((($line_lengh-$my_title_count)/2))
      after_count=$(((($line_lengh-$my_title_count)%2)+$before_count))
      before=`eval printf "%0.s-" {1..$before_count}`
      after=`eval printf "%0.s-" {1..$after_count}`
      eval 'printf "\e[101m%s%s%s\e[0m\n" "$before" "$mui_script_in_cron_disable" "$after"' $mon_log_perso
	else
      my_title_count=`echo -n "$mui_script_in_cron" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | wc -c`
      line_lengh="78"
      before_count=$((($line_lengh-$my_title_count)/2))
      after_count=$(((($line_lengh-$my_title_count)%2)+$before_count))
      before=`eval printf "%0.s-" {1..$before_count}`
      after=`eval printf "%0.s-" {1..$after_count}`
      eval 'printf "\e[101m%s%s%s\e[0m\n" "$before" "$mui_script_in_cron" "$after"' $mon_log_perso
    fi
  fi
fi

#### Vérification/création du fichier conf
if [[ -f $mon_script_config ]] ; then
  my_title_count=`echo -n "$mui_conf_ok" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | wc -c`
  line_lengh="78"
  before_count=$((($line_lengh-$my_title_count)/2))
  after_count=$(((($line_lengh-$my_title_count)%2)+$before_count))
  before=`eval printf "%0.s-" {1..$before_count}`
  after=`eval printf "%0.s-" {1..$after_count}`
  eval 'printf "\e[42m%s%s%s\e[0m\n" "$before" "$mui_conf_ok" "$after"' $mon_log_perso
else
  my_title_count=`echo -n "$mui_conf_missing" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | wc -c`
  line_lengh="78"
  before_count=$((($line_lengh-$my_title_count)/2))
  after_count=$(((($line_lengh-$my_title_count)%2)+$before_count))
  before=`eval printf "%0.s-" {1..$before_count}`
  after=`eval printf "%0.s-" {1..$after_count}`
  eval 'printf "\e[41m%s%s%s\e[0m\n" "$before" "$mui_conf_missing" "$after"' $mon_log_perso
  eval 'echo "$mui_conf_creating"' $mon_log_perso
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
chemin_serveur=""

#### Version des mods à installer : Windows ou Linux
mod_branch="Windows"

#### Paramètre du push
## ces réglages se trouvent sur le site http://www.pushover.net
token_app=""
destinataire_1=""
destinataire_2=""
titre_push=""
push_maj_mod="oui"
push_maj_serveur="oui"
webhook_discord=""

####################################
## Fin de configuration
####################################
EOT
  eval 'echo "$mui_no_conf_created"'
  eval 'echo "$mui_no_conf_edit"'
  eval 'echo "mui_no_conf_help"'
  rm $pid_script
  exit 1
fi

echo "------------------------------------------------------------------------------"

#### VERIFICATION DES DEPENDANCES
##########################
eval 'printf  "\e[44m\u2263\u2263  \e[0m \e[44m \e[1m %-62s  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m\n" "$mui_section_dependencies"' $mon_log_perso

#### Vérification et installation des repositories (apt)
for repo in $required_repos ; do
  ppa_court=`echo $repo | sed 's/.*ppa://' | sed 's/\/ppa//'`
  check_repo=`grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/* | grep "$ppa_court"`
    if [[ "$check_repo" == "" ]]; then
      add-apt-repository $repo -y
      update_a_faire="1"
    else
      source $mon_script_langue
      eval 'echo -e "$mui_required_repository"' $mon_log_perso
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
      source $mon_script_langue
      eval 'echo -e "$mui_required_apt"' $mon_log_perso
    fi
done

#### Vérification et installation des outils requis si besoin (pip)
for tools_pip in $required_tools_pip ; do
  check_tool=`pip freeze | grep "$tools_pip"`
    if [[ "$check_tool" == "" ]]; then
      pip install $tools_pip
    else
      source $mon_script_langue
      eval 'echo -e "$mui_required_pip"' $mon_log_perso
    fi
done

#### Ajout de ce script dans le menu
if [[ -f "/etc/xdg/menus/applications-merged/scripts-scoony.menu" ]] ; then
  useless=1
else
  eval 'echo "$mui_creating_menu_entry"' $mon_log_perso
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
  eval 'echo "$mui_created_menu_entry"' $mon_log_perso
fi

if [[ -f "/usr/share/desktop-directories/scripts-scoony.directory" ]] ; then
  useless=1
else
## je met l'icone en place
  wget -q http://i.imgur.com/XRCxvJK.png -O /usr/share/icons/scripts.png
  eval 'echo "$mui_creating_menu_folder"' $mon_log_perso
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

#### vérification de la présence de 'rcon'
if [[ ! -f "$dossier_config/rcon" ]] ; then
  wget -q https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/prerequisites/rcon.c -O $dossier_config/rcon.c && gcc $dossier_config/rcon.c -o $dossier_config/rcon && chmod ugo+rx $dossier_config/rcon &
  pid=$!
  spin='-\|/'
  i=0
  while kill -0 $pid 2>/dev/null
  do
    i=$(( (i+1) %4 ))
    printf "\r$mui_required_install rcon ... ${spin:$i:1}"
    sleep .1
  done
  rm $dossier_config/rcon.c > /dev/null
  printf "$mon_printf" && printf "\r"
  eval 'echo -e "$mui_required_rcon"' $mon_log_perso
else
  eval 'echo -e "$mui_required_rcon"' $mon_log_perso
fi

#### vérification de la présence de 'discord.sh'
emplacement_script_discord="/opt/scripts/discord.sh"
if [[ ! -f "$emplacement_script_discord" ]] ; then
  wget -q https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/prerequisites/discord.sh -O $emplacement_script_discord && sed -i -e 's/\r//g' $emplacement_script_discord && chmod +x $emplacement_script_discord &
  pid=$!
  spin='-\|/'
  i=0
  while kill -0 $pid 2>/dev/null
  do
    i=$(( (i+1) %4 ))
    printf "\r$mui_required_install discord.sh ... ${spin:$i:1}"
    sleep .1
  done
  printf "$mon_printf" && printf "\r"
  eval 'echo -e "$mui_required_discord"' $mon_log_perso
else
  distant_md5=`curl -s "https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/prerequisites/discord.sh" | md5sum | cut -f1 -d" "`
  local_md5=`md5sum "$emplacement_script_discord" 2>/dev/null | cut -f1 -d" "`
  if [[ $distant_md5 != $local_md5 ]]; then
    wget -q https://raw.githubusercontent.com/Z0uZOU/ARKServer/master/prerequisites/discord.sh -O $emplacement_script_discord && sed -i -e 's/\r//g' $emplacement_script_discord && chmod +x $emplacement_script_discord &
    pid=$!
    spin='-\|/'
    i=0
    while kill -0 $pid 2>/dev/null
    do
      i=$(( (i+1) %4 ))
      printf "\r$mui_required_update discord.sh ... ${spin:$i:1}"
      sleep .1
    done
    printf "$mon_printf" && printf "\r"
  fi
  eval 'echo -e "$mui_required_discord"' $mon_log_perso
fi

config_discord="oui"
if [[ ! -f "/opt/scripts/.webhook" ]]; then
  if [[ "$webhook_discord" != "" ]]; then
    echo "$webhook_discord" > /opt/scripts/.webhook
    eval 'echo -e "[\e[42m\u2713 \e[0m] Utilisation du script \"discord.sh\": le fichier \".webhook\" a été créé, les notifications sur Discord seront envoyées"' $mon_log_perso
  else
    eval 'echo -e "[\e[41m\u2717 \e[0m] Utilisation du script \"discord.sh\": le fichier \".webhook\" est absent, les notifications sur Discord ne seront pas envoyées"' $mon_log_perso
    config_discord="non"
  fi
else
  eval 'echo -e "[\e[42m\u2713 \e[0m] Utilisation du script \"discord.sh\": le fichier \".webhook\" est présent, les notifications sur Discord seront envoyées"' $mon_log_perso
fi

### Déclaration des variables pour les couleurs des textes
GREEN="\\033[1;32m"
RED="\\033[1;31m"
YELLOW="\\e[0;33m"
NORMAL="\\033[0;39m"

restart_necessaire="" # Variable permettant le restart du serveur
script_discord="/opt/scripts/discord.sh --text"
annonce_discord="non"

eval 'printf  "\e[44m\u2263\u2263  \e[0m \e[44m \e[1m %-62s  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m\n" "$mui_section_server_infos"' $mon_log_perso
sh_serveurs=()
map_serveurs=()
sessionname_serveurs=()
port_serveurs=()
rconport_serveurs=()
players_serveurs=()
ip_locale=`hostname -I | cut -d' ' -f1`

if [[ "$chemin_serveur" == "" ]]; then
  updatedb &
  pid=$!
  spin='-\|/'
  i=0
  while kill -0 $pid 2>/dev/null
  do
    i=$(( (i+1) %4 ))
    printf "\r[  ] Détection du nombre de joueurs connectés au serveur ... ${spin:$i:1}"
    sleep .1
  done
  printf "$mon_printf" && printf "\r"

#### recherche du chemin et de la liste des serveurs
  printf "\r[  ] Détection du nombre de joueurs connectés au serveur ..."
  chemin_serveur=`locate \/arkserver | sed '/\/usb_save\//d' |  sed '/\/SAUVEGARDE\//d' | sed '/\/lgsm\//d' | sed '/\/log\//d' | sed '/\/.config\/argos\//d' | grep "\/arkserver$" | xargs dirname`
  chemin_serveur_line=$(sed -n '/^chemin_serveur=/=' $mon_script_config)
  if [[ "$chemin_serveur_line" != "" ]]; then
    sed -i 's|chemin_serveur=.*|chemin_serveur="'$chemin_serveur'"|' $mon_script_config
  else
    echo -e "\nchemin_serveur=$chemin_serveur" >> $mon_script_config
  fi
fi
updatedb -U $chemin_serveur --output $dossier_config/mlocate.db &
pid=$!
spin='-\|/'
i=0
while kill -0 $pid 2>/dev/null
do
  i=$(( (i+1) %4 ))
  printf "\r[  ] Détection du nombre de joueurs connectés au serveur ... ${spin:$i:1}"
  sleep .1
done
printf "$mon_printf" && printf "\r"

liste_serveurs=`locate -d $dossier_config/mlocate.db \/arkserver | grep "$chemin_serveur" | sed '/\/usb_save\//d' |  sed '/\/SAUVEGARDE\//d' | sed '/\/lgsm\//d' | sed '/\/log\//d' | sed "s|$chemin_serveur\/||g"`
arkserver_GameUserSettings=`echo $chemin_serveur"/serverfiles/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini"`
server_admin_password=`cat "$arkserver_GameUserSettings" | grep '^ServerAdminPassword=' | sed 's/ServerAdminPassword=//g'`

numero_serveur=0
players_total_serveur=0
for sh_actuel in $liste_serveurs ; do
  sh_serveurs+=("$sh_actuel")
  if [[ -f "$chemin_serveur/lgsm/config-lgsm/arkserver/$sh_actuel.cfg" ]]; then
    map_serveurs+=(`cat "$chemin_serveur/lgsm/config-lgsm/arkserver/$sh_actuel.cfg" | grep '^defaultmap=' | sed 's/defaultmap=\"//g' | sed 's/\"//g'`)
    serveur_name=`cat "$chemin_serveur/lgsm/config-lgsm/arkserver/$sh_actuel.cfg" | grep 'SessionName=' | sed 's/.*SessionName=//g' | sed 's/?.*//g' | sed 's/\\\"//g'`
    sessionname_serveurs+=("$serveur_name")
    port_serveurs+=(`cat "$chemin_serveur/lgsm/config-lgsm/arkserver/$sh_actuel.cfg" | grep '^port=' | sed 's/port=\"//g' | sed 's/\"//g'`)
    queryport_serveurs+=(`cat "$chemin_serveur/lgsm/config-lgsm/arkserver/$sh_actuel.cfg" | grep '^queryport=' | sed -e 's/queryport=\"//g' | sed 's/\"//g'`)
    rconport_serveurs+=(`cat "$chemin_serveur/lgsm/config-lgsm/arkserver/$sh_actuel.cfg" | grep '^rconport=' | sed 's/rconport=\"//g' | sed 's/\"//g'`)
    process_arkserver=`ps aux | sed '/tmux/d' | grep -i "./ShooterGameServer \(/Game/Mods/.*/${map_serveurs[$numero_serveur]}\|${map_serveurs[$numero_serveur]}\)" | grep "?Port=${port_serveurs[$numero_serveur]}?" | sed '/grep/d' | awk '{print $2}'`
    if [[ "$process_arkserver" != "" ]]; then
      $dossier_config/rcon -P$server_admin_password -a$ip_locale -p${rconport_serveurs[$numero_serveur]} listplayers > $dossier_config/rcon_$numero_serveur.txt
      players_connected=`cat $dossier_config/rcon_$numero_serveur.txt | grep 'No Players Connected'`
      if [[ "$players_connected" == "" ]]; then
        cat $dossier_config/rcon_$numero_serveur.txt | sed '/^$/d' | cut -c 4- | cut -d , -f 1 | sed '$d' > $dossier_config/list_players.txt
        players=`wc -l < $dossier_config/list_players.txt`
        players_serveurs+=("$players")
      else
        players_serveurs+=("0")
      fi
    else
      players_serveurs+=("0")
    fi
  else
    map_serveurs+=("0")
    serveur_name="Serveur non configuré"
    sessionname_serveurs+=("")
    port_serveurs+=("0")
    rconport_serveurs+=("0")
    players_serveurs+=("0")
  fi
  players_total_serveur=$(expr $players_total_serveur + ${players_serveurs[$numero_serveur]})
  numero_serveur=$(expr $numero_serveur + 1)
done
printf "$mon_printf" && printf "\r"
if [[ "$players_total_serveur" != "0" ]]; then
  if [[ "$force_update" == "oui" ]]; then
    eval 'echo -e "[\e[41m\u2713 \e[0m] Nombre de joueurs connecté: $players_total_serveur (paramètre --force-update)"' $mon_log_perso
  else
    eval 'echo -e "[\e[41m\u2717 \e[0m] Nombre de joueurs connecté: $players_total_serveur"' $mon_log_perso
  fi
else
  eval 'echo -e "[\e[42m\u2713 \e[0m] Aucun joueur connecté"' $mon_log_perso
fi
rm -f rcon_* 2>/dev/null
nombre_serveur=`echo ${#map_serveurs[@]}`

#url_steamdb="https://steamdb.info/app/376030/depots"
#wget -q --timeout=2 --waitretry=0 --tries=2  "$url_steamdb" -O "$dossier_config/steamdb.log" &
#pid=$!
#spin='-\|/'
#i=0
#while kill -0 $pid 2>/dev/null
#do
#  i=$(( (i+1) %4 ))
#  printf "\r[  ] Vérification de la version du serveur sur SteamDB.info... ${spin:$i:1}"
#  sleep .1
#done
#printf "$mon_printf" && printf "\r"
#availablebuild=`cat "$dossier_config/steamdb.log" | grep "href=\"/patchnotes/" | grep "rel=\"nofollow\">" | sed -n 1p | sed 's|.*/patchnotes/||' | sed -e 's|/".*||'`
#rm $dossier_config/steamdb.log

rm -rf ~/.steam/appcache
availablebuild=""
while [[ "$availablebuild" == "" ]]; do
  steamcmd +login anonymous +app_info_update 1 +app_info_print 376030 +quit 2>/dev/null > $dossier_config/availablebuild.log &
  pid=$!
  spin='-\|/'
  i=0
  while kill -0 $pid 2>/dev/null
  do
    i=$(( (i+1) %4 ))
    printf "\r[  ] Vérification de la version du serveur disponible ... ${spin:$i:1}"
    sleep .1
  done
  availablebuild=`cat $dossier_config/availablebuild.log | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d' ' -f3`
done
printf "$mon_printf" && printf "\r"
rm $dossier_config/availablebuild.log

maj_serveur="non"
if [ -n "$nom_serveur" ] && [ -n "$chemin_serveur" ]; then
  currentbuild=`grep buildid "$chemin_serveur/serverfiles/steamapps/appmanifest_376030.acf" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d\  -f3`
#  compare=`testvercomp $currentbuild $availablebuild '<' | grep Pass`
#  if [[ "$compare" != "" ]] ; then
  if [[ "$currentbuild" -lt "$availablebuild" ]]; then
    eval 'echo -e "[\e[42m\u2713 \e[0m] Une mise à jour du serveur $nom_serveur est disponible:"' $mon_log_perso
    eval 'echo -e " ... Build actuelle: $RED$currentbuild$NORMAL"' $mon_log_perso
    eval 'echo -e " ... Build disponible: $GREEN$availablebuild$NORMAL"' $mon_log_perso
    if [[ "$players_total_serveur" != "0" && "$force_update" == "oui" ]] || [[ "$players_total_serveur" == "0" ]]; then
      restart_necessaire="oui"
      maj_serveur="oui"
      if [[ "$config_discord" == "oui" ]]; then
        bash $script_discord ":construction: Une mise à jour du server $nom_serveur est disponible, un reboot sera effectué sous peu :construction:"
        annonce_discord="oui"
      fi
      if [[ "$push_maj_serveur" == "oui" ]]; then
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
              --form-string "priority=1" \
              https://api.pushover.net/1/messages.json > /dev/null
          fi
        done
      fi
    else
      eval 'echo -e " ... La mise à jour ne sera pas installée: paramètre \"--force-update\" manquant"' $mon_log_perso
      if [[ "$push_maj_serveur" == "oui" ]]; then
        message_maj=`echo -e "Une mise à jour du serveur $nom_serveur est disponible.\n<b>Version actuelle:</b> "$currentbuild"\n<b>Version disponible:</b> "$availablebuild"\n<b>MAIS NE SERA PAS INSTALLÉE...</b>\n<b>Nombre de joueurs connectés:</b> "$players_total_serveur`
        for user in {1..10}; do
        destinataire=`eval echo "\\$destinataire_"$user`
          if [ -n "$destinataire" ]; then
            curl -s \
              --form-string "token=$token_app" \
              --form-string "user=$destinataire" \
              --form-string "title=Mise à jour disponible" \
              --form-string "message=$message_maj" \
              --form-string "html=1" \
              --form-string "priority=1" \
              https://api.pushover.net/1/messages.json > /dev/null
          fi
        done
      fi
    fi
  else
    eval 'echo -e "[\e[42m\u2713 \e[0m] Serveur $nom_serveur à jour:"' $mon_log_perso
    eval 'echo -e " ... Build actuelle: $GREEN$currentbuild$NORMAL"' $mon_log_perso
  fi
fi

eval 'printf  "\e[44m\u2263\u2263  \e[0m \e[44m \e[1m %-62s  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m\n" "$mui_section_mods_download"' $mon_log_perso

if [[ "$mod_branch" == "Linux" ]]; then
  eval 'echo -e "[\e[43m\u2713 \e[0m] Les mods seront téléchargés en version Linux. Il est conseillé de les prendre en version Windows, la version Linux peut causer des plantages du server"' $mon_log_perso
else
  if [[ "$mod_branch" == "Windows" ]]; then
    eval 'echo -e "[\e[42m\u2713 \e[0m] Les mods seront téléchargés en version Windows"' $mon_log_perso
  else
    eval 'echo -e "[\e[41m\u2717 \e[0m] Le paramètre mod_branch est à configurer. Il est conseillé de les prendre en version Windows, la version Linux peut causer des plantages du server"' $mon_log_perso
    eval 'echo -e "[\e[42m\u2713 \e[0m] Les mods seront téléchargés en version Windows"' $mon_log_perso
    mod_branch="Windows"
  fi
fi

chemin_GameUserSettings=`echo $chemin_serveur"/serverfiles/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini"`
if [[ -f "$chemin_GameUserSettings" ]]; then
  activemods=`cat "$chemin_GameUserSettings" | grep "ActiveMods=" | sed "s/ActiveMods=//g"`
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

  info_version_mod_disponible=""
  while [[ "$info_version_mod_disponible" == "" ]]; do
    info_version_mod_disponible=`curl -s "https://steamcommunity.com/sharedfiles/filedetails/?id=$modId" | sed -n 's|^.*<div class="detailsStatRight">\([^<]*\)</div>.*|\1|p' | sed -n 3p`
  done
  info_version_mod_local=""
  if [[ -f "$modExtractDir/.updatemods.info" ]] && [[ "$force_dl" == "non" ]] ;then
    info_version_mod_local=`cat "$modExtractDir/.updatemods.info"`
  fi
  if [ "$info_version_mod_disponible" != "$info_version_mod_local" ]; then
    if [[ "$players_total_serveur" != "0" && "$force_update" == "oui" ]] || [[ "$players_total_serveur" == "0" ]]; then
      if [[ "$force_dl" == "non" ]]; then
        eval 'echo -e "[\e[41m\u2717 \e[0m] Mise à jour du mod $modName ($modId) nécessaire"' $mon_log_perso
      else
        eval 'echo -e "[\e[41m\u2717 \e[0m] Mise à jour du mod $modName ($modId) demandé"' $mon_log_perso
      fi
      modSrcDir=""
      let num=0
      while [[ "$modSrcDir" == "" ]]; do
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
#        while IFS= read -r -d $'\n'; do
#          modDir=`echo "$REPLY" | sed -n 's@^Success. Downloaded item '$modId' to "\([^"]*\)" .*@\1@p'`
          modDir=`cat steamdl.log | grep "Success. Downloaded item $modId to" | awk '{print $6}' | sed 's/"//g'`
          if [[ "$modDir" != "" ]]; then
            modSrcDir=$modDir
          else
            eval 'echo -e "[\e[41m\u2717 \e[0m] Erreur lors du téléchargement du mod $modName ($modId)."' $mon_log_perso
            let num=$num+1
            if [[ "$num" == "10" ]]; then
              if [[ "$push_maj_mod" == "oui" ]]; then
                message_maj=`echo -e "Erreur lors du téléchargement du mod "$modName" ("$modId")."`
                for user in {1..10}; do
                  destinataire=`eval echo "\\$destinataire_"$user`
                  if [ -n "$destinataire" ]; then
                    curl -s \
                      --form-string "token=$token_app" \
                      --form-string "user=$destinataire" \
                      --form-string "title=Mise à jour mod" \
                      --form-string "message=$message_maj" \
                      --form-string "html=1" \
                      --form-string "priority=1" \
                      https://api.pushover.net/1/messages.json > /dev/null
                  fi
                done
              fi
              break
            fi
          fi
#        done <steamdl.log
        if [ ! -d "/opt/scripts/SteamDL/log" ]; then mkdir -p "/opt/scripts/SteamDL/log"; fi
        cp steamdl.log /opt/scripts/SteamDL/log/$modId.log
        rm steamdl.log
      done
 
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
     
          echo $info_version_mod_disponible > "$modExtractDir/.updatemods.info"
     
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
          if [[ "$config_discord" == "oui" ]]; then
            if [[ "$annonce_discord" != "oui" ]]; then
              bash $script_discord ":construction: Une mise à jour d'un mod est disponible, un reboot sera effectué sous peu :construction:"
              annonce_discord="oui"
            fi
          fi
          if [[ "$push_maj_mod" == "oui" ]]; then
            message_maj=`echo -e "Une mise à jour du mod "$modName" ("$modId") est installée.\nLe redémarrage du serveur s'effectuera après la procédure de mise à jour."`
            for user in {1..10}; do
              destinataire=`eval echo "\\$destinataire_"$user`
              if [ -n "$destinataire" ]; then
                curl -s \
                  --form-string "token=$token_app" \
                  --form-string "user=$destinataire" \
                  --form-string "title=Mise à jour mod" \
                  --form-string "message=$message_maj" \
                  --form-string "html=1" \
                  --form-string "priority=-1" \
                  https://api.pushover.net/1/messages.json > /dev/null
              fi
            done
          fi
        fi
        eval 'echo " ---"' $mon_log_perso
      else
        eval 'echo -e "[\e[41m\u2717 \e[0m] Erreur lors du téléchargement du mod $modName ($modId)."' $mon_log_perso
        if [[ "$push_maj_mod" == "oui" ]]; then
          message_maj=`echo -e "Erreur lors du téléchargement du mod "$modName" ("$modId")."`
          for user in {1..10}; do
            destinataire=`eval echo "\\$destinataire_"$user`
            if [ -n "$destinataire" ]; then
              curl -s \
                --form-string "token=$token_app" \
                --form-string "user=$destinataire" \
                --form-string "title=Mise à jour mod" \
                --form-string "message=$message_maj" \
                --form-string "html=1" \
                --form-string "priority=1" \
                https://api.pushover.net/1/messages.json > /dev/null
            fi
          done
        fi
        eval 'echo " ---"' $mon_log_perso
      fi
    else
      eval 'echo -e "[\e[41m\u2717 \e[0m] La mise à jour du mod $modName ($modId) ne sera pas installée."' $mon_log_perso
    fi
  else
    eval 'echo -e "[\e[42m\u2713 \e[0m] Mod $modName ($modId) à jour"' $mon_log_perso
  fi
done

eval 'printf  "\e[44m\u2263\u2263  \e[0m \e[44m \e[1m %-62s  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m\n" "$mui_section_server_reboot"' $mon_log_perso
if [[ "$restart_necessaire" == "oui" ]]; then
  restart="non"
  ### Création du script de reboot du serveur
  chmod 777 -R "$chemin_serveur"
  user_arkserver=`stat -c "%U" "$chemin_serveur"`
  group_arkserver=`stat -c "%G" "$chemin_serveur"`
  chown $user_arkserver:$group_arkserver -R "$chemin_serveur"
  numero_serveur=0
  while [[ $numero_serveur != $nombre_serveur ]]; do
    process_arkserver=`ps aux | sed '/tmux/d' | grep -i "./ShooterGameServer \(/Game/Mods/.*/${map_serveurs[$numero_serveur]}\|${map_serveurs[$numero_serveur]}\)" | grep "?Port=${port_serveurs[$numero_serveur]}?" | sed '/grep/d' | awk '{print $2}'`
    if [[ "$process_arkserver" != "" ]]; then
      echo "#!/bin/bash" > /opt/scripts/ark-restart.sh
      echo "mon_printf=\"\\r                                                                                                                \"" >> /opt/scripts/ark-restart.sh
      echo "bash $script_discord \":construction: Redémarrage du serveur ${sessionname_serveurs[$numero_serveur]} (${map_serveurs[$numero_serveur]}) :construction:\"" >> /opt/scripts/ark-restart.sh
      echo "bash \"$chemin_serveur/${sh_serveurs[$numero_serveur]}\" restart > /opt/scripts/ark-restart.log &" >> /opt/scripts/ark-restart.sh
      echo "pid=\$!" >> /opt/scripts/ark-restart.sh
      echo "spin='-\|/'" >> /opt/scripts/ark-restart.sh
      echo "i=0" >> /opt/scripts/ark-restart.sh
      echo "while kill -0 \$pid 2>/dev/null" >> /opt/scripts/ark-restart.sh
      echo "do" >> /opt/scripts/ark-restart.sh
      echo "  i=\$(( (i+1) %4 ))" >> /opt/scripts/ark-restart.sh
      echo "  printf \"\\r[  ] Redémarrage du serveur ${sessionname_serveurs[$numero_serveur]} (${map_serveurs[$numero_serveur]}) ... \${spin:\$i:1}\"" >> /opt/scripts/ark-restart.sh
      echo "  sleep .1" >> /opt/scripts/ark-restart.sh
      echo "done" >> /opt/scripts/ark-restart.sh
      echo "printf \"\$mon_printf\" && printf \"\\r\"" >> /opt/scripts/ark-restart.sh
      echo "echo -e \"\\r[\\e[42m\\u2713 \e[0m] Redémarrage du serveur ${sessionname_serveurs[$numero_serveur]} (${map_serveurs[$numero_serveur]}) \"" >> /opt/scripts/ark-restart.sh
      echo "bash $script_discord \":construction: Le serveur ${sessionname_serveurs[$numero_serveur]} (${map_serveurs[$numero_serveur]}) est redémarré, veuillez patienter quelques instants :construction:\"" >> /opt/scripts/ark-restart.sh
      chmod +x /opt/scripts/ark-restart.sh
su $user_arkserver <<'EOF'
bash /opt/scripts/ark-restart.sh
EOF
      restart="oui"
      if [[ "$push_maj_serveur" == "oui" ]]; then
        message_reboot=`echo -e "Le redémarrage du serveur "${sessionname_serveurs[$numero_serveur]}" a été effectué."`
        for user in {1..10}; do
          destinataire=`eval echo "\\$destinataire_"$user`
          if [ -n "$destinataire" ]; then
            curl -s \
              --form-string "token=$token_app" \
              --form-string "user=$destinataire" \
              --form-string "title=Redémarrage du serveur" \
              --form-string "message=$message_reboot" \
              --form-string "html=1" \
              --form-string "priority=1" \
              https://api.pushover.net/1/messages.json > /dev/null
          fi
        done
      fi
    fi
    numero_serveur=$(expr $numero_serveur + 1)
  done
  if [[ "$restart" != "oui" ]]; then
    if [[ "$maj_serveur" == "oui" ]]; then
      numero_serveur=0
      echo "#!/bin/bash" > /opt/scripts/ark-restart.sh
      echo "mon_printf=\"\\r                                                                                           \"" >> /opt/scripts/ark-restart.sh
      echo "bash $script_discord \":construction: Mise à jour du serveur :construction:\"" >> /opt/scripts/ark-restart.sh
      echo "bash \"$chemin_serveur/${sh_serveurs[$numero_serveur]}\" force-update > /opt/scripts/ark-restart.log &" >> /opt/scripts/ark-restart.sh
      echo "pid=\$!" >> /opt/scripts/ark-restart.sh
      echo "spin='-\|/'" >> /opt/scripts/ark-restart.sh
      echo "i=0" >> /opt/scripts/ark-restart.sh
      echo "while kill -0 \$pid 2>/dev/null" >> /opt/scripts/ark-restart.sh
      echo "do" >> /opt/scripts/ark-restart.sh
      echo "  i=\$(( (i+1) %4 ))" >> /opt/scripts/ark-restart.sh
      echo "  printf \"\\r[  ] Mise à jour du serveur ... \${spin:\$i:1}\"" >> /opt/scripts/ark-restart.sh
      echo "  sleep .1" >> /opt/scripts/ark-restart.sh
      echo "done" >> /opt/scripts/ark-restart.sh
      echo "printf \"\$mon_printf\" && printf \"\\r\"" >> /opt/scripts/ark-restart.sh
      echo "echo -e \"\\r[\\e[42m\\u2713 \e[0m] Le serveur a été mis à jour\"" >> /opt/scripts/ark-restart.sh
      echo "bash $script_discord \":construction: Le serveur a été mis à jour :construction:\"" >> /opt/scripts/ark-restart.sh
      chmod +x /opt/scripts/ark-restart.sh
su $user_arkserver <<'EOF'
bash /opt/scripts/ark-restart.sh
EOF
    fi
    eval 'echo -e "\r[\e[42m\u2713 \e[0m] Pas de nécessité de redémarrer le serveur"' $mon_log_perso
    if [[ "$push_maj_serveur" == "oui" ]]; then
      message_reboot=`echo -e "Pas de nécessité de redémarrer le serveur: aucun serveur démarré."`
      for user in {1..10}; do
        destinataire=`eval echo "\\$destinataire_"$user`
        if [ -n "$destinataire" ]; then
          curl -s \
            --form-string "token=$token_app" \
            --form-string "user=$destinataire" \
            --form-string "title=Redémarrage du serveur" \
            --form-string "message=$message_reboot" \
            --form-string "html=1" \
            --form-string "priority=-1" \
            https://api.pushover.net/1/messages.json > /dev/null
        fi
      done
    fi
  fi
  rm -f /opt/scripts/ark-restart.*
else
  eval 'echo -e "\r[\e[42m\u2713 \e[0m] Pas de nécessité de redémarrer le serveur"' $mon_log_perso
fi

end_of_script=`date`
source $mon_script_langue
my_title_count=`echo -n "$mui_end_of_script" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | sed 's/é/e/g' | wc -c`
line_lengh="78"
before_count=$((($line_lengh-$my_title_count)/2))
after_count=$(((($line_lengh-$my_title_count)%2)+$before_count))
before=`eval printf "%0.s-" {1..$before_count}`
after=`eval printf "%0.s-" {1..$after_count}`
eval 'printf "\e[43m%s%s%s\e[0m\n" "$before" "$mui_end_of_script" "$after"' $mon_log_perso
if [[ "$maj_necessaire" == "1" ]] && [[ -f "$fichier_log_perso" ]]; then
  cp $fichier_log_perso /var/log/$mon_script_base-last.log
fi
rm "$mon_script_pid"

if [[ "$1" == "--menu" ]]; then
  read -rsp $'Press a key to close the window...\n' -n1 key
fi