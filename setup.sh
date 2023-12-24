#!/bin/bash

echo "__   ___     _   _   _        _   _   _ _   _  ____ _   _ _____ ____   ";  
echo "\ \ / / |   | \ | | | |      / \ | | | | \ | |/ ___| | | | ____|  _ \  ";
echo " \ V /| |   |  \| | | |     / _ \| | | |  \| | |   | |_| |  _| | |_) | ";
echo "  | | | |___| |\  | | |___ / ___ \ |_| | |\  | |___|  _  | |___|  _ <  ";
echo "  |_| |_____|_| \_| |_____/_/   \_\___/|_| \_|\____|_| |_|_____|_| \_\ ";

echo ""

if [ $# -ne 0 ]; then
	echo "Ce script ne prend pas de paramètre, il doit être exécuté sans paramètres"
	exit 1
fi

#Pour installer podman en fonction du SE de l'utilisateur
if [ -x "$(command -v apt-get)" ]; then
	sudo apt-get update 
	sudo apt-get install -y podman 
elif [ -x "$(command -v dnf)" ]; then
	sudo dnf install -y podman 
elif [ -x "$(command -v yum)" ]; then
	sudo yum install -y podman 
else
	echo "Système d'exploitation inconnu"
	exit 1
fi

#Pour installer podman-compose
if [ -x "$(command -v apt-get)" ]; then
	sudo apt-get install -y podman-compose 
elif [ -x "$(command -v dnf)" ]; then
	sudo dnf install -y podman-compose 
elif [ -x "$(command -v yum)" ]; then
	sudo yum install -y podman-compose  
else
	echo "Système d'exploitation non pris en charge."
	exit 1
fi

#Pour récupérer des images avec podman
if podman images | grep 'docker.io/library/nginx.*alpine' && podman images | grep 'docker.io/library/php.*8.2-fpm' && podman images | grep 'docker.io/library/mysql.*latest' && podman images | grep 'docker.io/library/haproxy.*alpine' && podman images | grep 'docker.io/portainer/portainer-ce.*latest'; then
	echo "Les images sont déjà installées"
else
	echo "Pulling des images pour le lancement des conteneurs.."
	podman pull docker.io/library/mysql:latest
	podman pull docker.io/library/php:8.2-fpm
	podman pull docker.io/library/nginx:alpine
	podman pull docker.io/library/haproxy:alpine
	podman pull docker.io/portainer/portainer-ce:latest
	#podman pull grafana/grafana
	#podman pull grafana/loki
	#podman pull grafana/promtail    
	#podman pull docker.io/balabit/syslog-ng:latest
fi

chmod 666 ./website/logs/logs.txt

#Partie syslog-ng et grafana : 

#echo ""
#echo "--> L'application peut être implémentée avec un syslog-ng. Cette partie est automatique : elle installe et configure rsyslog sur votre PC hôte pour l'envoi des logs et ajoute un conteneur syslog-ng."
#echo "--> Voulez-vous ajouter syslog-ng lors du déploiement de l'application (taille de l'image : 538 Mo) ? (O/N)"
#read rep_syslogng

#if [ "$rep_syslogng" == "O" ] || [ "$rep_syslogng" == "o" ]; then
	
	#bash ./scripts/rsyslog.sh
	#echo "Syslog-ng ajouté avec succès."
    
	#echo ""
	#echo "--> Voulez-vous également implémenter une interface graphique avec Grafana, Promtail et Loki (taille des images : 683 Mo) ? (O/N)"
	#read rep_ihm

	#if [ "$rep_ihm" == "O" ] || [ "$rep_ihm" == "o" ]; then
		#bash ./scripts/grafana.sh
		#echo "Interface graphique pour syslog-ng (Grafana, Promtail, Loki) ajoutée avec succès."
		#echo "Lancement des conteneurs..."
		#podman-compose -f docker-compose-grafana.yaml up -d
	#else
		#echo "Interface graphique pour syslog-ng (Grafana, Promtail, Loki) non implémentée."
		#echo "Lancement des conteneurs"
		#podman-compose -f docker-compose-syslog.yaml up -d
	#fi

#else
	#echo "Syslog-ng non implémenté."
	#echo "Lancement des conteneurs"
	#podman-compose -f docker-compose-sans.yaml up -d
#fi

echo ""
echo "--> Voulez-vous gérer les logs de l'application ? (O/N)"
read rep_logs

if [ "$rep_logs" == "O" ] || [ "$rep_logs" == "o" ]; then
	echo "Faites votre choix"
	echo "1- Syslog-ng"
	echo "2- Grafana (GUI)"
	read rep_log_choix

	case $rep_log_choix in
		1)
			echo "Syslog-ng sélectionné. Ajout en cours..."
			bash ./scripts/rsyslog.sh
			echo "Syslog-ng ajouté avec succès."
			echo "Lancement des conteneurs..."
			podman-compose -f docker-compose-syslog.yaml up -d
			;;
		2)
			echo "Grafana sélectionné. Ajout en cours..."
			bash ./scripts/grafana.sh
			echo "Interface graphique pour syslog-ng (Grafana, Promtail, Loki) ajoutée avec succès."
			echo "Lancement des conteneurs..."
			podman-compose -f docker-compose-grafana.yaml up -d
			;;
		*)
			echo "Choix invalide. Aucune gestion des logs implémentée."
			;;
	esac

