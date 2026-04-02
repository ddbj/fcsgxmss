# fcsgxmss
FCSgx-related scripts to assist MSS works for quick screening of the sequence contamination

## fcsgxmss.sh
Carry out FCS-GX against MSS submission.

### How to use
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
