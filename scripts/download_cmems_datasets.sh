#!/bin/bash

# Default options
MOTU_URL=''

PASSWD=''
USERID=''

OUTDIR='./'

START_YEAR=''
END_YEAR=''


# Read opts passed by user
optstring='p:o:u:m:s:e:'
while getopts ${optstring} opt; do
	case $opt in
		p)
			PASSWD=$OPTARG;;
		o)
			OUTDIR=$OPTARG;;
		u)
			USERID=$OPTARG;;
		m)
			MOTU_URL=$OPTARG;;
		s)
			START_YEAR=$OPTARG;;
		e)
			END_YEAR=$OPTARG;;
		?)
			echo "Invalid option: -${OPTARG}."
			echo "";;
	esac
done


# Processing opts to avoid error
if [ "$PASSWD" == '' ]; then
	while true; do
		read -s -p "Password is needed for $USERID: " PASSWD
		if [[ "$PASSWD" != '' ]]; then
			break ;
		fi
	done
fi

if [ "$START_YEAR" == '' ]; then
	while true; do
      echo ""
		read -p "Choose the first year to download: " START_YEAR
		if [[ "$START_YEAR" != '' ]]; then
			break ;
		fi
	done
fi

if [ "$END_YEAR" == '' ]; then
	while true; do
		read -p "Choose the last year to download: " END_YEAR
		if [[ "$END_YEAR" != '' ]]; then
			break ;
		fi
	done
fi

IFS=' ' read -ra alls <<< "$MOTU_URL"

product_id="product"
nelmt=${#alls[@]}
imin=0
imax=0

for i in $(seq 0 $nelmt); do
   if [ "${alls[$i]}" == '--date-min' ]; then
      alls[$((i+1))]="'$START_YEAR-01-01"
      imin=$i
   fi
   if [ "${alls[$i]}" == '--date-max' ]; then
      alls[$((i+1))]="'$END_YEAR-12-31"
      imax=$i
   fi
   if [ "${alls[$i]}" == '--product-id' ]; then
      product_id="${alls[$((i+1))]}"
   fi
done


# Execute command and download the datat
for y in $(seq $START_YEAR $END_YEAR); do
   filename="$product_id""_$y.nc"
   
   IFS=' ' read -ra all_options <<< "$MOTU_URL"
   if [[ $imin -eq 0 ]]; then
      all_options[$((nelmt+1))]="--date-min '$START_YEAR-01-01 00:00:00'"
   else
      all_options[$((imin+1))]="'$START_YEAR-01-01"
   fi
   if [[ $imax -eq 0 ]]; then
      all_options[$((nelmt+2))]="--date-max '$END_YEAR-12-31 23:59:59'"
   else
      all_options[$((imax+1))]="'$END_YEAR-12-31"
   fi
   
   motuclient --motu "${all_options[@]}" --out-dir $OUTDIR --out-name $filename --user $USERID --pwd $PASSWD

done


