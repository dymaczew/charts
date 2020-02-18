#!/bin/sh

if [ $# -ne 1 ]; then
  echo "Usage: repackage.sh <version>"
  exit 1
fi

chart_version=$1

for i in "productpage details reviews mysqldb ratings"; do
helm package $i
done
mv *.tgz repo/incubator
sed  -i .bak -e "s/^version\: [0-9\.]*/version\: $chart_version/" bookinfo/Chart.yaml

helm package bookinfo
mv bookinfo-${chart_version}.tgz repo/incubator
./regenerate-index.sh
