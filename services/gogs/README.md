# gogs

From: https://github.com/gogs/gogs

Cloning via ssh has been problematic. With the builtin ssh server we had more luck recently.

When git-push complains about [algorithm mismatch](https://github.com/gogs/gogs/issues/6623) try
adding this to the client `~/.ssh/config` 

```
Host gogs.heinrichhartmann.net
   Port 2222
   HostKeyAlgorithms +ssh-rsa
   PubkeyAcceptedAlgorithms +ssh-rsa
```
