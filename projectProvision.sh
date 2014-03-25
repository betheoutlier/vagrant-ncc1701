#!/bin/bash

#load the variables.
. /vagrant/vagrant_vars.sh

# Ensures if the specified file is present and the md5 checksum is equal
ensureFilePresentMd5 () {
    source=$1
    target=$2
    if [ "$3" != "" ]; then description=" $3"; else description=" $source"; fi
 
    md5source=`md5sum ${source} | awk '{ print $1 }'`
    if [ -f "$target" ]; then md5target=`md5sum $target | awk '{ print $1 }'`; else md5target=""; fi

    if [ "$md5source" != "$md5target" ];
    then
        echo "Provisioning $description file to $target..."
        cp $source $target
        echo "...done"
        return 1
    else
        return 0
    fi
}

# Ensures that the specified symbolic link exists and creates it otherwise
ensureSymlink () {
    target=$1
    symlink=$2
    symlinkParent="$(dirname "$symlink")"

    #does the parent directory exist
    if ! [ -d "$symlinkParent" ];
    then
      sudo mkdir -p "$symlinkParent"
      sudo chown vagrant:vagrant $symlinkParent
      echo "Created the directory $symlinkParent in order to hold the symlink.";
    fi
    
    #does the symlink exist?
    if ! [ -L "$symlink" ];
    then
        sudo ln -s $target $symlink
        sudo chown vagrant:vagrant $symlink
        echo "Created symlink $symlink that references $target"
        return 1
    else
        echo "Did not created symlink $symlink, it already existed"
        return 0
    fi    
}

# Provision commands
provision() {
    
    # MySQL import

    #if provisioning has never been run, create the database and adjust users. 
    if [[ ! -d /.vagrantProvisioned ]]; then      
      
      #Create Sym links to mimic the production server's doc and web root
      ensureSymlink /var/www/appdev "$docRoot"
      
      #other symlinks
      ensureSymlink /var/www/appdev/html "/var/www/appdev/public_html" #the webroot between production and local are different. This bridges that diff.

      #create the project's db
      mysql -u root -h $HostName -p$dbRootPass -Bse "CREATE DATABASE $dbName;"
      echo "Database Created";

      #grant access
      mysql -u root -h $HostName -p$dbRootPass -Bse "GRANT ALL ON ${dbName}.* to $dbUser@localhost identified by '$dbPass';"
      echo "Database: User $dbUser granted access to db and a password was set";
      #import the db. 
      mysql -u $dbUser -p$dbPass $dbName < /vagrant/projectProvision/mysqlImport.sql
      echo "Database imported - sql user password was used";

#our shell scripts expect this db user
mysql -u root -h $HostName -p$dbRootPass -Bse "GRANT ALL ON ${dbName}.* TO nwemce@localhost IDENTIFIED BY '%UPDATE PASSWORD HERE';"
echo "A special MySQL user was added to conform to shell scripts on production"

      #Apache install mod_ssl
      yum install -y mod_ssl
      
      #install nano
      yum install -y nano
    
      #touch a file so that we know this provisioning has already run one initial time at least.
      sudo mkdir /.vagrantProvisioned
      sudo chown vagrant:vagrant /.vagrantProvisioned

    fi
    
    # Hosts file
    ensureFilePresentMd5 /vagrant/projectProvision/hosts /etc/hosts "hosts"
    
   # MySQL custom settings
    ensureFilePresentMd5 /vagrant/projectProvision/my.cnf /etc/my.cnf "custom MySQL settings"
    #restrart MySQL
    if [ "$?" = 1 ]; then echo "Restarting MySQL..."; /etc/init.d/mysqld restart; echo "...done"; fi
 
    # Apache conf overrides
    ensureFilePresentMd5 /vagrant/projectProvision/httpd.conf /etc/httpd/httpd.conf "custom httpd settings"
    # Apache Extras
    for file in /vagrant/projectProvision/httpd-conf/*
      do
        filename="$(basename "$file")"
        ensureFilePresentMd5 "$file" /etc/httpd/conf.d/$filename "httpd conf extra $filename was updated"
    done
   
    # PHP custom settings
    ensureFilePresentMd5 /vagrant/projectProvision/php.ini /etc/php.ini "custom PHP settings"
    
    #restart Apache/PHP
    echo "Restarting Apache/PHP..."; sudo /etc/init.d/httpd restart; echo "...done";
   
    #bash updates

    #git global config
        
    return 0
}

provision