#!/bin/bash

# This script must be run by w3const user.
# Update ete3 taxonomy database, ~/work-kosuge/etetoolkit/ncbitaxonomy.*

. /home/w3const/work-kosuge/mypy/bin/activate

# Log
exec > >(tee /home/w3const/work-kosuge/etetoolkit/update_taxonomydb.log) 2>&1

cd ~/fcsgx_mss
python3 update_taxonomydb.py