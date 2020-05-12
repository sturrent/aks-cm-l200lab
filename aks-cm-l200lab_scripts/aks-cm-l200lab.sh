#!/bin/bash

# script name: aks-cm-l200lab.sh
# Version v0.1.1 20200512
# Set of tools to deploy L200 Azure containers labs

# "-g|--resource-group" resource group name
# "-n|--name" AKS cluster name
# "-l|--lab" Lab scenario to deploy
# "-v|--validate" Validate a particular scenario
# "-r|--region" region to deploy the resources
# "-h|--help" help info
# "--version" print version

# read the options
TEMP=`getopt -o g:n:l:r:hv --long resource-group:,name:,lab:,region:,help,validate,version -n 'aks-cm-l200lab.sh' -- "$@"`
eval set -- "$TEMP"

# set an initial value for the flags
RESOURCE_GROUP=""
CLUSTER_NAME=""
LAB_SCENARIO=""
LOCATION="eastus2"
VALIDATE=0
HELP=0
VERSION=0

while true ;
do
    case "$1" in
        -h|--help) HELP=1; shift;;
        -g|--resource-group) case "$2" in
            "") shift 2;;
            *) RESOURCE_GROUP="$2"; shift 2;;
            esac;;
        -n|--name) case "$2" in
            "") shift 2;;
            *) CLUSTER_NAME="$2"; shift 2;;
            esac;;
        -l|--lab) case "$2" in
            "") shift 2;;
            *) LAB_SCENARIO="$2"; shift 2;;
            esac;;
        -r|--region) case "$2" in
            "") shift 2;;
            *) LOCATION="$2"; shift 2;;
            esac;;    
        -v|--validate) VALIDATE=1; shift;;
        --version) VERSION=1; shift;;
        --) shift ; break ;;
        *) echo -e "Error: invalid argument\n" ; exit 3 ;;
    esac
done

# Variable definition
SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
SCRIPT_NAME="$(echo $0 | sed 's|\.\/||g')"
SCRIPT_VERSION="Version v0.1.1 20200512"

# Funtion definition

# az login check
function az_login_check () {
    if $(az account list 2>&1 | grep -q 'az login')
    then
        echo -e "\nError: You have to login first with the 'az login' command before you can run this lab tool\n"
        az login -o table
    fi
}

# check resource group and cluster
function check_resourcegroup_cluster () {
    RG_EXIST=$(az group show -g $RESOURCE_GROUP &>/dev/null; echo $?)
    if [ $RG_EXIST -ne 0 ]
    then
        echo -e "\nCreating resource group ${RESOURCE_GROUP}...\n"
        az group create --name $RESOURCE_GROUP --location $LOCATION &>/dev/null
    else
        echo -e "\nResource group $RESOURCE_GROUP already exists...\n"
    fi

    CLUSTER_EXIST=$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME &>/dev/null; echo $?)
    if [ $CLUSTER_EXIST -eq 0 ]
    then
        echo -e "\nCluster $CLUSTER_NAME already exists...\n"
        echo -e "Please remove that one before you can proceed with the lab.\n"
        exit 4
    fi
}

# validate cluster exists
function validate_cluster_exists () {
    CLUSTER_EXIST=$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME &>/dev/null; echo $?)
    if [ $CLUSTER_EXIST -ne 0 ]
    then
        echo -e "\nERROR: Cluster $CLUSTER_NAME in resource group $RESOURCE_GROUP does not exists...\n"
        exit 5
    fi
}

# Lab scenario 1
function lab_scenario_1 () { 
    echo -e "\n\n********************************************************"
    echo "You have to deploy an AKS cluster with the following setup:"
    echo "1. Cluster name = ${CLUSTER_NAME}"
    echo "2. Resource group name = ${RESOURCE_GROUP}"
    echo "3. Number of nodes = 1"
    echo "4. Node OS disk size = 70"
    echo "5. VM type = AvailabilitySet"
    echo "6. Max Pods = 100"
    echo "7. CNI = kubenet"
    echo "8. Load balancer sku = basic"
    echo "9. Cluster has to reach succeeded state"
    echo -e "\nOnce you deploy the cluster with the requested setup, use the following to validate it:"
    echo -e "aks-cm-l200lab -g $RESOURCE_GROUP -n $CLUSTER_NAME -l 1 -v\n"
}

