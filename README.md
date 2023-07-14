# Brass

The Ctrl-O management system.

## Producing Latex documents

These links required:

```
/var/lib/brass/tex
ln -s ../../../../usr/bin/extractbb
ln -s ../../../../usr/bin/xdvipdfmx
ln -s ../../../../usr/bin/xelatex
```

## Commands for fuse folder mounting

```
bin/fuse.pl /home/abeverley/receipts &
fusermount -u /home/abeverley/receipts
```

## Add cron job for brass
```
30 02 * * * /srv/Brass/bin/status.pl
```

## Running configdb.pl

A configuration file ```~/.configdb``` is needed to run configdb.pl. Values align with entries in the Brass database. The SMTP entry is optional and provides the return value when running configdb.pl with the smtp action.

```
[myorg]
email=john@example.com
dbhost=brass.example.com
passphrase=The passphrase for encrypted passwords
smtp=smtp.example.com
```
