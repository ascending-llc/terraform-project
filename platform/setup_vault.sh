#!/bin/bash

# Prompt the user to enter the variable name
echo "Enter Vault server URL:"
read vault_url


# Prompt the user to enter the variable value
echo "Enter Vault token:"
read -s vault_token

export VAULT_TOKEN=$vault_token
export VAULT_ADDR=$vault_url

add_secret=1
vault secrets enable -path=demo kv

while [ $add_secret -eq 1 ];
do 
    echo "Enter Username:"
    read username
    echo "Enter Password:"
    read -s password

    vault kv put demo/"$username" password=$password

    echo "Username and password stored in Vault."
    echo "Do you want to store another username/password pair?[y/n]"
    read ans

    if [ "$ans" = "n" ];
    then 
        add_secret=0
    fi
done