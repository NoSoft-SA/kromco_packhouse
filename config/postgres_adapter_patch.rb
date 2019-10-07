# -------------------------------------------------------------------
# Postgresql 12 does not support adsrc column.
# See https://github.com/dbcli/pgcli/issues/1058
# and https://www.postgresql.org/docs/current/catalog-pg-attrdef.html
# -------------------------------------------------------------------
# PGError: ERROR:  column d.adsrc does not exist
# LINE 1: ... a.attname, format_type(a.atttypid, a.atttypmod), d.adsrc, a...
#                                                              ^
# :             SELECT a.attname, format_type(a.atttypid, a.atttypmod), d.adsrc, a.attnotnull
#               FROM pg_attribute a LEFT JOIN pg_attrdef d
#                 ON a.attrelid = d.adrelid AND a.attnum = d.adnum
#              WHERE a.attrelid = 'users'::regclass
#                AND a.attnum > 0 AND NOT a.attisdropped
#              ORDER BY a.attnum
module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter
      def pk_and_sequence_for(table)
        # First try looking for a sequence with a dependency on the
        # given table's primary key.
        result = query(<<-end_sql, 'PK and serial sequence')[0]
          SELECT attr.attname, name.nspname, seq.relname
          FROM pg_class      seq,
               pg_attribute  attr,
               pg_depend     dep,
               pg_namespace  name,
               pg_constraint cons
          WHERE seq.oid           = dep.objid
            AND seq.relnamespace  = name.oid
            AND seq.relkind       = 'S'
            AND attr.attrelid     = dep.refobjid
            AND attr.attnum       = dep.refobjsubid
            AND attr.attrelid     = cons.conrelid
            AND attr.attnum       = cons.conkey[1]
            AND cons.contype      = 'p'
            AND dep.refobjid      = '#{table}'::regclass
        end_sql

        if result.nil? or result.empty?
          # If that fails, try parsing the primary key's default value.
          # Support the 7.x and 8.0 nextval('foo'::text) as well as
          # the 8.1+ nextval('foo'::regclass).
          # TODO: assumes sequence is in same schema as table.
          result = query(<<-end_sql, 'PK and custom sequence')[0]
            SELECT attr.attname, name.nspname, split_part(pg_catalog.pg_get_expr(def.adbin, def.adrelid, true), '''', 2)
            FROM pg_class       t
            JOIN pg_namespace   name ON (t.relnamespace = name.oid)
            JOIN pg_attribute   attr ON (t.oid = attrelid)
            JOIN pg_attrdef     def  ON (adrelid = attrelid AND adnum = attnum)
            JOIN pg_constraint  cons ON (conrelid = adrelid AND adnum = conkey[1])
            WHERE t.oid = '#{table}'::regclass
              AND cons.contype = 'p'
              AND pg_catalog.pg_get_expr(def.adbin, def.adrelid, true) ~* 'nextval'
          end_sql
        end
        # check for existence of . in sequence name as in public.foo_sequence.  if it does not exist, return unqualified sequence
        # We cannot qualify unqualified sequences, as rails doesn't qualify any table access, using the search path
        [result.first, result.last]
      rescue
        nil
      end

      private
      def column_definitions(table_name)
        query <<-end_sql
          SELECT a.attname, format_type(a.atttypid, a.atttypmod), pg_catalog.pg_get_expr(d.adbin, d.adrelid, true) as adsrc, a.attnotnull
            FROM pg_attribute a LEFT JOIN pg_attrdef d
              ON a.attrelid = d.adrelid AND a.attnum = d.adnum
           WHERE a.attrelid = '#{table_name}'::regclass
             AND a.attnum > 0 AND NOT a.attisdropped
           ORDER BY a.attnum
        end_sql
      end
    end
  end
end
