name             'chef-instant-coder'
maintainer       'Calvin So'
maintainer_email 'calvin.so@non-exist.com'
description      'A Chef cookbook provisioning all the basic software stack for a typical RoR developer.'
long_description 'A Chef cookbook provisioning all the basic software stack for a typical RoR developer.'
version          '1.1'

depends 'ntp'
depends 'nginx'
depends 'git'
depends 'build-essential'
depends 'vim'
depends 'ruby_build'
depends 'rbenv'
depends 'imagemagick'
depends 'redisio'
depends 'java'
