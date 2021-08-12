#!/bin/bash

/etc/init.d/apache2 reload
/etc/init.d/mysql restart

while ! mysqladmin -u root -ppassword ping --silent; do
    sleep 1
done