function lab_scenario_1_validation () {
    validate_cluster_exists
    SUMMARY=0
    echo -e "\n+++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo -e "Running validation for Lab scenario $LAB_SCENARIO\n"

    echo -e "\n\n========================================================"
    # number of nodes
    STATUS3="$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query agentPoolProfiles[].count -o tsv 2>/dev/null)"
    if [ $STATUS3 -eq 1 ]
    then
        echo "Number of nodes = $STATUS3 -- Succeeded"
    else
        echo "Number of nodes = $STATUS3 -- Failed"
        let "++SUMMARY"
    fi
    # Nodes OS disk size
    STATUS4="$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query agentPoolProfiles[].osDiskSizeGb -o tsv 2>/dev/null)"
    if [ $STATUS4 -eq 70 ]
    then
        echo "Nodes OS disk size = $STATUS4 -- Succeeded"
    else
        echo "Nodes OS disk size = $STATUS4 -- Failed"
        let "++SUMMARY"
    fi
    # VM type
    STATUS5="$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query networkProfile.networkPolicy -o tsv 2>/dev/null)"
    if [ $STATUS5 == "AvailabilitySet" ]
    then
        echo "VM type = $STATUS7 -- Succeeded"
    else
        echo "VM type = $STATUS7 -- Failed"
        let "++SUMMARY"
    fi
    # Max Pods
    STATUS6="$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query agentPoolProfiles[].maxPods -o tsv 2>/dev/null)"
    if [ $STATUS6 -eq 100 ]
    then
        echo "Max Pods = $STATUS6 -- Succeeded"
    else
        echo "Max Pods = $STATUS6 -- Failed"
        let "++SUMMARY"
    fi
    # CNI
    STATUS7="$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query networkProfile.networkPlugin -o tsv 2>/dev/null)"
    if [ $STATUS7 == "kubenet" ]
    then
        echo "CNI = $STATUS7 -- Succeeded"
    else
        echo "CNI = $STATUS7 -- Failed"
        let "++SUMMARY"
    fi
    # LB sku
    STATUS8="$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query networkProfile.loadBalancerSku -o tsv 2>/dev/null)"
    if [ $STATUS8 == "Basic" ]
    then
        echo "Load balancer SKU = $STATUS8 -- Succeeded"
    else
        echo "Load balancer SKU = $STATUS8 -- Failed"
        let "++SUMMARY"
    fi
    # Cluster status
    STATUS9="$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query provisioningState -o tsv 2>/dev/null)"
    if [ $STATUS9 == "Succeeded" ]
    then
        echo "Provisioning State = $STATUS9"
    else
        echo "Provisioning State = $STATUS9"
        let "++SUMMARY"
    fi

    if [ $SUMMARY -eq 0 ]
    then
        echo -e "\n========================================================"
        echo -e "\nCluster looks good, the keyword for the assesment is:\n\ncongregate sportsmanship diagonally\n"
    else
        echo -e "\nScenario $LAB_SCENARIO is FAILED\n"
    fi
}

# Lab scenario 2
function lab_scenario_2 () {
    VNET_NAME=aks-vnet-autoscalelab
    SUBNET_NAME=aks-subnet-autoscalelab

    az group create --name $RESOURCE_GROUP --location $LOCATION

    az network vnet create \
    --resource-group $RESOURCE_GROUP \
    --name $VNET_NAME \
    --address-prefixes 10.0.0.0/16 \
    --subnet-name $SUBNET_NAME \
    --subnet-prefix 10.0.0.0/25 \
    -o table &>/dev/null
    
    SUBNET_ID=$(az network vnet subnet list \
    --resource-group $RESOURCE_GROUP \
    --vnet-name $VNET_NAME \
    --query [].id --output tsv 2>/dev/null)

    az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --location $LOCATION \
    --node-count 1 \
    --enable-cluster-autoscaler \
    --min-count 1 \
    --max-count 5 \
    --cluster-autoscaler-profile scan-interval=30s \
    --network-plugin azure \
    --service-cidr 10.2.0.0/16 \
    --dns-service-ip 10.2.0.10 \
    --docker-bridge-address 172.17.0.1/16 \
    --vnet-subnet-id $SUBNET_ID \
    --generate-ssh-keys \
    --tag l200lab=${LAB_SCENARIO} \
    -o table

    validate_cluster_exists

    az aks get-credentials -g $RESOURCE_GROUP -n $CLUSTER_NAME --overwrite-existing &>/dev/null

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web1
  labels:
    app: nginx1
spec:
  replicas: 60
  selector:
    matchLabels:
      app: nginx1
  template:
    metadata:
      labels:
        app: nginx1
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 250m
            memory: 256Mi
        ports:
        - containerPort: 80
EOF

    CLUSTER_URI="$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query id -o tsv)"
    PENDING_PODS="$(kubectl get po -l app=nginx1 | grep Pending | wc -l 2>/dev/null)"
    AUTOSCALE_EVENTS="$(kubectl -n kube-system describe configmap cluster-autoscaler-status | sed -n -e '/^Events:/,$p')"

    echo -e "\n\n********************************************************"
    echo -e "\nCluster has autoscaler enabled and a deployment called web1 was created and has pending pods."
    echo -e "Current status:\n"
    echo -e "Pending pods = $PENDING_PODS"
    echo -e "$AUTOSCALE_EVENTS\n"
    echo -e "\nYou have to fix the cluster status in order to allow the autoscaler to work"
    echo -e "Cluster uri == ${CLUSTER_URI}\n"
}