else
	echo "Gestion des logs non implémentée."
	echo "Lancement des conteneurs sans gestion des logs..."
	podman-compose -f docker-compose-sans.yaml up -d
fi

#Et l'adresse IP du conteneur Haproxy pour accéder à l'application
AdresseIP=$(podman inspect haproxy | grep -oP '"IPAddress": "\K[^"]+') 
AdresseIP_Portainer=$(podman inspect portainer | grep -oP '"IPAddress": "\K[^"]+')

res_fqdn_site="172.18.0.253	yln.fr"
res_fqdn_portainer="172.18.0.254	portainer.yln.fr"

if grep -q "$res_fqdn_site" /etc/hosts; then
	echo "Résolution déjà présente du site"
else
    	echo "$res_fqdn_site" >> /etc/hosts
    	echo "Résolution ajoutée du site"
fi

if grep -q "$res_fqdn_portainer" /etc/hosts; then
        echo "Résolution déjà présente de portainer"
else
        echo "$res_fqdn_portainer" >> /etc/hosts
        echo "Résolution ajoutée de portainer"
fi

echo "--> Voulez-vous surveiller en temps réel les performances des conteneurs ? (O/N)"
read rep_netdata

if [ "$rep_netdata" == "O" ] || [ "$rep_netdata" == "o" ]; then
    podman pull docker.io/netdata/netdata
    #podman run -d --name=netdata -p 172.18.0.20:19999:19999 -v /proc:/host/proc:ro -v /sys:/host/sys:ro -v /run/podman/podman.sock:/var/run/docker.sock:z --cap-add SYS_PTRACE --security-opt apparmor=unconfined --network sae501-502-theotime-martel_sae netdata/netdata


    podman run -d --name=netdata -p 19999:19999 -v /proc:/host/proc:ro -v /sys:/host/sys:ro -v /run/podman/podman.sock:/var/run/docker.sock:z -v ./netdataconfig/netdata.conf:/etc/netdata/netdata.conf:z --cap-add SYS_PTRACE --security-opt apparmor=unconfined --network sae501-502-theotime-martel_sae netdata/netdata


    echo "Netdata ajouté avec succès pour surveiller les performances des conteneurs."
else
    echo "Surveillance des performances non implémentée"
fi

echo ""
echo "--> L'adresse IP de l'application sur laquelle se rendre est https://$AdresseIP:8443 ou https://yln.fr:8443"
#sudo firefox "https://yln.fr:8443"
echo "Vous pouvez faire un CTRL + [clique gauche] sur l'URL ci-dessus."
echo ""
echo "--> La gestion des conteneurs se fait sur https://$AdresseIP_Portainer:9443 ou sur https://portainer.yln.fr:9443"
echo "";
if podman ps | grep -q "grafana"; then
	AddresseIpGrafana=$(podman inspect grafana | grep -oP '"IPAddress": "\K[^"]+')
	res_fqdn_grafana="172.18.0.10	grafana.yln.fr"

	if grep -q "$res_fqdn_grafana" /etc/hosts; then
        	echo "Résolution déjà présente de grafana"
	else
        	echo "$res_fqdn_grafana" >> /etc/hosts
        	echo "Résolution ajoutée de grafana"
	fi

	echo "--> Pour votre syslog-ng, vous pouvez vous rendre sur https://$AddresseIpGrafana:3000 ou sur https://grafana.yln.fr:3000"
	
fi

if podman ps | grep -q "netdata"; then
	AddresseIpnetdata=$(podman inspect netdata | grep -oP '"IPAddress": "\K[^"]+')
	res_fqdn_netdata="$AddresseIpnetdata	netdata.yln.fr"
	if grep -q "$res_fqdn_netdata" /etc/hosts; then
                echo "Résolution déjà présente de netdata"
        else
                echo "$res_fqdn_netdata" >> /etc/hosts
                echo "Résolution ajoutée de netdata"
        fi

        echo "--> Pour la surveillance des conteneurs, vous pouvez vous rendre sur http://$AddresseIpnetdata:19999 ou sur http://netdata.yln.fr:19999"

fi
