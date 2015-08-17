#!/bin/bash
VERSION="v0.11.16"
git clone https://github.com/creationix/nvm.git /.nvm
echo ". /.nvm/nvm.sh" >> /etc/bash.bashrc
/bin/bash -c ". /.nvm/nvm.sh && nvm install $VERSION && nvm use $VERSION && nvm alias default $VERSION && ln -s /.nvm/$VERSION/bin/node /usr/bin/node && ln -s /.nvm/$VERSION/bin/npm /usr/bin/npm"
groupadd nodegrp
usermod -a -G nodegrp developer

chgrp -R nodegrp /.nvm/$VERSION/*
chmod -R 775 /.nvm/$VERSION/*
chgrp nodegrp `which npm`
chgrp nodegrp `which node`
