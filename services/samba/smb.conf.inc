[global]
    idmap config * : backend = tdb
    idmap config * : range = 10000-20000

[public]
   path = /share/public
   browsable = yes
   read only = no
   guest ok = yes
   veto files = /.apdisk/.DS_Store/.TemporaryItems/.Trashes/desktop.ini/ehthumbs.db/Network Trash Folder/Temporary Items/Thumbs.db/
   delete veto files = yes

[hhartmann]
   path = /share/hhartmann
   browsable = yes
   read only = no
   guest ok = no
   veto files = /.apdisk/.DS_Store/.TemporaryItems/.Trashes/desktop.ini/ehthumbs.db/Network Trash Folder/Temporary Items/Thumbs.db/
   delete veto files = yes
   valid users = hhartmann

[lhartmann]
   path = /share/lhartmann
   browsable = yes
   force user =
   force group =
   read only = no
   guest ok = no
   veto files = /.apdisk/.DS_Store/.TemporaryItems/.Trashes/desktop.ini/ehthumbs.db/Network Trash Folder/Temporary Items/Thumbs.db/
   delete veto files = yes
   valid users = lhartmann hhartmann

[paperless] # used by scanner
   path = /share/hhartmann/var/paperless/consume/scan
   browsable = yes
   read only = no
   guest ok = yes
   veto files = /.apdisk/.DS_Store/.TemporaryItems/.Trashes/desktop.ini/ehthumbs.db/Network Trash Folder/Temporary Items/Thumbs.db/
   delete veto files = yes
