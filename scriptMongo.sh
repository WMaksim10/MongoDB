#!/bin/bash
#Installatiyon de mongodb
apt update -y
apt install curl -y
curl -O http://downloads.mongodb.org/linux/mongodb-linux-x86_64-2.6.12.tgz


#Extraction des fichiers
tar -zxvf mongodb-linux-x86_64-2.6.12.tgz
cp mongodb-linux-x86_64-2.6.12/bin/* /usr/local/bin


#Ajout de l'utilisateur mongodb
groupadd mongodb
useradd --system --no-create-home -g mongodb mongodb


#Creation du dossier et fichier log
mkdir -p /var/log/mongodb
touch /var/log/mongodb/mongodb.log


#Creation du fichier de base de donnees pour mongodb
mkdir -p /var/lib/mongodb/


#Attribution des droits sur les dossiers et fichier creer
chown mongodb:mongodb -R /var/lib/mongodb
chown mongodb:mongodb -R /var/log/mongodb


#Creation du service mongodb
cat > /etc/systemd/system/mongodb.service	<<EOF
[Unit]
Description=High-performance, schema-free document-oriented database
After=network.target
[Service]
User=mongodb
ExecStart=/usr/local/bin/mongod --config /etc/mongod.conf
[Install]
WantedBy=multi-user.target
EOF


#Definition de l'adresse IP de la machine :
ip=$(hostname -I)
echo "L'adresse IP de cette machine est : $ip"


#Definition par l'utilisateur du nom du replication set et definition du role de la machine
read -p 'Nom du relpset: ' replName


#Creation du fichier de configuration
cat > /etc/mongod.conf	<<EOF
storage:
   dbPath: /var/lib/mongodb
   smallFiles: true
systemLog:
   destination: file
   path: /var/log/mongodb/mongodb.log
   logAppend: true
replication:
   replSetName: $replName
net:
   bindIp: 127.0.0.1,$ip
   port: 27017
EOF

echo 'Quelle role aura cette machine ?'
echo '1 :Primary'
echo '2 :Secondary'
echo '3 :Arbitre'
while true; do
read -p ">" role
case $role in
    1 ) echo "Vous avez choisie Primary"
            break;;
    2 ) echo "Vous avez choisie Secondary"
            break;;
    3 ) echo "Vous avez choisie Arbitre"
            break;;
    * )     echo "Veuillez ecrire 1, 2 ou 3."
esac
done

if [[ $role -eq 1 ]]
then
	read -p 'Adresse IP du secondary: ' IPsec
        read -p "Adresse IP de l'arbitre: " IParb

        #Enregistrement des modifications
        systemctl daemon-reload
        systemctl restart mongodb.service
	systemctl enable mongodb.service
	sleep 1
        systemctl status mongodb.service

	sleep 2

        #Commande mongodb pour activer la replication
	mongo -p 27017	<<-EOF
rs.initiate()
	EOF
	sleep 5
	mongo -p 27017	<<-EOF
rs.add('$IPsec:27017')
	EOF
	sleep 1
	mongo -p 27017	<<-EOF
rs.addArb('$IParb:27017')
	EOF
fi

if [[ $role -eq 2 ]]
then
        #Enregistrement des modifications
        systemctl daemon-reload
        systemctl restart mongodb.service
        systemctl enable mongodb.service
        sleep 1
        systemctl status mongodb.service
        sleep 1

	mongo -p 27017	<<-EOF
rs.slaveOk()
	EOF
fi

if [[ $role -eq 3 ]]
then
        #enrgistrement des modifications
	systemctl daemon-reload
        systemctl restart mongodb.service
	systemctl enable mongodb.service
	sleep 1
        systemctl status mongodb.service
fi

echo "***** Script Fini ******"

