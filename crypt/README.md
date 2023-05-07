## GPG and git-crypt

We use git-crypt to store secrets in this repository.

git-crypt relies on gpg keys for encrpytion, hence we need to generate keys for
every host, that should be able to read the encrypted files, and git-crypt-add
it to the repository.

To support this process, we provide the following tools:

1. `gpg-make-key.sh` -- Make gpg key for this host and add it to gpg keyring

2. `gpg-add-keys-to-repository.sh` -- git-add&commit public keys for this host to the `./gpg` folder.

3. `crypt-add-gpg-keys.sh` -- Add all keys in `./gpg` as git-crypt users. 

To on-board a new machine, executed steps 1,2 on the new machine followed by a
git-push. Then, git-pull on a trusted host, and execute 3 to trust the keys of
the new machine. After a git-pull on the new machine, git-crypt will be able to
decrypt the stored secrets.