function lab_scenario_2_validation () {
    validate_cluster_exists
    LAB_TAG="$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query tags.l200lab -o tsv 2>/dev/null)"
    echo -e "\n+++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo -e "Running validation for Lab scenario $LAB_SCENARIO\n"
    if [ -z $LAB_TAG ]
    then
        echo -e "\nError: Cluster $CLUSTER_NAME in resource group $RESOURCE_GROUP was not created with this tool for lab $LAB_SCENARIO and cannot be validated...\n"
        exit 6
    elif [ $LAB_TAG -eq $LAB_SCENARIO ]
    then
        az aks get-credentials -g $RESOURCE_GROUP -n $CLUSTER_NAME --overwrite-existing &>/dev/null
        RUNNING_PODS="$(kubectl get po -l app=nginx1 | grep Running | wc -l 2>/dev/null)"
        AUTOSCALE_STATUS="$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query agentPoolProfiles[].enableAutoScaling -o tsv 2>/dev/null)"
        if [ -n $AUTOSCALE_STATUS ]
        then
            if [ "$AUTOSCALE_STATUS" == "true" ] && [ $RUNNING_PODS -eq 60 ]
            then
                echo -e "\n\n========================================================"
                echo -e "\nCluster looks good now, the keyword for the assesment is:\n\nimpromptu ruffle imminently\n"
            else
                echo -e "\nScenario $LAB_SCENARIO is still FAILED\n"
            fi
        else
            echo -e "\nCluster autoscaler is not enabled. Scenario $LAB_SCENARIO is still FAILED\n"
        fi
    else
        echo -e "\nError: Cluster $CLUSTER_NAME in resource group $RESOURCE_GROUP was not created with this tool for lab $LAB_SCENARIO and cannot be validated...\n"
        exit 6
    fi
}

# Lab scenario 3
function lab_scenario_3 () {
    az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --location $LOCATION \
    --node-count 1 \
    --generate-ssh-keys \
    --tag l200lab=${LAB_SCENARIO} \
    -o table

    validate_cluster_exists

    az aks get-credentials -g $RESOURCE_GROUP -n $CLUSTER_NAME --overwrite-existing &>/dev/null
    SP_ID=$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query servicePrincipalProfile.clientId -o tsv 2>/dev/null)
    SP_SECRET="$(az ad sp credential reset --name $SP_ID --query password -o tsv 2>/dev/null)"
    NEXT_VERSION="$(az aks get-upgrades -g $RESOURCE_GROUP -n $CLUSTER_NAME --query controlPlaneProfile.upgrades[].kubernetesVersion -o tsv 2>/dev/null)"
    az aks upgrade -g $RESOURCE_GROUP -n $CLUSTER_NAME -k $NEXT_VERSION --control-plane-only -y 2>/dev/null

    NODE_RESOURCE_GROUP="$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query nodeResourceGroup -o tsv)"
    CLUSTER_URI="$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query id -o tsv)"
    echo -e "\n\n********************************************************"
    echo -e "\nCluster upgrade attempt has failed..."
    echo -e "\nCluster uri == ${CLUSTER_URI}\n"
}

