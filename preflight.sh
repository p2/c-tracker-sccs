#!/bin/bash

CONFIG=${CONFIGURATION}
FILE_CONFIG=./Configuration_${CONFIG}.swift
ORIG_CONFIG=./Configuration.swift

if [[ ! -e "$FILE_CONFIG" ]]; then
	echo "You must copy '$ORIG_CONFIG' to '$FILE_CONFIG' and update your settings"
	exit 1
fi

echo "Using configuration file at "$FILE_CONFIG
mv "$ORIG_CONFIG" "$ORIG_CONFIG.bkup"
cp "$FILE_CONFIG" "$ORIG_CONFIG"

# Certificate (optional)
FILE_CERT=./data-queue-certificate_${CONFIG}.crt
ORIG_CERT=./data-queue-certificate.crt

if [[ -e "$FILE_CERT" ]]; then
	echo "Using certificate file at "$FILE_CERT
	mv "$ORIG_CERT" "$ORIG_CERT.bkup"
	cp "$FILE_CERT" "$ORIG_CERT"
fi

# Movie
#MOVIE=./Videos/CTracker.mp4
#if [[ ! -e "$MOVIE" ]]; then
#	echo -e "Movie file not present at $MOVIE"
#	./postflight.sh
#	exit 1
#fi
