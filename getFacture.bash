#!/bin/bash

login="$1"
pass="$2"
workingDirectory="$3"
sourceDirectory=$(pwd)

cd "$workingDirectory"

#Récupération de la page d'index
wget -qO index.html "https://subscribe.free.fr/login/login.pl?login=$login&pass=$pass&ok=Connexion"

#récupération des factures
for facture in $(grep -Eo "facture.pl\?id=[0-9]+&idt=[a-z0-9]+&mois=[0-9]+&no_facture=[0-9]+" index.html | sort | uniq)
do
	mois=$(echo $facture | sed -e "s/.*mois=\([0-9]\+\)&no_facture=.*/\1/")
	
	#Récupération de la facture courante
	echo "Récupération de la facture du $mois"
	wget -qO "$mois.html" "https://adsl.free.fr/conso/$facture"
	
	#Récupération de la facture téléphonique
	factureTel=$(grep -Eo "facture_tel.pl\?id=[0-9]+&idt=[a-z0-9]+&mois=[0-9]+" "$mois.html")
	if [ -n "$factureTel" ]
	then
		echo "Récupération de la facture téléphonique du $mois" $mois"_tel.pdf"
		wget -qO $mois"_tel.pdf" "https://adsl.free.fr/conso/$factureTel"
	else
		echo "Pas de facture téléphonique pour le mois : $mois"
	fi
	
	#Récupération de la facture télé
	factureTv=$(grep -Eo "facture_tv.pl\?id=[0-9]+&idt=[a-z0-9]+&mois=[0-9]+" "$mois.html")
	if [ -n "$factureTv" ]
	then
		echo "Récupération de la facture télévisuelle du $mois" $mois"_tv.html"
		wget -qO $mois"_tv.html" "https://adsl.free.fr/conso/$factureTv"
	else
		echo "Pas de facture télévisuelle pour le mois : $mois"
	fi
	
done

#Rangement dans les répertoires
for key in $(ls -1 | grep -Eo "[0-9]+" | sort | uniq)
do
	#récupération des valeurs
	annee=$(echo $key | sed -e "s/^\([0-9]\{4\}\).*/\1/g")
	mois=$(echo $key | sed -e "s/^[0-9]\{4\}\([0-9]\{2\}\).*/\1/g")
	
	#Création des répertoires s'ils n'existent pas déjà
	if [ -d "$annee" ]
	then
		if ! [ -d "$annee/$mois" ]
		then
			mkdir "$annee/$mois"
		fi
	else
		mkdir -p "$annee/$mois"
	fi
	
	#déplacement du fichier
	mv "$key"* "$annee/$mois/"
done

cd "$sourceDirectory"

