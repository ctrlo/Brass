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
