#!/bin/sh

TARGET_BRANCH=collation-versioning
export PGOPTIONS='--client-min-messages=warning'

do_test()
{
  source_install=$1
  target_install=$2
  source_pgdata=$3
  target_pgdata=$4

  rm -fr $target_pgdata
  $source_install/bin/initdb -D $target_pgdata
  install-icu/$TARGET_BRANCH/bin/pg_upgrade -b install-icu/$branch/bin -d pgdata-old/$branch-icu -D pgdata-icu-new/$branch-icu
  # also just capture the pg_dump output for review
  install-icu/$branch/bin/pg_ctl start -w -D pgdata-old/$branch-icu
  install-icu/$TARGET_BRANCH/bin/pg_dump postgres --binary-upgrade --schema-only > pgdata-old/$branch-icu/pg_upgrade.dump
  install-icu/$branch/bin/pg_ctl stop -w -D pgdata-old/$branch-icu

  # also do a quick simple_test check on the result
  install-icu/$TARGET_BRANCH/bin/pg_ctl start -w -D pgdata-icu-new/$branch-icu
  install-icu/$TARGET_BRANCH/bin/psql postgres -c "SELECT i.relname, c.collname, coalesce(refobjversion, '<NULL>') as version FROM pg_depend d JOIN pg_class i ON i.oid = d.objid JOIN pg_collation c ON d.refobjid = c.oid WHERE i.relname IN ('a_t_idx', 'b_t_idx', 'c_t_idx', 'd_t_idx', 'e_t_idx') ORDER BY 1, 2" >> pgdata-icu-new/$branch-icu/simple_test.out
  install-icu/$TARGET_BRANCH/bin/psql postgres -c "select * from a union all select * from b union all select * from c union all select * from d union all select * from e" >> pgdata-icu-new/$branch-icu/simple_test.out 2>&1
  install-icu/$TARGET_BRANCH/bin/psql postgres -c "reindex database postgres" >> pgdata-icu-new/$branch-icu/simple_test.out
  install-icu/$TARGET_BRANCH/bin/psql postgres -c "SELECT i.relname, c.collname, coalesce(refobjversion, '<NULL>') as version FROM pg_depend d JOIN pg_class i ON i.oid = d.objid JOIN pg_collation c ON d.refobjid = c.oid WHERE i.relname IN ('a_t_idx', 'b_t_idx', 'c_t_idx', 'd_t_idx', 'e_t_idx') ORDER BY 1, 2" >> pgdata-icu-new/$branch-icu/simple_test.out
  install-icu/$TARGET_BRANCH/bin/pg_ctl stop -w -D pgdata-icu-new/$branch-icu

  # ICU -> non ICU (this fails, can't create tables!)
  install/$TARGET_BRANCH/bin/initdb -D pgdata-new/$branch-icu
  install/$TARGET_BRANCH/bin/pg_upgrade -b install/$branch-icu/bin -d pgdata-old/$branch-icu -D pgdata-new/$branch-icu
}

