# fcsgx_mss
FCSgx-related scripts to assist MSS works for quick screening of the sequence contamination

# Prerequisites
- a012 node (>512GB RAM, SSD, >48 Cores)
- w3const user (for only the 1st setup)
- This script is expected to be executed by members of w3const group.
- python3
  - The modules (biopython, dictdiffer, ete3, pandas, polars, pydrive2, xlsxwriter) are quired to run, but have already been prepared in python venv, ~/wok-kosuge/mypy/ that is called during the script. Therefore you do not need to install them by yourself.
- Google Workspace (Gdrive, Spreadsheet, and GAS)

# Installation
1. ssh login to a012 as w3const user.
2. git clone https://github.com/ddbj/fcsgx_mss.git
3. Prepare symbolic lins for fcsgxmss.sh in /data1/FCS. `ln -s ~/fcsgx_mss/fcsgxmss.sh /data1/FCS/fcsgxmss.sh`
4. Copy the secret keys to upload the file to Gdrive. **Make sure that the owner of the two json files must be w3const:w3const with the permission 640.**  
   `cp -av ~/work-kosuge/fcsgxmss_secrets/*.json ~/fcsgx_mss/`
5. The script depends on the taxonomy data prepared by ete tool. To update `~/work-kosuge/etetoolkit/ncbitaxonomy.sqlite`, `bash ~/fcsgx_mss/update_taxonomydb.sh` should be executeted by w3const user at 6:00 every day.

# How to use
~~~
bash /home/w3const/fcsgx_mss/run_fcs2gsheet.sh -d </home/w3const/submissions/production/NSUB######/YYYYmmdd-HHMMSS>
e.g. bash /home/w3const/fcsgx_mss/run_fcs2gsheet.sh -d /home/w3const/submissions/production/NSUB999999/20261231-012346
~~~
Then the result is saved in `/home/w3const/fcslog/gx/<NSUB number>`. When the contamination is detected, the hyperlink to the contamination report is filled to the cell for corresponding NSUB in MSS working sheet.




## When you would like to run only FCS-gx.
~~~
ssh a012
/data1/FCS/fcsgxmss.sh -q <NSUB######>|<path to a fasta file> -t <tax ID> [-o <directory name>]

You will find the FCS-GX result in ~/fcsgxmss as default.
~~~


### e.g. 1
~~~
/data1/FCS/fcsgxmss.sh -q ~/w3const/submissions/production/NSUB001887/20240702-151414/SAMD00797160_TA6350.fasta -t 2104
~~~

### e.g. 2
You can do FCS-GX against the latest submission files when NSUB number is designated at -q option
~~~
/data1/FCS/fcsgxmss.sh -q NSUB001972 -t 105296
~~~

### e.g. 3
Use of -o option can change the output directory to your favorite one. You should prepare the output directory in advance when you use -d option.
~~~
/data1/FCS/fcsgxmss.sh -q ~/w3const/submissions/production/NSUB001887/20240702-151414/SAMD00797160_TA6350.fasta -t 2104 -o ~/myresult
~~~
