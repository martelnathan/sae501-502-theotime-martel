#!/bin/bash

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
if podman images | grep 'docker.io/library/nginx.*alpine' && podman images | grep 'docker.io/library/php.*8.2-fpm' && podman images | grep 'docker.io/library/mysql.*latest' && podman images | grep 'docker.io/library/haproxy.*alpine'; then
    echo "Les images sont déjà installées"
else
    echo "Pulling des images pour le lancement des conteneurs.."
    podman pull docker.io/library/mysql:latest
    podman pull docker.io/library/php:8.2-fpm
    podman pull docker.io/library/nginx:alpine
    podman pull docker.io/library/haproxy:alpine
    #podman pull grafana/grafana
    #podman pull grafana/loki
    #podman pull grafana/promtail    
    #podman pull docker.io/balabit/syslog-ng:latest
fi

#Partie syslog-ng et grafana : 

echo "L'application peut être implémentée avec un syslog-ng. Cette partie est automatique : elle installe et configure rsyslog sur votre PC hôte pour l'envoi des logs et ajoute un conteneur syslog-ng."
echo "Voulez-vous ajouter syslog-ng lors du déploiement de l'application (taille de l'image : 538 Mo) ? (O/N)"
read response_syslogng

if [ "$response_syslogng" == "O" ] || [ "$response_syslogng" == "o" ]; then
	bash ./scripts/rsyslog.sh
	echo "Syslog-ng ajouté avec succès."
    
	echo "Voulez-vous également implémenter une interface graphique avec Grafana, Promtail et Loki (taille des images : 683 Mo) ? (O/N)"
	read response_ihm

	if [ "$response_ihm" == "O" ] || [ "$response_ihm" == "o" ]; then
		bash ./scripts/grafana.sh
		echo "Interface graphique pour syslog-ng (Grafana, Promtail, Loki) ajoutée avec succès."
		echo "Lancement des conteneurs..."
		podman-compose -f docker-compose-grafana.yaml up -d
	else
		echo "Interface graphique pour syslog-ng (Grafana, Promtail, Loki) non implémentée."
	fi

else
	echo "Syslog-ng non implémenté."
	echo "Lancement des conteneurs"
	podman-compose -f docker-compose.yaml up -d
fi

#Et l'adresse IP du conteneur Haproxy pour accéder à l'application
AdresseIP=$(podman inspect haproxy | grep -oP '"IPAddress": "\K[^"]+') 
echo "--> L'adresse IP de l'application sur laquelle se rendre est https://$AdresseIP:8443"
echo "--> Vous pouvez faire un CTRL + [clique gauche] sur l'URL ci-dessus."
if podman ps | grep -q "grafana"; then
	AddresseIpGraph=$(podman inspect grafana | grep -oP '"IPAddress": "\K[^"]+')
	echo "Si vous avez choisi d'implémenter une IHM avec votre syslog-ng, vous pouvez vous rendre sur https://$AddresseIpGraph:3000"
fi
