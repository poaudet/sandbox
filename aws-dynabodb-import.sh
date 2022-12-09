#/bin/sh

for file in ~/AWS/toImport/*
do
  aws dynamodb put-item \
  --table-name pfa_dev \
  --item file://"$file"
done