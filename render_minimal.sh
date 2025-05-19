#!/bin/bash

cd ./minimal_example || exit
rm -rf ./_site
quarto render
