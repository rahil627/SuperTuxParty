#!/bin/sh

mkdir -p /usr/share/supertuxparty
echo '#!/bin/sh\ncd $(dirname $(realpath $0))\n./supertuxparty'> /usr/share/supertuxparty/run.sh
chmod +x /usr/share/supertuxparty/run.sh
cp build/supertuxparty /usr/share/supertuxparty
cp build/supertuxparty.pck /usr/share/supertuxparty
cp -r build/plugins /usr/share/supertuxparty/plugins
ln -sf /usr/share/supertuxparty/run.sh /bin/supertuxparty
