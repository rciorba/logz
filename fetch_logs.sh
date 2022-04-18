#!/bin/sh

scp rciorba@devrandom.ro:/var/log/nginx/access.log.* ./data/

gunzip --force ./data/access.*.gz

for file in ./data/access.log.* ; do
    hash=`md5sum ${file} | awk '{ print $1 }'`
    echo mv $file ./data/$hash
    mv $file ./data/$hash
done