for branch in $TARGET_BRANCH REL_13_STABLE REL9_6_STABLE ; do
  # non-ICU -> non-ICU
  rm -fr pgdata-new/$branch
  install/$TARGET_BRANCH/bin/initdb -D pgdata-new/$branch
  install/$TARGET_BRANCH/bin/pg_upgrade -b install/$branch/bin -d pgdata-old/$branch -D pgdata-new/$branch
  # also just capture the pg_dump output for review
  install/$branch/bin/pg_ctl start -w -D pgdata-old/$branch
  install/$TARGET_BRANCH/bin/pg_dump postgres --binary-upgrade --schema-only > pgdata-old/$branch/pg_upgrade.dump
  install/$branch/bin/pg_ctl stop -w -D pgdata-old/$branch
  # also do a quick simple_test check on the result
  install/$TARGET_BRANCH/bin/pg_ctl start -w -D pgdata-new/$branch
  install/$TARGET_BRANCH/bin/psql postgres -c "SELECT i.relname, c.collname, coalesce(refobjversion, '<NULL>') as version FROM pg_depend d JOIN pg_class i ON i.oid = d.objid JOIN pg_collation c ON d.refobjid = c.oid WHERE i.relname IN ('a_t_idx', 'b_t_idx', 'c_t_idx', 'd_t_idx', 'e_t_idx') ORDER BY 1, 2" >> pgdata-new/$branch/simple_test.out
  install/$TARGET_BRANCH/bin/psql postgres -c "select * from a union all select * from b union all select * from c union all select * from d" >> pgdata-new/$branch/simple_test.out 2>&1
  install/$TARGET_BRANCH/bin/psql postgres -c "reindex database postgres" >> pgdata-new/$branch/simple_test.out 2>&1
  install/$TARGET_BRANCH/bin/psql postgres -c "SELECT i.relname, c.collname, coalesce(refobjversion, '<NULL>') as version FROM pg_depend d JOIN pg_class i ON i.oid = d.objid JOIN pg_collation c ON d.refobjid = c.oid WHERE i.relname IN ('a_t_idx', 'b_t_idx', 'c_t_idx', 'd_t_idx', 'e_t_idx') ORDER BY 1, 2" >> pgdata-new/$branch/simple_test.out
  install/$TARGET_BRANCH/bin/pg_ctl stop -w -D pgdata-new/$branch

  # non-ICU -> ICU
  rm -fr pgdata-icu-new/$branch
  install-icu/$TARGET_BRANCH/bin/initdb -D pgdata-icu-new/$branch
  install-icu/$TARGET_BRANCH/bin/pg_upgrade -b install/$branch/bin -d pgdata-old/$branch -D pgdata-icu-new/$branch
  # also just capture the pg_dump output for review
  install/$branch/bin/pg_ctl start -w -D pgdata-old/$branch
  install/$TARGET_BRANCH/bin/pg_dump postgres --binary-upgrade --schema-only > pgdata-old/$branch/pg_upgrade.dump
  install/$branch/bin/pg_ctl stop -w -D pgdata-old/$branch
  # also do a quick simple_test check on the result
  install-icu/$TARGET_BRANCH/bin/pg_ctl start -w -D pgdata-icu-new/$branch
  install-icu/$TARGET_BRANCH/bin/psql postgres -c "SELECT i.relname, c.collname, coalesce(refobjversion, '<NULL>') as version FROM pg_depend d JOIN pg_class i ON i.oid = d.objid JOIN pg_collation c ON d.refobjid = c.oid WHERE i.relname IN ('a_t_idx', 'b_t_idx', 'c_t_idx', 'd_t_idx', 'e_t_idx') ORDER BY 1, 2" >> pgdata-icu-new/$branch/simple_test.out
  install-icu/$TARGET_BRANCH/bin/psql postgres -c "select * from a union all select * from b union all select * from c union all select * from d" >> pgdata-icu-new/$branch/simple_test.out 2>&1
  install-icu/$TARGET_BRANCH/bin/psql postgres -c "reindex database postgres" >> pgdata-icu-new/$branch/simple_test.out
  install-icu/$TARGET_BRANCH/bin/psql postgres -c "SELECT i.relname, c.collname, coalesce(refobjversion, '<NULL>') as version FROM pg_depend d JOIN pg_class i ON i.oid = d.objid JOIN pg_collation c ON d.refobjid = c.oid WHERE i.relname IN ('a_t_idx', 'b_t_idx', 'c_t_idx', 'd_t_idx', 'e_t_idx') ORDER BY 1, 2" >> pgdata-icu-new/$branch/simple_test.out
  install-icu/$TARGET_BRANCH/bin/pg_ctl stop -w -D pgdata-icu-new/$branch

  if echo $branch | grep -v -E 'REL[6789]' > /dev/null ; then
    # ICU -> ICU
    rm -fr pgdata-icu-new/$branch-icu
    install-icu/$TARGET_BRANCH/bin/initdb -D pgdata-icu-new/$branch-icu
    install-icu/$TARGET_BRANCH/bin/pg_upgrade -b install-icu/$branch/bin -d pgdata-old/$branch-icu -D pgdata-icu-new/$branch-icu
    # also just capture the pg_dump output for review
    install-icu/$branch/bin/pg_ctl start -w -D pgdata-old/$branch-icu
    install-icu/$TARGET_BRANCH/bin/pg_dump postgres --binary-upgrade --schema-only > pgdata-old/$branch-icu/pg_upgrade.dump
    install-icu/$branch/bin/pg_ctl stop -w -D pgdata-old/$branch-icu

    # also do a quick simple_test check on the result
    install-icu/$TARGET_BRANCH/bin/pg_ctl start -w -D pgdata-icu-new/$branch-icu
    install-icu/$TARGET_BRANCH/bin/psql postgres -c "SELECT i.relname, c.collname, coalesce(refobjversion, '<NULL>') as version FROM pg_depend d JOIN pg_class i ON i.oid = d.objid JOIN pg_collation c ON d.refobjid = c.oid WHERE i.relname IN ('a_t_idx', 'b_t_idx', 'c_t_idx', 'd_t_idx', 'e_t_idx') ORDER BY 1, 2" >> pgdata-icu-new/$branch-icu/simple_test.out
    install-icu/$TARGET_BRANCH/bin/psql postgres -c "select * from a union all select * from b union all select * from c union all select * from d union all select * from e" >> pgdata-icu-new/$branch-icu/simple_test.out 2>&1
    install-icu/$TARGET_BRANCH/bin/psql postgres -c "reindex database postgres" >> pgdata-icu-new/$branch-icu/simple_test.out
    install-icu/$TARGET_BRANCH/bin/psql postgres -c "SELECT i.relname, c.collname, coalesce(refobjversion, '<NULL>') as version FROM pg_depend d JOIN pg_class i ON i.oid = d.objid JOIN pg_collation c ON d.refobjid = c.oid WHERE i.relname IN ('a_t_idx', 'b_t_idx', 'c_t_idx', 'd_t_idx', 'e_t_idx') ORDER BY 1, 2" >> pgdata-icu-new/$branch-icu/simple_test.out
    install-icu/$TARGET_BRANCH/bin/pg_ctl stop -w -D pgdata-icu-new/$branch-icu

    # ICU -> non ICU (this fails, can't create tables!)
    install/$TARGET_BRANCH/bin/initdb -D pgdata-new/$branch-icu
    install/$TARGET_BRANCH/bin/pg_upgrade -b install/$branch-icu/bin -d pgdata-old/$branch-icu -D pgdata-new/$branch-icu
  fi
done
