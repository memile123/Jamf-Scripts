#!/bin/bash
#Created 2/14/17; NRJA

CurUser=$(ls -l /dev/console | cut -d " " -f 4)
Photo=$(dscl /Search -read Users/${CurUser} dsAttrTypeNative:thumbnailPhoto 2>/dev/null | tail -1)
mkdir ./PicFolder 2>/dev/null
chmod -f -R 777 ./PicFolder

if [[ ! ${Photo} == "" ]]; then
    echo "Saving ${CurUser}.jpg..."
    echo ${Photo} | xxd -r -p > ./PicFolder/${CurUser}.jpg
    dscl . create /Users/${CurUser} Picture ${Photo}
else
    echo "ERROR: ${CurUser} does not have a picture or machine is not bound."
    exit 1
fi

echo "0x0A 0x5C 0x3A 0x2C dsRecTypeStandard:Users 2 dsAttrTypeStandard:RecordName  externalbinary:dsAttrTypeStandard:JPEGPhoto" > PicText.txt
echo "${CurUser}:./PicFolder/${CurUser}.jpg" >> PicText.txt

dscl . -delete /Users/$CurUser JPEGPhoto
dsimport PicText.txt /Local/Default M

if [[ $? == 0 ]]; then
    echo "AD picture successfully reimported."
else
    echo "Failed to import AD picture."
    #Exit and leave files intact to troubleshoot what went wrong
    exit 1
fi

rm PicText.txt
rm -f -R ./PicFolder 2>/dev/null

exit 0
