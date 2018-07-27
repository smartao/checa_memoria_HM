#!/bin/bash
# Script para coleta o SNMP de Memoria para HM

function MAIN()
{
	CORES
	OIDS
	
	clear
	echo -e $CBR
	read -p " Entre com o IP do servidor: " IP
	echo -e $CFM

	T=0
	TENTATIVAS=1
	while [ $T -lt $TENTATIVAS ];
	do
		let T=$T+1
		SERVER_NAME=`snmpwalk -v 1 -c public $IP $OHOSTNAME | cut -c31-56` > /dev/null 2>&1 #$CAMINHO_LOG/$ARQ_DEBUG
		if [ -z $SERVER_NAME ];then
			EXIT=1
			echo -e "\n$CVE Nao foi possivel coletar o SNMP do servidor, tentando novamente $CFM\n" 
		else
			EXIT=0
			break; # Sair quando houver sucesso na coleta do hostname
                fi
        done
	if [ $EXIT -eq 0 ];then
		SO=`snmpwalk -v 1 -c public $IP $OSO | grep -iEo "ESX|Linux|Windows"` >/dev/null 2>&1 
		ID_MFISICA=`snmpwalk -v 1 -c public $IP $OMEMORIA_FULL | grep -i "physica" | cut -c26-27` >/dev/null 2>&1
		
		OMEMORIA_TOTAL="$OMEMORIA.$ID_RAM_TOTAL.$ID_MFISICA"
		OMEMORIA_UTILIZADA="$OMEMORIA.$ID_RAM_UTILIZADA.$ID_MFISICA"
	
		#echo "OID Memoria Total $OMEMORIA_TOTAL" # Teste	
		#echo "OID Memoria Utilizada $OMEMORIA_UTILIZADA" # Teste
 			
	    #echo "M_TOTAL=snmpget -v 1 -c public $IP $OMEMORIA_TOTAL | cut -c39-53" #Teste
		#echo "M_UTILIZADA=snmpget -v 1 -c public $IP $OMEMORIA_UTILIZADA | cut -c39-53" #Teste	

		#echo "OK" # Teste
		
		M_TOTAL=`snmpget -v 1 -c public $IP $OMEMORIA_TOTAL | cut -c39-53` > /dev/null 2>&1
		M_UTILIZADA=`snmpget -v 1 -c public $IP $OMEMORIA_UTILIZADA | cut -c39-53` > /dev/null 2>&1	
		
		#M_TOTAL=`snmpwalk -v 1 -c public $IP $OMEMORIA_TOTAL | cut -c39-53` > /dev/null 2>&1
		#M_UTILIZADA=`snmpwalk -v 1 -c public $IP $OMEMORIA_UTILIZADA | cut -c39-53` > /dev/null 2>&1	
		
		#echo "Memoria TOTAL=$M_TOTAL" # Teste
		#echo "Memoria Utilizada=$M_UTILIZADA" # Teste

		MULTI=1048576 # 1024*1024 Retorno em MB
	
		case $SO in
			"Windows")	
				BLOCO=65536
				TESTE
				CALCULA
				IMPRIMIR
				;;		
			"Linux")
				BLOCO=1024
				TESTE
				CALCULA
				IMPRIMIR
				;;
			"ESX")
				BLOCO=1024
				TESTE
				CALCULA
				IMPRIMIR
				;;
			*)
				echo -e "\n\n$CVE Sistema operacional nao reconhecido! $SO"
				echo -e " Hostname: $SERVER_NAME $CFM\n\n"
				exit;
				;;	
		esac	

	fi	
}	

function CORES()
{
	CCA='\e[1;36m' # Cyan Bold
	CAM='\e[1;33m' # Yellow Bold
	CBR='\e[1;37m' # White Bold
	CVE='\e[1;31m' # Red Bold
	CFM='\e[0m'    # Tag end
}

function OIDS()
{
	OHOSTNAME="1.3.6.1.2.1.1.5"
	OSO="1.3.6.1.2.1.1.1.0" 
	OMEMORIA_FULL="1.3.6.1.2.1.25.2.3.1"
	OMEMORIA="1.3.6.1.2.1.25.2.3.1"
	ID_RAM_TOTAL="5"
	ID_RAM_UTILIZADA="6"
}

function IMPRIMIR() 
{	
	echo ""
	echo -e "$CCA Hostname                       : $CAM $SERVER_NAME $CFM"
	echo -e "$CCA Sistema Operacional            : $CAM $SO $CFM"
	echo -e "$CCA Memoria RAM total (LEG)        : $CAM $M_TOTAL_CON Megabytes $CFM"
	echo -e "$CCA Memoria RAM utilizada (LEG)    : $CAM $M_UTILIZADA_CON Megabytes $CFM"
	echo -e "$CCA Memoria RAM total OID HM       : $CAM $OMEMORIA_TOTAL $CFM"
	echo -e "$CCA Memoria RAM utilizada OID HM   : $CAM $OMEMORIA_UTILIZADA $CFM"
	echo -e "$CCA Memoria RAM total (OID)        : $CAM $M_TOTAL $CFM"
	echo -e "$CCA Alarmar com > 90% (OID)        : $CAM $M_ALARME $CFM\n\n"
	exit;
}

function TESTE()
{
	if [ "$M_TOTAL" = "" ];then ## teste se for diferente de vazio
		echo -e "\n\n$CVE Servidor nao esta respondendo a coleta SNMP $CFM"
		echo -e "$CVE Necessario fazer a coleta manualmente $CFM" 
		echo -e "$CVE Utilize o seguinte comando, converter a memoria totol $CFM"
		echo -e "$CVE snmpwalk -v 1 -c public $IP $OMEMORIA_TOTAL $CFM"
		echo -e "$CVE OID de memoria utilizado para adicionar no HM $OMEMORIA_UTILIZADA $CFM"
		#echo -e "$CVE Utilize o seguinte OID no snmpwalk: $OMEMORIA_UTILIZADA OID de memoria total $CFM"
		echo -e "$CVE Hostname:$SERVER_NAME $CFM\n\n"
		exit;
	fi		
}

function CALCULA()
{
	M_ALARME=`echo "$M_TOTAL-$M_TOTAL*0.10" | bc | cut -d . -f 1` > /dev/null 2>&1
	M_TOTAL_CON=`echo "$M_TOTAL*$BLOCO/$MULTI" | bc` > /dev/null 2>&1
	M_UTILIZADA_CON=`echo "$M_UTILIZADA*$BLOCO/$MULTI" | bc` > /dev/null 2>&1
}

MAIN
exit;
