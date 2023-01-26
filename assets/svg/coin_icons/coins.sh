# read each item in the JSON array to an item in the Bash array
readarray -t my_array < <(jq -c '.[]' coins.json)

# iterate through the Bash array
for item in "${my_array[@]}"; do
    echo 
    echo "Downloading $(jq '.name' <<< "$item" | xargs echo) logo from $(echo $(jq '.image' <<< "$item") | xargs echo) and saving as $(jq '.name' <<< "$item" | xargs echo).svg"
    curl $(echo $(jq '.image' <<< "$item") | xargs echo) --output "$(jq '.name' <<< "$item" | xargs echo).svg"
done
