#!/bin/bash

PS3="Select which app to interact with (#): "
select app in "Docker" "Podman"
do
echo "You have selected $app"
break
done

#decide port based on platform
PORT=""
if [[ $app = "Docker" ]]; then
    PORT="5001"
else
    PORT="5003"
fi

BASE_URL="http://localhost:$PORT"

PS3="What would you like to do? (#): "
select option in "Read DB" "Add Item" "Delete Item"
do
case "$option" in
    "Read DB") echo "You have chosen to read the DB"
               curl -i "$BASE_URL/items";;
    "Add Item") echo "You have chosen to add an item"
                read -p "Name your new item: " itemName
                curl -i -X POST "$BASE_URL/items" \
                    -H 'Content-Type: application/json' \
                    -d "{\"name\":\"$itemName\"}";;
    "Delete Item") echo "You have chosen to delete an item"
                   read -p "Item ID to delete: " id
                   curl -i -X DELETE "$BASE_URL/items/$id";;
esac
done
