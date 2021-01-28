# ////////////////////////////////////////////////////////////////////////////
# FILE: index.sh
# AUTHOR: David Ruvolo
# CREATED: 2020-11-18
# MODIFIED: 2020-01-11
# PURPOSE: script for interacting with GONL Server
# DEPENDENCIES: mcmd (molgenis commander); RScript
# COMMENTS: NA
# This script can be run at once, but it may be easier to use VSCode's
# integrated terminal. Make sure a keybinding exists for:
# `terminal run selected text in active terminal`. I recommend using
# "cmd + shift + enter"
# ////////////////////////////////////////////////////////////////////////////


# download compressed files to ~/Downloads and then move to ./vcfs
mv ~/Downloads/gonl.* vcfs/
mkdir vcfs/gzip/

# batch unpack gz files keep original
for v in vcfs/*; do echo "Unpacking: $v"; gunzip -k $v; done

# keep gz files, but move into gzip folder
mv vcfs/*.vcf.gz vcfs/gzip/

# //////////////////////////////////////

# ~ 1 ~
# Build EMX files

Rscript -e "source('R/emx_create_01_pkg.R')"
Rscript -e "source('R/emx_create_02_entities.R')"
Rscript -e "source('R/emx_create_03_attribs.R')"
Rscript -e "source('R/emx_create_04_static_content.R')"
Rscript -e "source('R/emx_create_05_request_pkg.R')"

# //////////////////////////////////////

# ~ 2 ~
# Push to Molgenis Server

# config `mcmd`
# pip3 install molgenis-commander               # install mcmd
# pip3 install --upgrade molgenis-commander     # upgrade mcmd
# mcmd --version              # test mcmd
# mcmd config add host        # initial time only
mcmd config set host
mcmd ping

# push EMX assets
mcmd import -p data/sys_md_Package.tsv
mcmd import -p data/gonl_attributes.tsv --as attributes --in gonl
mcmd import -p data/gonl_entities.tsv --as entities --in gonl

# push source data
# a shell script could be written, but it's probably just as easy to
# import the files 1-by-1 to make sure they are all imported correctly
cd vcfs/
mcmd import -p gonl.chr1.snps_indels.r5.vcf --in gonl --as gonl_chr1 # done
mcmd import -p gonl.chr2.snps_indels.r5.vcf --in gonl --as gonl_chr2 # done
mcmd import -p gonl.chr3.snps_indels.r5.vcf --in gonl --as gonl_chr3 # done
mcmd import -p gonl.chr4.snps_indels.r5.vcf --in gonl --as gonl_chr4 # done
mcmd import -p gonl.chr5.snps_indels.r5.vcf --in gonl --as gonl_chr5 # done
mcmd import -p gonl.chr6.snps_indels.r5.vcf --in gonl --as gonl_chr6 # done
mcmd import -p gonl.chr7.snps_indels.r5.vcf --in gonl --as gonl_chr7 # done
mcmd import -p gonl.chr8.snps_indels.r5.vcf --in gonl --as gonl_chr8 # done
mcmd import -p gonl.chr9.snps_indels.r5.vcf --in gonl --as gonl_chr9 # done
mcmd import -p gonl.chr10.snps_indels.r5.vcf --in gonl --as gonl_chr10 # done
mcmd import -p gonl.chr11.snps_indels.r5.vcf --in gonl --as gonl_chr11 # done
mcmd import -p gonl.chr12.snps_indels.r5.vcf --in gonl --as gonl_chr12 # done
mcmd import -p gonl.chr13.snps_indels.r5.vcf --in gonl --as gonl_chr13 # done
mcmd import -p gonl.chr14.snps_indels.r5.vcf --in gonl --as gonl_chr14 # done
mcmd import -p gonl.chr15.snps_indels.r5.vcf --in gonl --as gonl_chr15 # done
mcmd import -p gonl.chr16.snps_indels.r5.vcf --in gonl --as gonl_chr16 # done
mcmd import -p gonl.chr17.snps_indels.r5.vcf --in gonl --as gonl_chr17 # done
mcmd import -p gonl.chr18.snps_indels.r5.vcf --in gonl --as gonl_chr18 # done
mcmd import -p gonl.chr19.snps_indels.r5.vcf --in gonl --as gonl_chr19 # done
mcmd import -p gonl.chr20.snps_indels.r5.vcf --in gonl --as gonl_chr20 # done
mcmd import -p gonl.chr21.snps_indels.r5.vcf --in gonl --as gonl_chr21 # done
mcmd import -p gonl.chr22.snps_indels.r5.vcf --in gonl --as gonl_chr22 # done

# import questionnaire and give permissions
mcmd import -p data/emx_data_access_requests.xlsx --in requests
# mcmd enable rls requests_dar

mcmd give anonymous view data-row-edit
mcmd give anonymous edit requests_dar
# mcmd make --role ANONYMOUS requests_EDITOR

# push content
mcmd import -p data/sys_StaticContent.tsv

# cheeky way of uploading multiple images (make sure logo is always last)
mcmd add logo -p src/www/images/bgi.png
mcmd add logo -p src/www/images/bmri.png
mcmd add logo -p src/www/images/eumc.png
mcmd add logo -p src/www/images/lumc.jpg
mcmd add logo -p src/www/images/nbic.png
mcmd add logo -p src/www/images/umcg.png
mcmd add logo -p src/www/images/umcu.png
mcmd add logo -p src/www/images/vumc.png
mcmd add logo -p src/www/images/website.png
mcmd add logo -p src/www/images/GoNL_DataSources_Flowchart_04.png
mcmd add logo -p src/www/images/gonl.png

# upload apps, add to menu, and then continue
# menu order: Home, About, News, Publications, Download, Browse, Request
# request is a redirect

mcmd give anonymous view sys_App
mcmd give anonymous view app-about
mcmd give anonymous view app-news
mcmd give anonymous view app-publications
mcmd give anonymous view app-download
mcmd give anonymous view app-browse
mcmd give anonymous view app-request

mcmd give anonymous view sys_FileMeta

# set permissions
mcmd make --role anonymous gonl_VIEWER
# mcmd give anonymous view sys_md
mcmd give anonymous view gonl
# mcmd give anonymous view navigator
# mcmd give anonymous view dataexplorer
# mcmd give anonymous view directory

# upload publications dataset
mcmd import -p data/pubdata/sys_md_Package.csv
mcmd import -p data/pubdata/entities.csv
mcmd import -p data/pubdata/records_attributes.csv --as attributes --in publications
mcmd import -p data/pubdata/queries_attributes.csv --as attributes --in publications
mcmd import -p data/pubdata/records.csv --as publications_records --in publications
mcmd import -p data/pubdata/queries.csv --as publications_queries --in publications