function lab_scenario_3_validation () {
    validate_cluster_exists
    LAB_TAG="$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query tags.l200lab -o tsv)"
    echo -e "\n+++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo -e "Running validation for Lab scenario $LAB_SCENARIO\n"
    if [ -z $LAB_TAG ]
    then
        echo -e "\nError: Cluster $CLUSTER_NAME in resource group $RESOURCE_GROUP was not created with this tool for lab $LAB_SCENARIO and cannot be validated...\n"
        exit 6
    elif [ $LAB_TAG -eq $LAB_SCENARIO ]
    then
        az aks get-credentials -g $RESOURCE_GROUP -n $CLUSTER_NAME --overwrite-existing &>/dev/null
        CLUSTER_STATUS="$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query provisioningState -o tsv 2>/dev/null)"
        CLUSTER_VERSION="$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query kubernetesVersion -o tsv 2>/dev/null)"
        BASE_VERSION="$(az aks get-versions -l eastus2 -o yaml | awk '/^- default: true/{flag=1; next} /upgrades:/{flag=0} flag' | grep orchestratorVersion: | awk '{print $2}' 2>/dev/null)"
        if [ $CLUSTER_STATUS == "Succeeded" ] && [[ "$BASE_VERSION" < "$CLUSTER_VERSION" ]]
        then
            echo -e "\n\n========================================================"
            echo -e "\nCluster looks good now, the keyword for the assesment is:\n\nAll Greek To Me\n"
        else
            echo -e "\nScenario $LAB_SCENARIO is still FAILED\n"
        fi
    else
        echo -e "\nError: Cluster $CLUSTER_NAME in resource group $RESOURCE_GROUP was not created with this tool for lab $LAB_SCENARIO and cannot be validated...\n"
        exit 6
    fi
}

# Lab scenario 4
function lab_scenario_4 () {
    VNET_NAME="${RESOURCE_GROUP}_vnet"
    SUBNET_NAME="${RESOURCE_GROUP}_subnet"
    az network vnet create \
        --resource-group $RESOURCE_GROUP \
        --name $VNET_NAME \
        --address-prefixes 192.168.0.0/16 \
        --dns-servers 172.20.50.2 \
        --subnet-name $SUBNET_NAME \
        --subnet-prefix 192.168.100.0/24 \
        -o table &>/dev/null
        
        SUBNET_ID=$(az network vnet subnet list \
        --resource-group $RESOURCE_GROUP \
        --vnet-name $VNET_NAME \
        --query [].id --output tsv)

        az aks create \
        --resource-group $RESOURCE_GROUP \
        --name $CLUSTER_NAME \
        --location $LOCATION \
        --kubernetes-version 1.15.7 \
        --node-count 2 \
        --node-osdisk-size 100 \
        --network-plugin azure \
        --service-cidr 10.0.0.0/16 \
        --dns-service-ip 10.0.0.10 \
        --docker-bridge-address 172.17.0.1/16 \
        --vnet-subnet-id $SUBNET_ID \
        --generate-ssh-keys \
        --tag l200lab=${LAB_SCENARIO} \
        -o table

    validate_cluster_exists
    az aks get-credentials -g $RESOURCE_GROUP -n $CLUSTER_NAME --overwrite-existing &>/dev/null

    CLUSTER_URI="$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query id -o tsv)"
    echo -e "\n\n********************************************************"
    echo -e "\nLab environment is ready. Cluster deployment failed, looks like an issue with VM custom script extention...\n"
    echo -e "\nCluster uri == ${CLUSTER_URI}\n"
}

function lab_scenario_4_validation () {
    validate_cluster_exists
    LAB_TAG="$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query tags.l200lab -o tsv)"
    if [ -z $LAB_TAG ]
    then
        echo -e "\nError: Cluster $CLUSTER_NAME in resource group $RESOURCE_GROUP was not created with this tool for lab $LAB_SCENARIO and cannot be validated...\n"
        exit 6
    elif [ $LAB_TAG -eq $LAB_SCENARIO ]
    then
        az aks get-credentials -g $RESOURCE_GROUP -n $CLUSTER_NAME --overwrite-existing &>/dev/null
        if $(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query provisioningState -o tsv | grep -q "Succeeded") && $(kubectl get no | grep -q " Ready ")
        then
            echo -e "\n\n========================================================"
            echo -e "\nCluster looks good now, the keyword for the assesment is:\n\nA Piece of Cake\n"
        else
            echo -e "\nScenario $LAB_SCENARIO is still FAILED\n"
        fi
    else
        echo -e "\nError: Cluster $CLUSTER_NAME in resource group $RESOURCE_GROUP was not created with this tool for lab $LAB_SCENARIO and cannot be validated...\n"
        exit 6
    fi    
}

