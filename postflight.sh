#!/bin/bash

ORIG_CONFIG=./Configuration.swift
if [[ -e "$ORIG_CONFIG.bkup" ]]; then
	mv "$ORIG_CONFIG.bkup" "$ORIG_CONFIG"
fi

ORIG_CERT=./public-ctracker.crt
if [[ -e "$ORIG_CERT.bkup" ]]; then
	mv "$ORIG_CERT.bkup" "$ORIG_CERT"
fi
