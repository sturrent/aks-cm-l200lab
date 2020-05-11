# aks-cm-l200lab

This is a set of scripts and tools use to generate a docker image that will have the aks-cm-l200lab binary used to evaluate your AKS troubleshooting skill.

It uses the shc_script_converter.sh (build using the following tool https://github.com/neurobin/shc) to abstract the lab scripts on binary format and then the use the Dockerfile to pack everyting on a Ubuntu container with az cli and kubectl.

Any time the L200 lab scripts require an update the github actions can be use to trigger a new build and push of the updated image.
This will take care of building a new script binary as well as new docker image that will get pushed to the corresponding registry.
The actions will get triggered any time a new release gets published.

Here is the general usage for the image and aks-cm-l200lab tool:

Run in docker
```docker run -it sturrent/aks-cm-l200lab:latest```

aks-cm-l200lab tool usage
```
$ aks-cm-l200lab -h
aks-cm-l200lab usage: aks-cm-l200lab -g <RESOURCE_GROUP> -n <CLUSTER_NAME> -l <LAB#> [-v|--validate] [-r|--region] [-h|--help] [--version]

Here is the list of current labs available:

***************************************************************
*        1. Deploy AKS cluster with the specified setup
*        2. Cluster autoscaler enabled but not working
*        3. Cluster upgrade failed
*        4. 
***************************************************************

"-g|--resource-group" resource group name
"-n|--name" AKS cluster name
"-l|--lab" Lab scenario to deploy
"-r|--region" region to create the resources
"-v|--validate" Validate a particular scenario
"--version" print version of aks-cm-l200lab
"-h|--help" help info
```
