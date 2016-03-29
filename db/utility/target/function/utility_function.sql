CREATE OR REPLACE FUNCTION utility.fn_generate_dates(
   dt1  date,
   dt2  date,
   n    int
) RETURNS SETOF date AS
$$
	SELECT $1 + i
	FROM generate_series(0, $2 - $1, $3) i;
$$ LANGUAGE 'sql' IMMUTABLE;

CREATE OR REPLACE FUNCTION utility.last_day_of_month(date)
RETURNS date AS
$$
	SELECT (date_trunc('MONTH', $1) + INTERVAL '1 MONTH - 1 day')::date;
$$ LANGUAGE 'sql'
IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION utility.first_day_of_month(date)
RETURNS date AS
$$
	SELECT (date_trunc('MONTH', $1))::date;
$$ LANGUAGE 'sql'
IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION utility.array_random( a anyarray, OUT x anyelement )
  RETURNS anyelement AS
$func$
BEGIN
  IF a = '{}' THEN
    x := NULL::TEXT;
  ELSE
    WHILE x IS NULL LOOP
      x := a[floor(array_lower(a, 1) + (random()*( array_upper(a, 1) -  array_lower(a, 1)+1) ) )::int];
    END LOOP;
  END IF;
END
$func$ LANGUAGE plpgsql VOLATILE RETURNS NULL ON NULL INPUT;

create or replace function utility.random_string(length integer) returns text as 
$$
declare
  chars text[] := '{0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z}';
  result text := '';
  i integer := 0;
begin
  if length < 0 then
    raise exception 'Given length cannot be less than 0';
  end if;
  for i in 1..length loop
    result := result || chars[1+random()*(array_length(chars, 1)-1)];
  end loop;
  return result;
end;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION utility.pivot(refcursor, tableName text, pivotQuery text, pivotColumnQuery text, pivotColumn text, pivotColumnType text, columnList text, columnListType text)
RETURNS refcursor AS
$$
declare strColumnCoalesce text;
BEGIN

	/*
	refursor: The refcursor to be returned with pointer to result set.
	tableName: Name of temp table receiving the resultset.
	pivotQuery: SQL query providing the pivot values.
	pivotColumnQuery: SQL query providing the dynamic column list of the pivot.
	pivotColumn: The name of the pivot column.
	pivotColumnType: The name of the pivot column and its type (i.e. "ColumnName" text)
	columnList: Array of value columns of the pivot.
	columnListType: Array of value column names and type (i.e. "ColumnName" text)
	*/

	strColumnCoalesce = replace(columnList, ',', '::bigint,0), coalesce(');
   
   EXECUTE format('
	insert into %s (%s, %s)
	select %s, coalesce(%s::bigint,0)
	from crosstab(''%s'',''%s'')
	as ct( %s, %s )', tableName, pivotColumn, columnList, pivotColumn, strColumnCoalesce, pivotQuery, pivotColumnQuery, pivotColumnType, columnListType);
	
	OPEN $1 FOR EXECUTE format('select * from %s', tableName);
	return $1;
	
END
$$ LANGUAGE plpgsql;