#if -h | --help option is selected usage will be displayed
if [ $HELP -eq 1 ]
then
	echo "aks-cm-l200lab usage: aks-cm-l200lab -g <RESOURCE_GROUP> -n <CLUSTER_NAME> -l <LAB#> [-v|--validate] [-r|--region] [-h|--help] [--version]"
    echo -e "\nHere is the list of current labs available:\n
***************************************************************
*\t 1. Deploy AKS cluster with the specified setup
*\t 2. Cluster autoscaler enabled but not working
*\t 3. Cluster upgraded failed
*\t 4. 
***************************************************************\n"
    echo -e '"-g|--resource-group" resource group name
"-n|--name" AKS cluster name
"-l|--lab" Lab scenario to deploy
"-r|--region" region to create the resources
"-v|--validate" Validate a particular scenario
"--version" print version of aks-cm-l200lab
"-h|--help" help info\n'
	exit 0
fi

if [ $VERSION -eq 1 ]
then
	echo -e "$SCRIPT_VERSION\n"
	exit 0
fi

if [ -z $RESOURCE_GROUP ]; then
	echo -e "Error: Resource group value must be provided. \n"
	echo -e "aks-cm-l200lab usage: aks-cm-l200lab -g <RESOURCE_GROUP> -n <CLUSTER_NAME> -l <LAB#> [-v|--validate] [-r|--region] [-h|--help] [--version]\n"
	exit 7
fi

if [ -z $CLUSTER_NAME ]; then
	echo -e "Error: Cluster name value must be provided. \n"
	echo -e "aks-cm-l200lab usage: aks-cm-l200lab -g <RESOURCE_GROUP> -n <CLUSTER_NAME> -l <LAB#> [-v|--validate] [-r|--region] [-h|--help] [--version]\n"
	exit 8
fi

if [ -z $LAB_SCENARIO ]; then
	echo -e "Error: Lab scenario value must be provided. \n"
	echo -e "aks-cm-l200lab usage: aks-cm-l200lab -g <RESOURCE_GROUP> -n <CLUSTER_NAME> -l <LAB#> [-v|--validate] [-r|--region] [-h|--help] [--version]\n"
    echo -e "\nHere is the list of current labs available:\n
***************************************************************
*\t 1. Deploy AKS cluster with the specified setup
*\t 2. Cluster autoscaler enabled but not working
*\t 3. Cluster upgraded failed
*\t 4. 
***************************************************************\n"
	exit 9
fi

# lab scenario has a valid option
if [[ ! $LAB_SCENARIO =~ ^[1-4]+$ ]];
then
    echo -e "\nError: invalid value for lab scenario '-l $LAB_SCENARIO'\nIt must be value from 1 to 5\n"
    exit 10
fi

# main
echo -e "\nWelcome to the L200 Troubleshooting sessions
********************************************

This tool will use your internal azure account to deploy the lab environment.
Verifing if you are authenticated already...\n"

# Verify az cli has been authenticated
az_login_check

if [ $LAB_SCENARIO -eq 1 ] && [ $VALIDATE -eq 0 ]
then
    check_resourcegroup_cluster
    lab_scenario_1

elif [ $LAB_SCENARIO -eq 1 ] && [ $VALIDATE -eq 1 ]
then
    lab_scenario_1_validation

elif [ $LAB_SCENARIO -eq 2 ] && [ $VALIDATE -eq 0 ]
then
    check_resourcegroup_cluster
    lab_scenario_2

elif [ $LAB_SCENARIO -eq 2 ] && [ $VALIDATE -eq 1 ]
then
    lab_scenario_2_validation

elif [ $LAB_SCENARIO -eq 3 ] && [ $VALIDATE -eq 0 ]
then
    check_resourcegroup_cluster
    lab_scenario_3

elif [ $LAB_SCENARIO -eq 3 ] && [ $VALIDATE -eq 1 ]
then
    lab_scenario_3_validation

elif [ $LAB_SCENARIO -eq 4 ] && [ $VALIDATE -eq 0 ]
then
    check_resourcegroup_cluster
    lab_scenario_4

elif [ $LAB_SCENARIO -eq 4 ] && [ $VALIDATE -eq 1 ]
then
    lab_scenario_4_validation

else
    echo -e "\nError: no valid option provided\n"
    exit 11
fi

exit 0