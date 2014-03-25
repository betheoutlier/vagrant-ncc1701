##### PATHS #####
#Paths to your webRoot will also have to be set in your Apache vhost files. Please review:
#%vagrant%/projectProvision/httpd-conf/10-appdev.conf
#%vagrant%/projectProvision/httpd-conf/ssl.conf
docRoot="/home/acctname"
webRoot="/home/acctname/html"
    
##### MYSQL #####
HostName="localhost" #requried
dbName="acctname_enterprise" #requried
dbUser="acctname_acctname" #requried
dbPass="" #requried
dbRootPass="" #required

#the root user is used by Puppet provisioning. If you HAVE to change root user info, you will have to adjust that provisioning. 
#I recommend you just use a different user and define it above. 
dbRootPass="media1" #updating this value alone will not suffice in updating the root user password.