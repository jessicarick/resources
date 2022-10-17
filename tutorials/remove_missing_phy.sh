#!/bin/sh

################################################################
## Small shell script written by Jessi Rick (http://github.com/jessicarick)
## to remove individuals with large amounts of missing data from
## alignments prior to phylogenetic analysis (e.g., in RAxML, which
## will throw an error if any individuals have all missing data)
##
## Script written October 2022
################################################################


######### script usage ##########################################
##
## bash remove_missing_phy.sh infile.phy 90
##
## where infile.phy is the phylip file to analyze
## and 90 is the proportion of missing data *allowed*
## (i.e., individuals are allowed to have 90% or less 
## of their sites missing). To allow everything except
## individuals with 100% missing data, this number
## should be 100. This will produce a file with the extension
## '.reduced.phy' whether individuals are removed or not.
##
################################################################

phy=$1
prop=$2
base=`echo $phy | sed 's/\.phy//g'`

nind=$(head -n 1 $phy | cut -f 1 -d' ')
nsites=$(head -n 1 $phy | cut -f 2 -d' ')
nallowed=$(( nsites * prop / 100 ))

echo "working with phylip with $nind individuals and $nsites sites"

rm -f tmp.rmv

# count number of N per line
i=2
n=0
tail -n +2 $phy | cut -f 2 | awk -F'N' '{print NF-1}' | while read nN; do
	if [[ nN -ge nallowed ]]; then
		if [[ n -eq 0 ]]; then
			echo "${i}d" > tmp.rmv
		else
			echo ";${i}d" >> tmp.rmv
		fi

		i=$((i+1))
		n=$((n+1))
	else
		i=$((i+1))
	fi
done 

# count individuals to be deleted
ndelete=`cat tmp.rmv | wc -l`

# if one or more to delete, delete those individuals and write a new file
if [[ ndelete -ge 1 ]]; then
	delete=`cat tmp.rmv | tr -d '\n'`
        ndelete=`cat tmp.rmv | wc -l`
        new_nind=$((nind - ndelete))

        echo "removing $ndelete individuals that are completely missing"
        echo "$new_nind $nsites" > ${base}.reduced.phy
        sed -e $delete $phy | tail -n +2 >> ${base}.reduced.phy
else
	echo "no individuals to remove"
	cp $phy ${base}.reduced.phy
fi
