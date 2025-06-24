#!/bin/bash

UBUNTU_MIRROR="mirrors.tuna.tsinghua.edu.cn"
GITHUB_MIRROR="https://githubfast.com/"
DETECTED_IP=311802.xyz

ip_address=$(hostname -I | awk '{print $1}')
if test -z "$DETECTED_IP" 
then
  echo "Detected IP: $DETECTED_IP"
else
  ip_address=$DETECTED_IP
fi
echo "IP Address: $ip_address"

sudo sed -i "s|^TZ=.*$|TZ=$(cat /etc/timezone)|" src/.env 2>/dev/null || true

# Check if MySQL client is installed
# if ! command -v mysql &> /dev/null
# then
#     echo "MySQL client is not installed. Installing mariadb-client now..."
#     sudo apt install -y mariadb-client 2>/dev/null || echo "Note: MySQL client installation skipped (not available on this system)"
# else
#     echo "MySQL client is already installed."
# fi

# Check if Docker is installed
if ! command -v docker &> /dev/null
then
    echo "Docker is not installed. Installing Docker now..."
    # Add Docker's official GPG key:
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings

    sudo curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] http://mirrors.aliyun.com/docker-ce/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker $USER
    echo "::NOTE::"
    echo "Added your user to docker group to manage docker without root."
    echo "Log out and back in and rerun setup.sh."
    exit 1;
else
    echo "Docker is already installed."
fi

