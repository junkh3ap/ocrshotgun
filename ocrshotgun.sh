#!/bin/bash
#
# By Dennis Kuntz
# @denniskuntz - Twitter
# junkh3ap - IRC (freenode)
#
# This software is offered as is
# with no guarantees of any kind.
#
# Please use with caution and at your own risk
#
# Please feel free to distribute and/or modify
# this code at will.
# 
# If you modify it, I would love to know about
# what you did for my own education.
#
# If you distribute it, It would be cool
# for you to give me credit, but I don't need it
# so you decide.
#
# Finally, I'd love to know what you use this for
# so that I can find out if it was useful (or not)
# and how.
#
# Another note: The code for cleanpic was used from
# the Blue Hat SEO site. The only modification I made
# to it was to change hard-coded filenames to allowing
# them to be input as parameters
# Original code is here:
#
# http://www.bluehatseo.com/user-contributed-captcha-breaking-w-phpbb2-example/


# Get the current time to time the script
time1=$(date +%s.%N)

# right now the only parameter is a numerical representation
# of the confidence level from gocr. The default is 95%
# confidence, but I've had better experience with 80%
# FYI range is 1-100
if [ $# -eq 1 ]
then
	gocrconfidence=$1
else
	gocrconfidence=80
fi

#
# REGEXES
#
# Add or remove regexes in the two sections below
#
# Read each section to understand where to put
# whatever regexes you might have
#-------------------------------------------------
# numerical regexes
# Format is: "name:regex" - file-naming convention will use
# the part before the first colon in the filename for
# easier identification
# NOTE: right now these are used for numerical, but you
# can put anything in here that doesn't use filename-friendly
# characters in the regex.
numregexes=(
	"ssn1:[0-9]\{3\}.*[0-9]\{2\}.*[0-9]\{3\}"			# SSN #1
	"cc1:[0-9]\{4\}.*[0-9]\{4\}.*[0-9]\{4\}.*[0-9]\{4\}"		# CC #1 
	"cc2:[0-9]\{15,16\}"						# CC #2
	"phone1:(*[0-9]\{3\})*.*[0-9]\{3\}=*[0-9]\{4\}"			# Phone number
)

# name-based regexes. These names are used in the
# filenames for easier identification
alpharegexes=(
	"ssn" 
	"social security" 
	"credit card"
	"government" 
	"senator"
	"congress"
	"judge"
	"lawsuit"
	"sue"
	"password"
	"pwd"
	"username"
	"tax id"
	"taxes"
	"confidential"
	"securities exchange commission"
	"devon"
	"patent"
	"claimant"
	"respondent"
	"payroll"
	"police"
	"insurance"
	"power plant"
)

# start with making the directories
# where everything will eventually go
echo "And here we go..."
echo -e "    making directories"
mkdir ppm
mkdir tif
mkdir txt
mkdir greps

# First convert any images to ppm format before
# converting any PDF's to ppm's

for b in $(ls *.gif); do
	c=${b/\.gif/\.ppm}
	convert $b $c
done

for b in $(ls *.jpg); do
	c=${b/\.jpg/\.ppm}
	convert $b $c
done

for b in $(ls *.jpeg); do
        c=${b/\.jpeg/\.ppm}
        convert $b $c
done

for b in $(ls *.png); do
        c=${b/\.png/\.ppm}
        convert $b $c
done

# use pdftoppm to convert individual pdf pages
# to individual ppm files
echo -e "    creating PPM files for gocr and ocropus"
for i in $(ls *.pdf); do
	j=${i/\.pdf/}
	pdftoppm $i $j
done

echo -e "    for each image doing the following:"
echo -e "         - clean .ppm file - now we have two versions of the image"
echo -e "         - run gocr on both versions of the image - original and cleaned"
echo -e "         - create .tif files of each image for tesseract"
echo -e "         - run tesseract on both versions of the .tif files"
echo -e "         - run ocropus on both versions of the .ppm files"
echo -e "         - run ocrad on both versions of the .ppm files"
echo -e "    now you'll see some output from tesseract and ocropus - hang in\n"
for k in $(ls *.ppm); do
	# run cleanpic to boost fidelity of image
	# keep in mind it doesn't always make for the best
	# results - it's just another option

	# here we're creating a filename with "cleaned"
	# appended so we know it's not from the
	# original image
	#
	# $k = original ppm image
	# $cleanfile = the "cleanpic" version of the image
	cleanfile=${k/\.ppm/-cleaned\.ppm}
	./cleanpic $k $cleanfile

	# tesseract is the only OCR using .tif file
	# (at least that I'm using)
	# create filenames for those .tif's
	tesspicfile=${k/\.ppm/-tess\.tif}
	tesscleanedpicfile=${cleanfile/\.ppm/-tess\.tif}
	
	# create filenames for all of the OCR-centric
	# text files that will result from running
	# each OCR on the images
	# 
	# NOTE: Here is where you would add
	# additional filenames for
	# additional OCR-engine-created text files
	gocrfile=${k/\.ppm/-gocr\.txt}
	gocrcleanedfile=${cleanfile/\.ppm/-gocr\.txt}
	tessfile=${tesspicfile/\.tif/}
	tesscleanedfile=${tesscleanedpicfile/\.tif/}
	ocropusfile=${k/\.ppm/-ocropus\.txt}
	ocropuscleanedfile=${cleanfile/\.ppm/-ocropus\.txt}
	ocradfile=${k/\.ppm/-ocrad\.txt}
	ocradcleanedfile=${cleanfile/\.ppm/-ocrad\.txt}

	# This is where we run the OCR engines on
	# all of the files
	#
	# So...this is where you would run any other 
	# OCR engines you have installed
	#
	# Also this is where you can comment out
	# any engines not installed

	#
	# GOCR
	#
	# run gocr on both versions of the image
	# using the confidence parameter
	gocr -a $gocrconfidence $k > $gocrfile
	gocr -a $gocrconfidence $cleanfile > $gocrcleanedfile
	
	#
	# TESSERACT
	#
	# create .tif versions of each file for tesseract
	convert $k $tesspicfile
	convert $cleanfile $tesscleanedpicfile
	
	# run tesseract on each version of the file
	tesseract $tesspicfile $tessfile
	tesseract $tesscleanedpicfile $tesscleanedfile
	
	#
	# OCROPUS
	#
	# run ocropus on each version of the image
	ocropus page $k > $ocropusfile
	ocropus page $cleanfile > $ocropuscleanedfile
	
	#
	# OCRAD
	#
	# run ocrad on each version of the image
	ocrad -o $ocradfile $k
	ocrad -o $ocradcleanedfile $cleanfile
done

# Run regexes on ALL of the resulting text files and
# name the files accordingly
#
# The final naming convention is based on:
#     OCR engine used
#     Whether or not it was the original image or the "cleanpic" version
#     The regex being run
echo -e "\n    now running numeric and alpha regexes on the text files that came from OCRing"
for l in $(ls *.txt); do
	for z in ${numregexes[@]}; do
		# This relates to the numregex strings
		# The key is before the first colon
		# the regex is after the first colon
		#
		# The key is used in the filename whereas
		# the regex is, well, the regex :)
		key=${z%:*}
		rgx=${z#*:}
		# Do it once removing spaces because sometimes
		# the OCR apps will insert them when we don't want them
		# ...Make sure to name the file accordingly ("nospaces")
		cat $l | tr -d " " | grep -n $rgx >> grep-nospaces-$key-$l
		# Now do it again just so we don't miss anything
		cat $l | grep -n $rgx -n >> grep-$key-$l
	done

	# Now run the alpha based regexes
	for y in ${alpharegexes[@]}; do
		grep -n -i $y $l >> grep-$y-$l
	done
done

# Get rid of 0-byte files and move the rest
find . -type f -size 0 | xargs rm
mv grep-* ./greps/
mv *.txt ./txt/
mv *.ppm ./ppm/
mv *.tif ./tif/

time2=$(date +%s.%N)
printf "\n...done! And it only took %.2F seconds! Now go see what was found!\n" $(echo "$time2 - $time1"|bc )
