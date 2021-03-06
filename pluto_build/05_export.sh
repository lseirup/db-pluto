#!/bin/bash

# make sure we are at the top of the git directory
REPOLOC="$(git rev-parse --show-toplevel)"
cd $REPOLOC

# load config
DBNAME=$(cat $REPOLOC/pluto.config.json | jq -r '.DBNAME')
DBUSER=$(cat $REPOLOC/pluto.config.json | jq -r '.DBUSER')

# export full pluto table
# export map pluto
# export map pluto clipped

echo "Exporting pluto"
psql -U $DBUSER -d $DBNAME -f $REPOLOC/pluto_build/sql/exportdata.sql

pgsql2shp -u dbadmin -f pluto_build/output/mappluto capdb "SELECT * FROM pluto WHERE geom IS NOT NULL"
pgsql2shp -u $DBUSER -f pluto_build/output/mappluto_clipped $DBNAME "SELECT * FROM pluto WHERE geom IS NOT NULL"

ogr2ogr -f "GeoJSON" pluto_build/output/mappluto.geojson PG:"host=localhost dbname=capdb user=dbadmin" \
-sql "SELECT * FROM pluto WHERE geom IS NOT NULL"

ogr2ogr -f "GeoJSON" pluto_build/output/mappluto_clipped.geojson PG:"host=localhost dbname=$DBNAME user=$DBUSER" \
-sql "SELECT * FROM mappluto_clipped WHERE geom IS NOT NULL"


pgsql2shp -u dbadmin -f pluto_build/output/dcp_mappluto_18v11 capdb "SELECT * FROM dcp_mappluto_18v11 WHERE ST_GeometryType(geom)='ST_MultiPolygon'"

scp adoyle@45.55.59.45:/prod/db-pluto/pluto_build/output/pluto.csv pluto.csv

\copy (SELECT * FROM pluto WHERE bbl LIKE '2%') TO '/prod/db-pluto/pluto_build/output/pluto.csv' DELIMITER ',' CSV HEADER;
