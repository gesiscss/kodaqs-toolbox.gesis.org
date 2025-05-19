#!/bin/bash

cd ./demo || exit
rm -rf ./_site
quarto render