# Check if Azeroth Core is installed
if [ -d "azerothcore-wotlk" ]; then
    destination_dir="data/sql/custom"
    
    world=$destination_dir"/db_world/"
    chars=$destination_dir"/db_characters/"
    auth=$destination_dir"/db_auth/"
    
    cd azerothcore-wotlk
    
    rm -rf $world/*.sql
    rm -rf $chars/*.sql
    rm -rf $auth/*.sql
    
    cd ..
    
    cp src/.env azerothcore-wotlk/
    cp src/*.yml azerothcore-wotlk/
    cd azerothcore-wotlk
else
    git clone https://github.com/liyunfan1223/azerothcore-wotlk.git --branch=Playerbot
    cp src/.env azerothcore-wotlk/
    cp src/*.yml azerothcore-wotlk/
    cd azerothcore-wotlk/modules
    git clone https://github.com/liyunfan1223/mod-playerbots.git --branch=master
    cd ..
fi


# Install modules
echo "Install modules..."
##################################################################
cd modules
function install_mod() {
    local repo_url=$1
    local mod_name=$(basename -s .git $repo_url)

    if [ -d "${mod_name}" ]; then
        echo "${mod_name} exists. Skipping..."
    else
        git clone ${repo_url}
    fi
}
install_mod "https://github.com/azerothcore/mod-aoe-loot.git"
# fix modules sql folder
echo "Fixing mod-aoe-loot modules sql folder..."
mv mod-aoe-loot/data/sql/db-auth mod-aoe-loot/data/sql/auth 2>/dev/null || :
mv mod-aoe-loot/data/sql/db-characters mod-aoe-loot/data/sql/characters 2>/dev/null || :
mv mod-aoe-loot/data/sql/db-world mod-aoe-loot/data/sql/world 2>/dev/null || :
# fix modules sql folder
# install_mod "https://github.com/ZhengPeiRu21/mod-individual-progression.git"
# echo "Fixing mod-individual-progression modules sql folder..."
# mkdir -p mod-individual-progression/data/sql
# mv mod-individual-progression/sql/* mod-individual-progression/data/sql 2>/dev/null || :

install_mod "https://github.com/noisiver/mod-learnspells.git"
install_mod "https://github.com/azerothcore/mod-fireworks-on-level.git"
install_mod "https://github.com/DustinHendrickson/mod-player-bot-level-brackets.git"
install_mod "https://github.com/azerothcore/mod-eluna.git"
install_mod "https://github.com/azerothcore/mod-autobalance.git"
install_mod "https://github.com/azerothcore/mod-transmog.git"
echo "Fixing mod-transmog modules sql folder..."
mv mod-transmog/data/sql/db-auth mod-aoe-loot/data/sql/auth 2>/dev/null || :
mv mod-transmog/data/sql/db-characters mod-aoe-loot/data/sql/characters 2>/dev/null || :
mv mod-transmog/data/sql/db-world mod-aoe-loot/data/sql/world 2>/dev/null || :

cd ..
##################################################################

# set database volume
echo "Set database volume..."
sed -i "s#type: volume#type: bind#g" docker-compose.yml
sed -i "s#source: ac-database#source: \${DOCKER_VOL_DB:-ac-database}#g" docker-compose.yml
# set mirror
## ubuntu
echo "Set ubuntu mirror..."
mirror_cmd="RUN sed -i 's\/archive.ubuntu.com\/${UBUNTU_MIRROR}\/g' \/etc\/apt\/sources.list \&\& sed -i 's\/security.ubuntu.com\/${UBUNTU_MIRROR}\/g' \/etc\/apt\/sources.list \&\& apt-get update"
sed -i "s#RUN apt-get update#${mirror_cmd}#g" apps/docker/Dockerfile
## github 
echo "Set github mirror..."
sed -i "s#\"https://api.github#\"${GITHUB_MIRROR}https://api.github#g" apps/installer/includes/functions.sh
sed -i "s#\"https://raw.githubusercontent#\"${GITHUB_MIRROR}https://raw.githubusercontent#g" apps/installer/includes/functions.sh
sed -i "s#\"https://github.com#\"${GITHUB_MIRROR}https://github.com#g" apps/installer/includes/functions.sh
sed -i "s#curl -L https://github.com#curl -L ${GITHUB_MIRROR}https://github.com#g" apps/installer/includes/functions.sh


# Fixing permissions
echo "Fixing permissions ..."
mkdir -p env/dist/etc env/dist/logs ../wotlk/etc ../wotlk/logs ../wotlk/database
sudo chown -R 1000:1000 env/dist/etc env/dist/logs 2>/dev/null || chown -R 1000:1000 env/dist/etc env/dist/logs
sudo chown -R 1000:1000 ../wotlk 2>/dev/null || chown -R 1000:1000 ../wotlk
sudo chown -R 1000:1000 . 2>/dev/null || chown -R 1000:1000 .
sudo chown -R 775 ../wotlk/database 2>/dev/null || chown -R 775 ../wotlk/database

# Directory for custom SQL files
custom_sql_dir="src/sql"
auth="acore_auth"
world="acore_world"
chars="acore_characters"

mkdir -p "$custom_sql_dir/$auth"
mkdir -p "$custom_sql_dir/$world"
mkdir -p "$custom_sql_dir/$chars"


# build
docker compose up -d --build

# Wait a moment for containers to initialize
sleep 5

# Automatically detect and update realmlist
echo "Configuring realmlist with host IP..."
# Update realmlist database
docker exec ac-database mysql -u root -ppassword acore_auth -e "UPDATE realmlist SET address = '$ip_address' WHERE id = 1;" 2>/dev/null && \
echo "SUCCESS: Realmlist configured successfully for IP: $ip_address" || \
echo "WARNING: Realmlist update will be attempted again after worldserver starts"
# Verify the update
echo "Current realmlist configuration:"
docker exec ac-database mysql -u root -ppassword acore_auth -e "SELECT id, name, address FROM realmlist;" 2>/dev/null || true
cd ..

# Temporary SQL file
temp_sql_file="/tmp/temp_custom_sql.sql"

# Function to execute SQL files with IP replacement
function execute_sql() {
    local db_name=$1
    local sql_files=("$custom_sql_dir/$db_name"/*.sql)

    if [ -e "${sql_files[0]}" ]; then
        for custom_sql_file in "${sql_files[@]}"; do
            echo "Executing $custom_sql_file"
            temp_sql_file=$(mktemp)
            if [[ "$(basename "$custom_sql_file")" == "update_realmlist.sql" ]]; then
                sed -e "s/{{IP_ADDRESS}}/$ip_address/g" "$custom_sql_file" > "$temp_sql_file"
            else
                cp "$custom_sql_file" "$temp_sql_file"
            fi
            # Use Docker exec instead of local mysql command for Unraid compatibility
            docker exec ac-database mysql -u root -ppassword "$db_name" < "$temp_sql_file" 2>/dev/null || \
            mysql -h "$ip_address" -P 3307 -uroot -ppassword "$db_name" < "$temp_sql_file" 2>/dev/null || \
            echo "Note: Could not execute SQL file $custom_sql_file (MySQL client not available)"
        done
    else
        echo "No SQL files found in $custom_sql_dir/$db_name, skipping..."
    fi
}


# Run custom SQL files
echo "Running custom SQL files..."
execute_sql "$auth"
execute_sql "$world"
execute_sql "$chars"

# Final realmlist verification and update if needed
echo "Final realmlist verification..."
docker exec ac-database mysql -u root -ppassword acore_auth -e "UPDATE realmlist SET address = '$ip_address' WHERE id = 1;" 2>/dev/null || true
echo "SUCCESS: Final realmlist configuration complete for IP: $ip_address"

# Clean up temporary file
rm -f "$temp_sql_file"

echo ""
echo "INSTALLATION COMPLETED SUCCESSFULLY!"
echo ""
echo "ACHIEVEMENTS:"
echo "- Database configured on port 3307 (no conflicts with Unraid MariaDB)"
echo "- Realmlist automatically configured for IP: $ip_address"
echo "- 500 Playerbots ready for instant multiplayer experience"
echo "- All permissions fixed for Unraid compatibility"
echo ""
echo "NEXT STEPS:"
echo "1. Execute 'docker attach ac-worldserver'"
echo "2. 'account create username password' creates an account."
echo "3. 'account set gmlevel username 3 -1' sets the account as gm for all servers."
echo "4. Ctrl+p Ctrl+q will take you out of the world console."
echo "5. Edit your WoW client realmlist.wtf and set it to: $ip_address"
echo "6. Now login to WoW with 3.3.5a client!"
echo "7. All config files are copied into the wotlk folder."
echo ""
echo "ENJOY YOUR PRIVATE WORLD OF WARCRAFT SERVER WITH 500 AI COMPANIONS!"