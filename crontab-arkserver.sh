#!/bin/bash
 
 
#### Déduction des noms des fichiers (pour un portage facile)
mon_script_fichier=`basename "$0"`
mon_script_base=`echo ''$mon_script_fichier | cut -f1 -d'.'''`
mon_cron=`echo $HOME"/.config/"$mon_script_base"/mon_cron.txt"`
 
#### Création du dossier config
dossier_config=`echo $HOME"/.config/"$mon_script_base`
if [[ ! -d "$dossier_config" ]]; then
  mkdir -p $dossier_config
fi
 
#### Initialisation des variables
etat=$1					## Etat dans lequel le script sera
chemin_serveur=$2			## Chemin du serveur
nom_serveur=$3				## Nom du script du serveur ARK à lancer
 
 
####################
## On commence enfin
####################
 
if [[ "$etat" == "Off" ]];then
  crontab -l > $mon_cron
  sed -i 's|@reboot\t\t\t'$chemin_serveur'/'$nom_serveur' start|#@reboot\t\t\t'$chemin_serveur'/'$nom_serveur' start|g' $mon_cron
  echo "Désactivation du redémarrage automatique du serveur "$nom_serveur
else
  test_crontab=`crontab -l | grep "$nom_serveur start" | grep "#"`
  if [[ "$test_crontab" == "" ]]; then
    ajout_cron=`echo -e "@reboot\t\t\t$chemin_serveur/$nom_serveur start"`
    crontab -l > $mon_cron
    echo -e "$ajout_cron" >> $mon_cron
  else
    crontab -l > $mon_cron
    sed -i 's|#@reboot\t\t\t'$chemin_serveur'/'$nom_serveur' start|@reboot\t\t\t'$chemin_serveur'/'$nom_serveur' start|g' $mon_cron
  fi
  echo "Activation du redémarrage automatique du serveur "$nom_serveur
fi
crontab $mon_cron
echo -e "-- Cron mis à jour \n"
cat $mon_cron
rm -f $mon_cron
