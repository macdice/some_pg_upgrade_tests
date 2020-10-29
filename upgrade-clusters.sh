#!/bin/sh

TARGET_BRANCH=collation-versioning
#export PGOPTIONS='--client-min-messages=warning'

run_query()
{
  target_install=$1
  target_pgdata=$2
  query="$3"

  $target_install/bin/psql postgres -c "$query" >> $target_pgdata/query_output.txt 2>&1
}

dump_versions()
{
  target_install=$1
  target_pgdata=$2

  run_query $target_install $target_pgdata "
    SELECT i.relname, c.collname, coalesce(refobjversion, '<NULL>') as version
    FROM pg_depend d
    JOIN pg_class i ON i.oid = d.objid
    JOIN pg_collation c ON d.refobjid = c.oid
    WHERE i.relname IN ('a_t_idx', 'b_t_idx', 'c_t_idx', 'd_t_idx')
    ORDER BY 1, 2"
}

do_upgrade_test()
{
  source_install=$1
  target_install=$2
  source_pgdata=$3
  target_pgdata=$4

  # perform the upgrade
  rm -fr $target_pgdata
  $target_install/bin/initdb -D $target_pgdata
  $target_install/bin/pg_upgrade -b $source_install/bin -d $source_pgdata -D $target_pgdata

  # also just capture the pg_dump output for eyeball review
  $source_install/bin/pg_ctl start -w -D $source_pgdata
  $target_install/bin/pg_dump postgres --binary-upgrade --schema-only > $source_pgdata/pg_upgrade.dump
  $source_install/bin/pg_ctl stop -w -D $source_pgdata

  # examine the results
  $target_install/bin/pg_ctl start -w -D $target_pgdata
  dump_versions $target_install $target_pgdata
  run_query $target_install $target_pgdata "
    select * from a
    union all
    select * from b
    union all
    select * from c
    union all
    select * from d"
  run_query $target_install $target_pgdata "reindex database postgres"
  dump_versions $target_install $target_pgdata
  $target_install/bin/pg_ctl stop -w -D $target_pgdata
}

for branch in $TARGET_BRANCH REL_13_STABLE REL9_6_STABLE ; do
  # non-ICU -> non-ICU
  do_upgrade_test install/$branch install/$TARGET_BRANCH pgdata-old/$branch pgdata-new/$branch

  # non-ICU -> ICU
  do_upgrade_test install/$branch install-icu/$TARGET_BRANCH pgdata-old/$branch pgdata-icu-new/$branch

  if echo $branch | grep -v -E 'REL[6789]' > /dev/null ; then
    # ICU -> ICU
    do_upgrade_test install/$branch install-icu/$TARGET_BRANCH pgdata-old/$branch-icu pgdata-icu-new/$branch-icu

    # ICU -> non ICU (this fails, can't create tables that reference non-existence collations!)
    do_upgrade_test install/$branch install/$TARGET_BRANCH pgdata-old/$branch-icu pgdata-new/$branch-icu
  fi
done
