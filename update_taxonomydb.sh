#!/bin/bash

# This script must be run by w3const user.
# Update ete3 taxonomy database, ~/work-kosuge/etetoolkit/ncbitaxonomy.*
. /home/w3const/work-kosuge/mypy/bin/activate
python3 /home/w3const/fcsgx_mss/update_taxonomydb.py