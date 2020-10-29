#!/bin/sh

TARGET_BRANCH=collation-versioning

rm -fr pgdata-new pgdata-icu-new pgdata-old

for branch in $TARGET_BRANCH REL_13_STABLE REL9_6_STABLE ; do
  # non-ICU version
  rm -fr pgdata-old/$branch
  install/$branch/bin/initdb -D pgdata-old/$branch
  install/$branch/bin/pg_ctl start -w -D pgdata-old/$branch
  install/$branch/bin/psql postgres -c 'create table a (t text)'
  install/$branch/bin/psql postgres -c 'create index on a(t)'
  install/$branch/bin/psql postgres -c 'create table b (t text collate "C")'
  install/$branch/bin/psql postgres -c 'create index on b(t)'
  install/$branch/bin/psql postgres -c 'create table c (t text collate "en_US")'
  install/$branch/bin/psql postgres -c 'create index on c(t)'
  install/$branch/bin/psql postgres -c 'create table d (t text collate "fr_FR")'
  install/$branch/bin/psql postgres -c 'create index on d(t)'
  if [ "$branch" = "$TARGET_BRANCH" ] ; then
    install/$branch/bin/psql postgres -c "update pg_depend set refobjversion = '0.001' where objid = 'd_t_idx'::regclass and refobjversion is not null"
  fi
  install/$branch/bin/pg_ctl stop -w -D pgdata-old/$branch
  # ICU version
  if echo $branch | grep -v -E 'REL[6789]' > /dev/null ; then
    rm -fr pgdata-old/$branch-icu
    install-icu/$branch/bin/initdb -D pgdata-old/$branch-icu
    install-icu/$branch/bin/pg_ctl start -w -D pgdata-old/$branch-icu
    install-icu/$branch/bin/psql postgres -c 'create table a (t text)'
    install-icu/$branch/bin/psql postgres -c 'create index on a(t)'
    install-icu/$branch/bin/psql postgres -c 'create table b (t text collate "C")'
    install-icu/$branch/bin/psql postgres -c 'create index on b(t)'
    install-icu/$branch/bin/psql postgres -c 'create table c (t text collate "fr-x-icu")'
    install-icu/$branch/bin/psql postgres -c 'create index on c(t)'
    install-icu/$branch/bin/psql postgres -c 'create table d (t text collate "fr_FR")'
    install-icu/$branch/bin/psql postgres -c 'create index on d(t)'
    if [ "$branch" = "$TARGET_BRANCH" ] ; then
      install-icu/$branch/bin/psql postgres -c "update pg_depend set refobjversion = '0.001' where objid = 'd_t_idx'::regclass and refobjversion is not null"
    fi
    install-icu/$branch/bin/pg_ctl stop -w -D pgdata-old/$branch-icu
  fi
done
