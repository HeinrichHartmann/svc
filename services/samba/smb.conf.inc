[all]
   path = /smb
   browsable = yes
   read only = no
   guest ok = no
   veto files = /.apdisk/.DS_Store/.TemporaryItems/.Trashes/desktop.ini/ehthumbs.db/Network Trash Folder/Temporary Items/Thumbs.db/
   delete veto files = yes
   valid users = hhartmann

[public]
   path = /smb/pub
   browsable = yes
   read only = no
   guest ok = yes
   veto files = /.apdisk/.DS_Store/.TemporaryItems/.Trashes/desktop.ini/ehthumbs.db/Network Trash Folder/Temporary Items/Thumbs.db/
   delete veto files = yes

[paperless]
   path = /smb/paperless
   browsable = yes
   read only = no
   guest ok = yes
   veto files = /.apdisk/.DS_Store/.TemporaryItems/.Trashes/desktop.ini/ehthumbs.db/Network Trash Folder/Temporary Items/Thumbs.db/
   delete veto files = yes

[hhartmann]
   force group = 
   force user = 
   path = /smb/hhartmann
   browsable = yes
   read only = no
   guest ok = no
   veto files = /.apdisk/.DS_Store/.TemporaryItems/.Trashes/desktop.ini/ehthumbs.db/Network Trash Folder/Temporary Items/Thumbs.db/
   delete veto files = yes
   valid users = hhartmann

[share]
   map archive = no
   path = /smb/share
   browsable = yes
   read only = no
   guest ok = no
   veto files = /.apdisk/.DS_Store/.TemporaryItems/.Trashes/desktop.ini/ehthumbs.db/Network Trash Folder/Temporary Items/Thumbs.db/
   delete veto files = yes
   valid users = hhartmann lhartmann
   admin users = hhartmann

[videos]
   path = /smb/share/garage/Videos
   browsable = yes
   read only = yes
   guest ok = no
   veto files = /.apdisk/.DS_Store/.TemporaryItems/.Trashes/desktop.ini/ehthumbs.db/Network Trash Folder/Temporary Items/Thumbs.db/
   delete veto files = yes
   valid users = kodi

[music]
   path = /smb/share/attic/Music
   browsable = yes
   read only = yes
   guest ok = no
   veto files = /.apdisk/.DS_Store/.TemporaryItems/.Trashes/desktop.ini/ehthumbs.db/Network Trash Folder/Temporary Items/Thumbs.db/
   delete veto files = yes
   valid users = kodi

[pictures]
   path = /smb/pictures
   browsable = yes
   read only = yes
   guest ok = no
   veto files = /.apdisk/.DS_Store/.TemporaryItems/.Trashes/desktop.ini/ehthumbs.db/Network Trash Folder/Temporary Items/Thumbs.db/
   delete veto files = yes
   valid users = hhartmann lhartmann

[lhartmann]
   path = /smb/lhartmann
   browsable = yes
   force user =
   force group =
   read only = no
   guest ok = no
   veto files = /.apdisk/.DS_Store/.TemporaryItems/.Trashes/desktop.ini/ehthumbs.db/Network Trash Folder/Temporary Items/Thumbs.db/
   delete veto files = yes
   valid users = lhartmann

[global]
    idmap config * : backend = tdb
    idmap config * : range = 10000-20000
