#!/bin/bash

# This script will recreate the LINCS database

DIR=/groups/pharmacoresponse/
DATA_DIRECTORY=${DIR}/data/current

if [[ $# -lt 1 ]]
then
  echo "Usage: $0 { local <local data dir> <properties file> [<db name> [<db user>]] | dev | stage | prod }"
  exit $WRONG_ARGS
fi

SERVER=$1

if [[ "$SERVER" == "PROD" ]] || [[ "$SERVER" == "prod" ]] 
then
  SERVER=""
  DATA_DIRECTORY=${DIR}/data/prod
  DB=${SERVER}pharmacoresponse
  DB_USER=${SERVER}pharmacoresponseweb
  export SCREENSAVER_PROPERTIES_FILE=/groups/pharmacoresponse/screensaver/cfg/pharmacoresponse.properties.util.prod
elif [[ "$SERVER" == "STAGE" ]] || [[ "$SERVER" == "stage" ]] 
then
  SERVER="stage"
  DATA_DIRECTORY=${DIR}/data/stage
  DB=${SERVER}pharmacoresponse
  DB_USER=${SERVER}pharmacoresponseweb
  export SCREENSAVER_PROPERTIES_FILE=/groups/pharmacoresponse/screensaver/cfg/pharmacoresponse.properties.util.stage
elif [[ "$SERVER" == "DEV" ]] || [[ "$SERVER" == "dev" ]] 
then
  SERVER="dev"
  DATA_DIRECTORY=${DIR}/data/dev
  DB=${SERVER}pharmacoresponse
  DB_USER=${SERVER}pharmacoresponseweb
  PGHOST=dev.pgsql.orchestra
  export SCREENSAVER_PROPERTIES_FILE=/groups/pharmacoresponse/screensaver/cfg/pharmacoresponse.properties.util.dev
elif [[ "$SERVER" == "LOCAL" ]] || [[ "$SERVER" == "local" ]] 
then
  DIR=.
  DATA_DIRECTORY=${2:-/home/sde4/sean/docs/work/LINCS/data/current}
  export SCREENSAVER_PROPERTIES_FILE=${3:-/home/sde4/workspace/current/screensaver.properties.LINCS}
  DB=${4:-screensavergo}
  DB_USER=${5:-screensavergo}
else
  echo "Unknown option: \"$SERVER\""
  exit 1
fi

# TODO: parameterize
ECOMMONS_ADMIN=djw11
#ECOMMONS_ADMIN=sde_admin

check_errs()
{
  # Function. Parameter 1 is the return code
  # Para. 2 is text to display on failure.
  if [ "${1}" -ne "0" ]; then
    echo "ERROR: ${1} : ${2}"
    exit ${1}
  fi
}

#set -x 

echo DIR=$DIR
echo DATA_DIRECTORY=$DATA_DIRECTORY 
echo DB=$DB
echo DB_USER=$DB_USER
echo SCREENSAVER_PROPERTIES_FILE=$SCREENSAVER_PROPERTIES_FILE

if [[ `psql -U $DB_USER $DB -c '\dt'` != 'No relations found.' ]]; then
  echo dropping existing database
  psql -q -U $DB_USER $DB -f scripts/drop_all.sql -v ON_ERROR_STOP=1
  check_errs $? "drop_all.sh fails"
fi

psql -q -U $DB_USER $DB -f scripts/create_lincs_schema.sql -v ON_ERROR_STOP=1
check_errs $? "create schema fails"

psql -q -U $DB_USER $DB -f scripts/misc.sql -v ON_ERROR_STOP=1
check_errs $? "misc.sql fails"

psql -q -U $DB_USER $DB -f $DATA_DIRECTORY/lincs-users.sql -v ON_ERROR_STOP=1
check_errs $? "lincs-users.sql fails"

## Create the library
LIBRARY_1_SHORTNAME="R-LINCS-1"
LIBRARY_2_SHORTNAME="R-Anti-mitotics1"
LIBRARY_3_SHORTNAME="P-LINCS-1"
LIBRARY_4_SHORTNAME="P-Anti-mitotics5"
LIBRARY_5_SHORTNAME="P-Anti-mitotics6"
LIBRARY_6_SHORTNAME="P-Mario-1"
LIBRARY_7_SHORTNAME="R-CMT-1"

set -x 
./run.sh edu.harvard.med.screensaver.io.libraries.LibraryCreator \
-n "HMS LINCS-1 BATCH 001" -s $LIBRARY_1_SHORTNAME -lt "commercial" \
-lp "Qingsong Liu" -st SMALL_MOLECULE -sp 1 -ep 1 -AE $ECOMMONS_ADMIN 
check_errs $? "create library fails"

./run.sh edu.harvard.med.screensaver.io.libraries.LibraryContentsLoader \
--release-library-contents-version \
-l $LIBRARY_1_SHORTNAME \
-f $DATA_DIRECTORY/HMS_LINCS-1.sdf -AE $ECOMMONS_ADMIN
check_errs $? "library contents loading fails"

./run.sh edu.harvard.med.screensaver.io.libraries.LibraryCreator \
-n "LINCS Anti-mitotics-1" -s $LIBRARY_2_SHORTNAME -lt "commercial" \
-lp "Nate Moerke" -st SMALL_MOLECULE -sp 2 -ep 2 -AE $ECOMMONS_ADMIN 
check_errs $? "create library fails"

./run.sh edu.harvard.med.screensaver.io.libraries.LibraryContentsLoader \
--release-library-contents-version \
-l $LIBRARY_2_SHORTNAME \
-f $DATA_DIRECTORY/HMS_LINCS-2.sdf -AE $ECOMMONS_ADMIN
check_errs $? "library contents loading fails"

./run.sh edu.harvard.med.screensaver.io.libraries.LibraryCreator \
-n "HMS LINCS-1 Batch 001 Stock Plates" -s $LIBRARY_3_SHORTNAME -ps WELLS_96 -lt "commercial" \
-lp "Qingsong Liu" -st SMALL_MOLECULE -sp 3 -ep 4 -AE $ECOMMONS_ADMIN -ds 2011-05-20
check_errs $? "create library fails"

./run.sh edu.harvard.med.screensaver.io.libraries.LibraryContentsLoader \
--release-library-contents-version \
-l $LIBRARY_3_SHORTNAME \
-f $DATA_DIRECTORY/HMS_LINCS-3.sdf -AE $ECOMMONS_ADMIN
check_errs $? "library contents loading fails"

./run.sh edu.harvard.med.screensaver.io.libraries.LibraryCreator \
-n "LINCS Anti-mitotics Plate 5" -s $LIBRARY_4_SHORTNAME -lt "commercial" \
-lp "Nate Moerke" -st SMALL_MOLECULE -sp 5 -ep 5 -AE $ECOMMONS_ADMIN -ds 2010-06-01
check_errs $? "create library fails"

./run.sh edu.harvard.med.screensaver.io.libraries.LibraryContentsLoader \
--release-library-contents-version \
-l $LIBRARY_4_SHORTNAME \
-f $DATA_DIRECTORY/HMS_LINCS-4.sdf -AE $ECOMMONS_ADMIN
check_errs $? "library contents loading fails"

./run.sh edu.harvard.med.screensaver.io.libraries.LibraryCreator \
-n "LINCS Anti-mitotics Plate 6" -s $LIBRARY_5_SHORTNAME -lt "commercial" \
-lp "Nate Moerke" -st SMALL_MOLECULE -sp 6 -ep 6 -AE $ECOMMONS_ADMIN -ds 2010-11-01
check_errs $? "create library fails"

./run.sh edu.harvard.med.screensaver.io.libraries.LibraryContentsLoader \
--release-library-contents-version \
-l $LIBRARY_5_SHORTNAME \
-f $DATA_DIRECTORY/HMS_LINCS-5.sdf -AE $ECOMMONS_ADMIN
check_errs $? "library contents loading fails"

./run.sh edu.harvard.med.screensaver.io.libraries.LibraryCreator \
-n "P-Mario-1 (ICCB-L 3265)" -s $LIBRARY_6_SHORTNAME -lt "commercial" \
-lp "Mario Niepel/Qingsong Liu" -st SMALL_MOLECULE -sp 7 -ep 7 -AE $ECOMMONS_ADMIN -ds 2011-05-27
check_errs $? "create library fails"

./run.sh edu.harvard.med.screensaver.io.libraries.LibraryContentsLoader \
--release-library-contents-version \
-l $LIBRARY_6_SHORTNAME \
-f $DATA_DIRECTORY/HMS_LINCS-6.sdf -AE $ECOMMONS_ADMIN
check_errs $? "library contents loading fails"

./run.sh edu.harvard.med.screensaver.io.libraries.LibraryCreator \
-n "R-CMT-1" -s $LIBRARY_7_SHORTNAME -lt "commercial" \
-lp "Cyril Benes" -st SMALL_MOLECULE -sp 8 -ep 8 -AE $ECOMMONS_ADMIN 
check_errs $? "create library fails"

./run.sh edu.harvard.med.screensaver.io.libraries.LibraryContentsLoader \
--release-library-contents-version \
-l $LIBRARY_7_SHORTNAME \
-f $DATA_DIRECTORY/HMS_LINCS-7.sdf -AE $ECOMMONS_ADMIN
check_errs $? "library contents loading fails"

## Restrict reagents

psql -q -U $DB_USER $DB -f $DATA_DIRECTORY/restrict_reagents.sql -v ON_ERROR_STOP=1
check_errs $? "lincs-users.sql fails"

## Create the screens

LEAD_SCREENER_FIRST="Nathan"
LEAD_SCREENER_LAST="Moerke"
LEAD_SCREENER_EMAIL="nathanmoerke@gmail.com"
LAB_HEAD_FIRST="Tim"
LAB_HEAD_LAST="Mitchison"
LAB_HEAD_EMAIL="timothy_mitchison@hms.harvard.edu"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Moerke 2 Color Apoptosis: IA-LM cells.'  \
-i 10001 \
--summary "Moerke 2 Color Apoptosis: IA-LM cells. Dose response of anti-mitotic compounds in human cancer cell lines at 24, 48, and 72 hours to determine their effects on apoptosis.  In this assay, the cell-permeable DNA dye Hoechst 33342 is used to stain the nuclei of all cells.  The fluorescent caspase 3 reporter NucView488 stains the nuclei of cells undergoing apoptosis (in which caspase 3 is active)." \
-p 'Day 1: Seed cells in 384-well assay plates, at approximately 2000 cells/well (the exact density varies by cell line), with 3 plates per cell line (one each for a 24 hr, 48 hr and 72 hr time point).  Add 30 uL cell suspension per well.
Day 2: Add compounds to plates by pin transfer.
Day 3: Prepare cells for 24 hr timepoint.
Prepare the 4X apoptosis reagent mixture fresh in PBS
4X apoptosis reagent mixture composition:
(1) DEVD-NucView488 caspase substrate: 1 uM
(2) Hoechst 33342:  2 ug/mL
For 4 384-well plates, 25 mL of this mixture will be sufficient and allow plenty of dead volume.
For 25 mL of mixture add 25 uL of DEVD-NucView488 substrate (from refrigerator) and 50 uL of Hoechst 33342 (from freezer).
Use WellMate (hood or bench is fine) to add the mixture, using the designated manifold (labeled “NucView”).  Add 10 uL per well, skipping the 1st 2 and last 2 columns.  Spin plates briefly at 1000 rpm in plate centrifuge and put in incubator for 90 minutes.
Prepare 2X fixative solution: 2 % formaldehyde in PBS.  Dilute a 36-36.5% formaldehyde stock bottle 1:20 in PBS.  100 mL fixative total is sufficient for 4 plates; add 5 mL formaldehyde stock to 95 mL PBS.
After 90 minutes, use benchtop (not hood) WellMate to add fixative to plates.  Use the manifold labeled “Fixative”  Add 40 uL per well (again skipping first 2 and last 2 columns).  Spin plates briefly as before.  Let fix 20-30 minutes at RT, then seal with metal foil, and image right away or store in the cold room until you are ready to image.
Day 4: Repeat for 48 hr time point
Day 5: Repeat for 72 hr time point

Plates are imaged on the ImageXpress Micro screening microscope (Molecular Devices).  4 images are collected per well of the plate at 10X magnification, using the DAPI and FITC filter sets of this instrument.
Images are analyzed using MetaXpress software.  The multiwavelength cell scoring module of the software is used detect all cells using the DAPI channel, score cells as apoptotic cells (NucView 488 positive) using the FITC channel.  The analysis produces for each well the total cell count and the % of cells in the well that are apoptotic.

Reagent stocks:
Hoechst 33342 (Invitrogen ) – 1 mg/mL stock in H2O, store at -20 degrees C
DEVD-NucView488 (Biotium) –  1 mM in DMSO, store at 4 degrees C protected from light

References:

Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.

http://www.biotium.com/product/applications/Cell_Biology/price_and_info.asp?item=30029&layer1=A;&layer2=A02;&layer3=A0203;'
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/moerke_2color_IA-LM.xls \
-s 10001 -i 
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Moerke 2 Color Apoptosis: IS-MELI cells.'  \
-i 10002 \
--summary "Moerke 2 Color Apoptosis: IS-MELI cells. Dose response of anti-mitotic compounds in human cancer cell lines at 24, 48, and 72 hours to determine their effects on apoptosis.  In this assay, the cell-permeable DNA dye Hoechst 33342 is used to stain the nuclei of all cells.  The fluorescent caspase 3 reporter NucView488 stains the nuclei of cells undergoing apoptosis (in which caspase 3 is active)." \
-p 'Day 1: Seed cells in 384-well assay plates, at approximately 2000 cells/well (the exact density varies by cell line), with 3 plates per cell line (one each for a 24 hr, 48 hr and 72 hr time point).  Add 30 uL cell suspension per well.
Day 2: Add compounds to plates by pin transfer.
Day 3: Prepare cells for 24 hr timepoint.
Prepare the 4X apoptosis reagent mixture fresh in PBS
4X apoptosis reagent mixture composition:
(1) DEVD-NucView488 caspase substrate: 1 uM
(2) Hoechst 33342:  2 ug/mL
For 4 384-well plates, 25 mL of this mixture will be sufficient and allow plenty of dead volume.
For 25 mL of mixture add 25 uL of DEVD-NucView488 substrate (from refrigerator) and 50 uL of Hoechst 33342 (from freezer).
Use WellMate (hood or bench is fine) to add the mixture, using the designated manifold (labeled “NucView”).  Add 10 uL per well, skipping the 1st 2 and last 2 columns.  Spin plates briefly at 1000 rpm in plate centrifuge and put in incubator for 90 minutes.
Prepare 2X fixative solution: 2 % formaldehyde in PBS.  Dilute a 36-36.5% formaldehyde stock bottle 1:20 in PBS.  100 mL fixative total is sufficient for 4 plates; add 5 mL formaldehyde stock to 95 mL PBS.
After 90 minutes, use benchtop (not hood) WellMate to add fixative to plates.  Use the manifold labeled “Fixative”  Add 40 uL per well (again skipping first 2 and last 2 columns).  Spin plates briefly as before.  Let fix 20-30 minutes at RT, then seal with metal foil, and image right away or store in the cold room until you are ready to image.
Day 4: Repeat for 48 hr time point
Day 5: Repeat for 72 hr time point

Plates are imaged on the ImageXpress Micro screening microscope (Molecular Devices).  4 images are collected per well of the plate at 10X magnification, using the DAPI and FITC filter sets of this instrument.
Images are analyzed using MetaXpress software.  The multiwavelength cell scoring module of the software is used detect all cells using the DAPI channel, score cells as apoptotic cells (NucView 488 positive) using the FITC channel.  The analysis produces for each well the total cell count and the % of cells in the well that are apoptotic.

Reagent stocks:
Hoechst 33342 (Invitrogen ) – 1 mg/mL stock in H2O, store at -20 degrees C
DEVD-NucView488 (Biotium) –  1 mM in DMSO, store at 4 degrees C protected from light

References:

Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.

http://www.biotium.com/product/applications/Cell_Biology/price_and_info.asp?item=30029&layer1=A;&layer2=A02;&layer3=A0203;' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/moerke_2color_IS-MELI.xls \
-s 10002 -i 
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Moerke 2 Color Apoptosis: NCI-1648 cells.'  \
-i 10003 \
--summary "Moerke 2 Color Apoptosis: NCI-1648 cells. Dose response of anti-mitotic compounds in human cancer cell lines at 24, 48, and 72 hours to determine their effects on apoptosis.  In this assay, the cell-permeable DNA dye Hoechst 33342 is used to stain the nuclei of all cells.  The fluorescent caspase 3 reporter NucView488 stains the nuclei of cells undergoing apoptosis (in which caspase 3 is active)." \
-p 'Day 1: Seed cells in 384-well assay plates, at approximately 2000 cells/well (the exact density varies by cell line), with 3 plates per cell line (one each for a 24 hr, 48 hr and 72 hr time point).  Add 30 uL cell suspension per well.
Day 2: Add compounds to plates by pin transfer.
Day 3: Prepare cells for 24 hr timepoint.
Prepare the 4X apoptosis reagent mixture fresh in PBS
4X apoptosis reagent mixture composition:
(1) DEVD-NucView488 caspase substrate: 1 uM
(2) Hoechst 33342:  2 ug/mL
For 4 384-well plates, 25 mL of this mixture will be sufficient and allow plenty of dead volume.
For 25 mL of mixture add 25 uL of DEVD-NucView488 substrate (from refrigerator) and 50 uL of Hoechst 33342 (from freezer).
Use WellMate (hood or bench is fine) to add the mixture, using the designated manifold (labeled “NucView”).  Add 10 uL per well, skipping the 1st 2 and last 2 columns.  Spin plates briefly at 1000 rpm in plate centrifuge and put in incubator for 90 minutes.
Prepare 2X fixative solution: 2 % formaldehyde in PBS.  Dilute a 36-36.5% formaldehyde stock bottle 1:20 in PBS.  100 mL fixative total is sufficient for 4 plates; add 5 mL formaldehyde stock to 95 mL PBS.
After 90 minutes, use benchtop (not hood) WellMate to add fixative to plates.  Use the manifold labeled “Fixative”  Add 40 uL per well (again skipping first 2 and last 2 columns).  Spin plates briefly as before.  Let fix 20-30 minutes at RT, then seal with metal foil, and image right away or store in the cold room until you are ready to image.
Day 4: Repeat for 48 hr time point
Day 5: Repeat for 72 hr time point

Plates are imaged on the ImageXpress Micro screening microscope (Molecular Devices).  4 images are collected per well of the plate at 10X magnification, using the DAPI and FITC filter sets of this instrument.
Images are analyzed using MetaXpress software.  The multiwavelength cell scoring module of the software is used detect all cells using the DAPI channel, score cells as apoptotic cells (NucView 488 positive) using the FITC channel.  The analysis produces for each well the total cell count and the % of cells in the well that are apoptotic.

Reagent stocks:
Hoechst 33342 (Invitrogen ) – 1 mg/mL stock in H2O, store at -20 degrees C
DEVD-NucView488 (Biotium) –  1 mM in DMSO, store at 4 degrees C protected from light

References:

Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.

http://www.biotium.com/product/applications/Cell_Biology/price_and_info.asp?item=30029&layer1=A;&layer2=A02;&layer3=A0203;' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/moerke_2color_NCI-1648.xls \
-s 10003 -i 
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Moerke 2 Color Apoptosis: PC-9 cells.'  \
-i 10004 \
--summary "Moerke 2 Color Apoptosis: PC-9 cells. Dose response of anti-mitotic compounds in human cancer cell lines at 24, 48, and 72 hours to determine their effects on apoptosis.  In this assay, the cell-permeable DNA dye Hoechst 33342 is used to stain the nuclei of all cells.  The fluorescent caspase 3 reporter NucView488 stains the nuclei of cells undergoing apoptosis (in which caspase 3 is active)." \
-p 'Day 1: Seed cells in 384-well assay plates, at approximately 2000 cells/well (the exact density varies by cell line), with 3 plates per cell line (one each for a 24 hr, 48 hr and 72 hr time point).  Add 30 uL cell suspension per well.
Day 2: Add compounds to plates by pin transfer.
Day 3: Prepare cells for 24 hr timepoint.
Prepare the 4X apoptosis reagent mixture fresh in PBS
4X apoptosis reagent mixture composition:
(1) DEVD-NucView488 caspase substrate: 1 uM
(2) Hoechst 33342:  2 ug/mL
For 4 384-well plates, 25 mL of this mixture will be sufficient and allow plenty of dead volume.
For 25 mL of mixture add 25 uL of DEVD-NucView488 substrate (from refrigerator) and 50 uL of Hoechst 33342 (from freezer).
Use WellMate (hood or bench is fine) to add the mixture, using the designated manifold (labeled “NucView”).  Add 10 uL per well, skipping the 1st 2 and last 2 columns.  Spin plates briefly at 1000 rpm in plate centrifuge and put in incubator for 90 minutes.
Prepare 2X fixative solution: 2 % formaldehyde in PBS.  Dilute a 36-36.5% formaldehyde stock bottle 1:20 in PBS.  100 mL fixative total is sufficient for 4 plates; add 5 mL formaldehyde stock to 95 mL PBS.
After 90 minutes, use benchtop (not hood) WellMate to add fixative to plates.  Use the manifold labeled “Fixative”  Add 40 uL per well (again skipping first 2 and last 2 columns).  Spin plates briefly as before.  Let fix 20-30 minutes at RT, then seal with metal foil, and image right away or store in the cold room until you are ready to image.
Day 4: Repeat for 48 hr time point
Day 5: Repeat for 72 hr time point

Plates are imaged on the ImageXpress Micro screening microscope (Molecular Devices).  4 images are collected per well of the plate at 10X magnification, using the DAPI and FITC filter sets of this instrument.
Images are analyzed using MetaXpress software.  The multiwavelength cell scoring module of the software is used detect all cells using the DAPI channel, score cells as apoptotic cells (NucView 488 positive) using the FITC channel.  The analysis produces for each well the total cell count and the % of cells in the well that are apoptotic.

Reagent stocks:
Hoechst 33342 (Invitrogen ) – 1 mg/mL stock in H2O, store at -20 degrees C
DEVD-NucView488 (Biotium) –  1 mM in DMSO, store at 4 degrees C protected from light

References:

Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.

http://www.biotium.com/product/applications/Cell_Biology/price_and_info.asp?item=30029&layer1=A;&layer2=A02;&layer3=A0203;' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/moerke_2color_PC-9.xls \
-s 10004 -i 
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Moerke 2 Color Apoptosis: SK-LM31 cells.'  \
-i 10005 \
--summary "Moerke 2 Color Apoptosis: SK-LM31 cells. Dose response of anti-mitotic compounds in human cancer cell lines at 24, 48, and 72 hours to determine their effects on apoptosis.  In this assay, the cell-permeable DNA dye Hoechst 33342 is used to stain the nuclei of all cells.  The fluorescent caspase 3 reporter NucView488 stains the nuclei of cells undergoing apoptosis (in which caspase 3 is active)." \
-p 'Day 1: Seed cells in 384-well assay plates, at approximately 2000 cells/well (the exact density varies by cell line), with 3 plates per cell line (one each for a 24 hr, 48 hr and 72 hr time point).  Add 30 uL cell suspension per well.
Day 2: Add compounds to plates by pin transfer.
Day 3: Prepare cells for 24 hr timepoint.
Prepare the 4X apoptosis reagent mixture fresh in PBS
4X apoptosis reagent mixture composition:
(1) DEVD-NucView488 caspase substrate: 1 uM
(2) Hoechst 33342:  2 ug/mL
For 4 384-well plates, 25 mL of this mixture will be sufficient and allow plenty of dead volume.
For 25 mL of mixture add 25 uL of DEVD-NucView488 substrate (from refrigerator) and 50 uL of Hoechst 33342 (from freezer).
Use WellMate (hood or bench is fine) to add the mixture, using the designated manifold (labeled “NucView”).  Add 10 uL per well, skipping the 1st 2 and last 2 columns.  Spin plates briefly at 1000 rpm in plate centrifuge and put in incubator for 90 minutes.
Prepare 2X fixative solution: 2 % formaldehyde in PBS.  Dilute a 36-36.5% formaldehyde stock bottle 1:20 in PBS.  100 mL fixative total is sufficient for 4 plates; add 5 mL formaldehyde stock to 95 mL PBS.
After 90 minutes, use benchtop (not hood) WellMate to add fixative to plates.  Use the manifold labeled “Fixative”  Add 40 uL per well (again skipping first 2 and last 2 columns).  Spin plates briefly as before.  Let fix 20-30 minutes at RT, then seal with metal foil, and image right away or store in the cold room until you are ready to image.
Day 4: Repeat for 48 hr time point
Day 5: Repeat for 72 hr time point

Plates are imaged on the ImageXpress Micro screening microscope (Molecular Devices).  4 images are collected per well of the plate at 10X magnification, using the DAPI and FITC filter sets of this instrument.
Images are analyzed using MetaXpress software.  The multiwavelength cell scoring module of the software is used detect all cells using the DAPI channel, score cells as apoptotic cells (NucView 488 positive) using the FITC channel.  The analysis produces for each well the total cell count and the % of cells in the well that are apoptotic.

Reagent stocks:
Hoechst 33342 (Invitrogen ) – 1 mg/mL stock in H2O, store at -20 degrees C
DEVD-NucView488 (Biotium) –  1 mM in DMSO, store at 4 degrees C protected from light

References:

Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.

http://www.biotium.com/product/applications/Cell_Biology/price_and_info.asp?item=30029&layer1=A;&layer2=A02;&layer3=A0203;' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/moerke_2color_SK-LM31.xls \
-s 10005 -i 
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Moerke 3 Color Apoptosis: 5637 cells.'  \
-i 10006 \
--summary "Moerke 3 Color Apoptosis: 5637 cells. Dose response of anti-mitotic compounds in human cancer cell lines at 24, 48, and 72 hours to determine their effects on apoptosis and cell death.  In this assay, the cell-permeable DNA dye Hoechst 33342 is used to stain the nuclei of all cells.  The fluorescent caspase 3 reporter NucView488 stains the nuclei of cells undergoing apoptosis (in which caspase 3 is active), and the cell-impermeable DNA dye TO-PRO3 stains only the nuclei of dead or dying cells in which membrane integrity is compromised." \
-p 'Day 1: Seed cells in 384-well assay plates at approximately 2000 cells/well (the exact density varies by cell line), with 3 plates per cell line (one each for a 24 hr, 48 hr and 72 hr time point).  Add 30 uL cell suspension per well.
Day 2: Add compounds to plates by pin transfer.
Day 3: Process cells for 24 hr timepoint. 
Prepare the 4X apoptosis reagent mixture fresh in PBS or media from stocks.
4X apoptosis reagent mixture composition:
(1) DEVD-NucView488 caspase substrate: 1 uM
(2) TO-PRO-3: 2 uM
(3) Hoechst 33342:  2 ug/mL
Add 10 uL mixture per well using WellMate plate filler or multichannel pipette, and leave in tissue culture incubator for 2 hrs.
Remove plate from incubator, seal, and image using IX Micro – should take 45-60 min to read an entire plate (assuming 10X magnification and 4 sites per well) depending on the exact settings.
If reading multiple plates, stagger reagent addition times by the time required for imaging so that the incubation times are equal.
Day 4: Repeat for 48 hr time point
Day 5: Repeat for 72 hr time point

Plates are imaged on the ImageXpress Micro screening microscope.  4 images are collected per well of the plate at 10X magnification, using the DAPI, FITC, and Cy5 filter sets of this instrument.
Images are analyzed using MetaXpress software.  The multiwavelength cell scoring module of the software is used detect all cells using the DAPI channel, score cells as apoptotic cells (NucView 488 positive) using the FITC channel, and score cells as dead or dying (TO-PRO-3 positive) using the Cy5 channel.  The analysis produces for each well the total cell count, the % of cells in the well that are apoptotic, and the % of cells in the well that are dead or dying.

Reagent stocks:
Hoechst 33342 (Invitrogen ) – 1 mg/mL stock in H2O, store at -20 degrees C
DEVD-NucView488 (Biotium) –  1 mM in DMSO, store at 4 degrees C and protect from light
TO-PRO-3 (Invitrogen) – 1 mM in DMSO, store at -20 degrees C

References:

Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.

http://www.biotium.com/product/applications/Cell_Biology/price_and_info.asp?item=30029&layer1=A;&layer2=A02;&layer3=A0203;' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/moerke_3color_5637.xls \
-s 10006 -i 
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Moerke 3 Color Apoptosis: BPH-1 cells.'  \
-i 10007 \
--summary "Moerke 3 Color Apoptosis: BPH-1 cells. Dose response of anti-mitotic compounds in human cancer cell lines at 24, 48, and 72  hours to determine their effects on apoptosis and cell death.  In this assay, the cell-permeable DNA dye Hoechst 33342 is used to stain the nuclei of all cells.  The fluorescent caspase 3 reporter NucView488 stains the nuclei of cells undergoing apoptosis (in which caspase 3 is active), and the cell-impermeable DNA dye TO-PRO3 stains only the nuclei of dead or dying cells in which membrane integrity is compromised." \
-p 'Day 1: Seed cells in 384-well assay plates at approximately 2000 cells/well (the exact density varies by cell line), with 3 plates per cell line (one each for a 24 hr, 48 hr and 72 hr time point).  Add 30 uL cell suspension per well.
Day 2: Add compounds to plates by pin transfer.
Day 3: Process cells for 24 hr timepoint. 
Prepare the 4X apoptosis reagent mixture fresh in PBS or media from stocks.
4X apoptosis reagent mixture composition:
(1) DEVD-NucView488 caspase substrate: 1 uM
(2) TO-PRO-3: 2 uM
(3) Hoechst 33342:  2 ug/mL
Add 10 uL mixture per well using WellMate plate filler or multichannel pipette, and leave in tissue culture incubator for 2 hrs.
Remove plate from incubator, seal, and image using IX Micro – should take 45-60 min to read an entire plate (assuming 10X magnification and 4 sites per well) depending on the exact settings.
If reading multiple plates, stagger reagent addition times by the time required for imaging so that the incubation times are equal.
Day 4: Repeat for 48 hr time point
Day 5: Repeat for 72 hr time point

Plates are imaged on the ImageXpress Micro screening microscope.  4 images are collected per well of the plate at 10X magnification, using the DAPI, FITC, and Cy5 filter sets of this instrument.
Images are analyzed using MetaXpress software.  The multiwavelength cell scoring module of the software is used detect all cells using the DAPI channel, score cells as apoptotic cells (NucView 488 positive) using the FITC channel, and score cells as dead or dying (TO-PRO-3 positive) using the Cy5 channel.  The analysis produces for each well the total cell count, the % of cells in the well that are apoptotic, and the % of cells in the well that are dead or dying.

Reagent stocks:
Hoechst 33342 (Invitrogen ) – 1 mg/mL stock in H2O, store at -20 degrees C
DEVD-NucView488 (Biotium) –  1 mM in DMSO, store at 4 degrees C and protect from light
TO-PRO-3 (Invitrogen) – 1 mM in DMSO, store at -20 degrees C

References:

Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.

http://www.biotium.com/product/applications/Cell_Biology/price_and_info.asp?item=30029&layer1=A;&layer2=A02;&layer3=A0203;' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/moerke_3color_BPH-1.xls \
-s 10007 -i 
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Moerke 3 Color Apoptosis: H810 cells.'  \
-i 10008 \
--summary "Moerke 3 Color Apoptosis: H810 cells. Dose response of anti-mitotic compounds in human cancer cell lines at 24, 48, and 72  hours to determine their effects on apoptosis and cell death.  In this assay, the cell-permeable DNA dye Hoechst 33342 is used to stain the nuclei of all cells.  The fluorescent caspase 3 reporter NucView488 stains the nuclei of cells undergoing apoptosis (in which caspase 3 is active), and the cell-impermeable DNA dye TO-PRO3 stains only the nuclei of dead or dying cells in which membrane integrity is compromised." \
-p 'Day 1: Seed cells in 384-well assay plates at approximately 2000 cells/well (the exact density varies by cell line), with 3 plates per cell line (one each for a 24 hr, 48 hr and 72 hr time point).  Add 30 uL cell suspension per well.
Day 2: Add compounds to plates by pin transfer.
Day 3: Process cells for 24 hr timepoint. 
Prepare the 4X apoptosis reagent mixture fresh in PBS or media from stocks.
4X apoptosis reagent mixture composition:
(1) DEVD-NucView488 caspase substrate: 1 uM
(2) TO-PRO-3: 2 uM
(3) Hoechst 33342:  2 ug/mL
Add 10 uL mixture per well using WellMate plate filler or multichannel pipette, and leave in tissue culture incubator for 2 hrs.
Remove plate from incubator, seal, and image using IX Micro – should take 45-60 min to read an entire plate (assuming 10X magnification and 4 sites per well) depending on the exact settings.
If reading multiple plates, stagger reagent addition times by the time required for imaging so that the incubation times are equal.
Day 4: Repeat for 48 hr time point
Day 5: Repeat for 72 hr time point

Plates are imaged on the ImageXpress Micro screening microscope.  4 images are collected per well of the plate at 10X magnification, using the DAPI, FITC, and Cy5 filter sets of this instrument.
Images are analyzed using MetaXpress software.  The multiwavelength cell scoring module of the software is used detect all cells using the DAPI channel, score cells as apoptotic cells (NucView 488 positive) using the FITC channel, and score cells as dead or dying (TO-PRO-3 positive) using the Cy5 channel.  The analysis produces for each well the total cell count, the % of cells in the well that are apoptotic, and the % of cells in the well that are dead or dying.

Reagent stocks:
Hoechst 33342 (Invitrogen ) – 1 mg/mL stock in H2O, store at -20 degrees C
DEVD-NucView488 (Biotium) –  1 mM in DMSO, store at 4 degrees C and protect from light
TO-PRO-3 (Invitrogen) – 1 mM in DMSO, store at -20 degrees C

References:

Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.

http://www.biotium.com/product/applications/Cell_Biology/price_and_info.asp?item=30029&layer1=A;&layer2=A02;&layer3=A0203;' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/moerke_3color_H810.xls \
-s 10008 -i 
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Moerke 3 Color Apoptosis: KYSE-140 cells.'  \
-i 10009 \
--summary "Moerke 3 Color Apoptosis: KYSE-140 cells. Dose response of anti-mitotic compounds in human cancer cell lines at 24, 48, and 72  hours to determine their effects on apoptosis and cell death.  In this assay, the cell-permeable DNA dye Hoechst 33342 is used to stain the nuclei of all cells.  The fluorescent caspase 3 reporter NucView488 stains the nuclei of cells undergoing apoptosis (in which caspase 3 is active), and the cell-impermeable DNA dye TO-PRO3 stains only the nuclei of dead or dying cells in which membrane integrity is compromised." \
-p 'Day 1: Seed cells in 384-well assay plates at approximately 2000 cells/well (the exact density varies by cell line), with 3 plates per cell line (one each for a 24 hr, 48 hr and 72 hr time point).  Add 30 uL cell suspension per well.
Day 2: Add compounds to plates by pin transfer.
Day 3: Process cells for 24 hr timepoint. 
Prepare the 4X apoptosis reagent mixture fresh in PBS or media from stocks.
4X apoptosis reagent mixture composition:
(1) DEVD-NucView488 caspase substrate: 1 uM
(2) TO-PRO-3: 2 uM
(3) Hoechst 33342:  2 ug/mL
Add 10 uL mixture per well using WellMate plate filler or multichannel pipette, and leave in tissue culture incubator for 2 hrs.
Remove plate from incubator, seal, and image using IX Micro – should take 45-60 min to read an entire plate (assuming 10X magnification and 4 sites per well) depending on the exact settings.
If reading multiple plates, stagger reagent addition times by the time required for imaging so that the incubation times are equal.
Day 4: Repeat for 48 hr time point
Day 5: Repeat for 72 hr time point

Plates are imaged on the ImageXpress Micro screening microscope.  4 images are collected per well of the plate at 10X magnification, using the DAPI, FITC, and Cy5 filter sets of this instrument.
Images are analyzed using MetaXpress software.  The multiwavelength cell scoring module of the software is used detect all cells using the DAPI channel, score cells as apoptotic cells (NucView 488 positive) using the FITC channel, and score cells as dead or dying (TO-PRO-3 positive) using the Cy5 channel.  The analysis produces for each well the total cell count, the % of cells in the well that are apoptotic, and the % of cells in the well that are dead or dying.

Reagent stocks:
Hoechst 33342 (Invitrogen ) – 1 mg/mL stock in H2O, store at -20 degrees C
DEVD-NucView488 (Biotium) –  1 mM in DMSO, store at 4 degrees C and protect from light
TO-PRO-3 (Invitrogen) – 1 mM in DMSO, store at -20 degrees C

References:

Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.

http://www.biotium.com/product/applications/Cell_Biology/price_and_info.asp?item=30029&layer1=A;&layer2=A02;&layer3=A0203;' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/moerke_3color_KYSE-140.xls \
-s 10009 -i 
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Moerke 3 Color Apoptosis: KYSE-180 cells.'  \
-i 10010 \
--summary "Moerke 3 Color Apoptosis: KYSE-180 cells. Dose response of anti-mitotic compounds in human cancer cell lines at 24, 48, and 72  hours to determine their effects on apoptosis and cell death.  In this assay, the cell-permeable DNA dye Hoechst 33342 is used to stain the nuclei of all cells.  The fluorescent caspase 3 reporter NucView488 stains the nuclei of cells undergoing apoptosis (in which caspase 3 is active), and the cell-impermeable DNA dye TO-PRO3 stains only the nuclei of dead or dying cells in which membrane integrity is compromised." \
-p 'Day 1: Seed cells in 384-well assay plates at approximately 2000 cells/well (the exact density varies by cell line), with 3 plates per cell line (one each for a 24 hr, 48 hr and 72 hr time point).  Add 30 uL cell suspension per well.
Day 2: Add compounds to plates by pin transfer.
Day 3: Process cells for 24 hr timepoint. 
Prepare the 4X apoptosis reagent mixture fresh in PBS or media from stocks.
4X apoptosis reagent mixture composition:
(1) DEVD-NucView488 caspase substrate: 1 uM
(2) TO-PRO-3: 2 uM
(3) Hoechst 33342:  2 ug/mL
Add 10 uL mixture per well using WellMate plate filler or multichannel pipette, and leave in tissue culture incubator for 2 hrs.
Remove plate from incubator, seal, and image using IX Micro – should take 45-60 min to read an entire plate (assuming 10X magnification and 4 sites per well) depending on the exact settings.
If reading multiple plates, stagger reagent addition times by the time required for imaging so that the incubation times are equal.
Day 4: Repeat for 48 hr time point
Day 5: Repeat for 72 hr time point

Plates are imaged on the ImageXpress Micro screening microscope.  4 images are collected per well of the plate at 10X magnification, using the DAPI, FITC, and Cy5 filter sets of this instrument.
Images are analyzed using MetaXpress software.  The multiwavelength cell scoring module of the software is used detect all cells using the DAPI channel, score cells as apoptotic cells (NucView 488 positive) using the FITC channel, and score cells as dead or dying (TO-PRO-3 positive) using the Cy5 channel.  The analysis produces for each well the total cell count, the % of cells in the well that are apoptotic, and the % of cells in the well that are dead or dying.

Reagent stocks:
Hoechst 33342 (Invitrogen ) – 1 mg/mL stock in H2O, store at -20 degrees C
DEVD-NucView488 (Biotium) –  1 mM in DMSO, store at 4 degrees C and protect from light
TO-PRO-3 (Invitrogen) – 1 mM in DMSO, store at -20 degrees C

References:

Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.

http://www.biotium.com/product/applications/Cell_Biology/price_and_info.asp?item=30029&layer1=A;&layer2=A02;&layer3=A0203;' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/moerke_3color_KYSE-180.xls \
-s 10010 -i 
check_errs $? "create screen result import fails"

LEAD_SCREENER_FIRST="Yangzhong"
LEAD_SCREENER_LAST="Tang"
LEAD_SCREENER_EMAIL="yangzhong_tang@hms.harvard.edu"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Tang Mitosis/Apoptosis ver.II: A375S3 cells.'  \
-i 10011 \
--summary "Tang Mitosis/Apoptosis ver.II: A375S3 cells. Dose response of anti-mitotic compounds in human cancer cell line A375S3 at 24 and 48 hours to determine effect on apoptosis, mitosis and cell death. 

In screening for small-molecule compounds that are effective at killing cancer cells, one-dimensional readout GI50, which is the EC50 value of growth inhibition, is usually used as the only criterion. A major problem with this one-readout approach is that other useful information is discarded, which could be critical for understanding the action of the compounds. In this screen, we use a single-cell-based imaging assay that can report multi-dimensional physiological responses in cells treated with small molecule kinase inhibitors." \
-p 'Protocol:
1. On Day 1, seed ~3000 cells in 30 uL of growth medium into each well of a 384-well clear-bottom black assay plate (Corning 3712), using a WellMate plate filler in a cell culture hood. 

2. On Day 2, pin transfer performed by an ICCB-Longwood Screening Facility staff member using an Epson robot system. The pin transfer adds 100nL of each diluted compound from the 384-well compound library plate to each well of the assay plate.

3. On each day of Day 3, 4, and 5 (24, 48, and 72 hrs after pin transfer), perform the following:
(A) Prepare a cocktail of reagents in PBS that has 4g/mL Hoechst33342 (Sigma B2261), 4M LysoTracker-Red (Invitrogen L7528), and 2M DEVD-NucView488 (Biotium 10403).
(B) Add 10L of the reagent cocktail to each well of the assay plate using benchtop WellMate plate filler, so that the final concentration of Hoechst33342 is 1g/mL, LysoTracker-Red is 1M, and DEVD-NucView488 is 500nM.
(C) Incubate cells in a tissue culture incubator at 37C, 5% CO2 for 1.5 hrs.
(D) Prepare 2% formaldehyde in PBS and pre-warm it in 37C water bath. 
(E) Add 40L of the pre-warmed formaldehyde to each well of cells using benchtop WellMate, so that the final concentration of formaldehyde is 1%. Then immediately centrifuge the plates at 1000rpm at room temperature for 20 minutes, in a plate centrifuge, while the cells are being fixed. 
(F) After 20 mins of fixation and centrifugation, seal the plates with adhesive plate seals. 
(G) Image the plates, ideally within the same day, using the ImageXpress Micro screening microscope (Molecular Devices) and the 10x objective lens. Image 4 sites/per well

Filter information:
DAPI [Excitation 377/50; Emission 447/60]
FITC [Excitation 482/35; Emission 536/40]
Texas Red [Excitation 562/40; Emission 624/40]

4. After image acquisition, image analysis is done using a customized Matlab program developed by Dr. Tiao Xie (Harvard Medical School). The program does segmentation on the DAPI channel to identify all nuclei, then it counts the bright, rounded cells in the Texas Red channel (LysoTracker-Red) to score mitotic cells. Finally it detects bright spots in the FITC channel (NucView) to score apoptotic cells. We also identify a population of late-stage dead cells with a “blurry” DAPI morphology, and no NucView Signal or LysoTracker Red signal.

5. When reporting data, 5 parameters are reported for each replicate for each cell line and compound condition:
a. Cell Count: The total number of cells (nuclei) stained with Hoechst 33342 and detected in the DAPI channel.
b. Interphase cells: The total number of cells less the number of Apoptotic cells, Dead cells, and Mitotic cells.
c. Apoptotic cells: The cells stained with NucView.
d. Dead cells: The “late-stage” dead cells with blurry DAPI morphology that do not stain with either NucView or LysoTracker Red.
e. Mitotic cells: The cells that stain brightly with LysoTracker Red and that have a rounded morphology.

Reference for NucView:
Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/tang_MitoApop2_A375S3.xls \
-s 10011 -i 
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Tang Mitosis/Apoptosis ver.II: AGS cells.'  \
-i 10012 \
--summary "Tang Mitosis/Apoptosis ver.II: AGS cells. Dose response of anti-mitotic compounds in human cancer cell line AGS at 24, 48 and 72 hours to determine effect on apoptosis, mitosis and cell death. 

In screening for small-molecule compounds that are effective at killing cancer cells, one-dimensional readout GI50, which is the EC50 value of growth inhibition, is usually used as the only criterion. A major problem with this one-readout approach is that other useful information is discarded, which could be critical for understanding the action of the compounds. In this screen, we use a single-cell-based imaging assay that can report multi-dimensional physiological responses in cells treated with small molecule kinase inhibitors." \
-p 'Protocol:
1. On Day 1, seed ~3000 cells in 30 uL of growth medium into each well of a 384-well clear-bottom black assay plate (Corning 3712), using a WellMate plate filler in a cell culture hood. 

2. On Day 2, pin transfer performed by an ICCB-Longwood Screening Facility staff member using an Epson robot system. The pin transfer adds 100nL of each diluted compound from the 384-well compound library plate to each well of the assay plate.

3. On each day of Day 3, 4, and 5 (24, 48, and 72 hrs after pin transfer), perform the following:
(A) Prepare a cocktail of reagents in PBS that has 4g/mL Hoechst33342 (Sigma B2261), 4M LysoTracker-Red (Invitrogen L7528), and 2M DEVD-NucView488 (Biotium 10403).
(B) Add 10L of the reagent cocktail to each well of the assay plate using benchtop WellMate plate filler, so that the final concentration of Hoechst33342 is 1g/mL, LysoTracker-Red is 1M, and DEVD-NucView488 is 500nM.
(C) Incubate cells in a tissue culture incubator at 37C, 5% CO2 for 1.5 hrs.
(D) Prepare 2% formaldehyde in PBS and pre-warm it in 37C water bath. 
(E) Add 40L of the pre-warmed formaldehyde to each well of cells using benchtop WellMate, so that the final concentration of formaldehyde is 1%. Then immediately centrifuge the plates at 1000rpm at room temperature for 20 minutes, in a plate centrifuge, while the cells are being fixed. 
(F) After 20 mins of fixation and centrifugation, seal the plates with adhesive plate seals. 
(G) Image the plates, ideally within the same day, using the ImageXpress Micro screening microscope (Molecular Devices) and the 10x objective lens. Image 4 sites/per well

Filter information:
DAPI [Excitation 377/50; Emission 447/60]
FITC [Excitation 482/35; Emission 536/40]
Texas Red [Excitation 562/40; Emission 624/40]

4. After image acquisition, image analysis is done using a customized Matlab program developed by Dr. Tiao Xie (Harvard Medical School). The program does segmentation on the DAPI channel to identify all nuclei, then it counts the bright, rounded cells in the Texas Red channel (LysoTracker-Red) to score mitotic cells. Finally it detects bright spots in the FITC channel (NucView) to score apoptotic cells. We also identify a population of late-stage dead cells with a “blurry” DAPI morphology, and no NucView Signal or LysoTracker Red signal.

5. When reporting data, 5 parameters are reported for each replicate for each cell line and compound condition:
a. Cell Count: The total number of cells (nuclei) stained with Hoechst 33342 and detected in the DAPI channel.
b. Interphase cells: The total number of cells less the number of Apoptotic cells, Dead cells, and Mitotic cells.
c. Apoptotic cells: The cells stained with NucView.
d. Dead cells: The “late-stage” dead cells with blurry DAPI morphology that do not stain with either NucView or LysoTracker Red.
e. Mitotic cells: The cells that stain brightly with LysoTracker Red and that have a rounded morphology.

Reference for NucView:
Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/tang_MitoApop2_AGS.xls \
-s 10012 -i 
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Tang Mitosis/Apoptosis ver.II: Calu-3 cells.'  \
-i 10013 \
--summary "Tang Mitosis/Apoptosis ver.II: Calu-3 cells. Dose response of anti-mitotic compounds in human cancer cell line Calu-3 at 24, 48 and 72 hours to determine effect on apoptosis, mitosis and cell death. 

In screening for small-molecule compounds that are effective at killing cancer cells, one-dimensional readout GI50, which is the EC50 value of growth inhibition, is usually used as the only criterion. A major problem with this one-readout approach is that other useful information is discarded, which could be critical for understanding the action of the compounds. In this screen, we use a single-cell-based imaging assay that can report multi-dimensional physiological responses in cells treated with small molecule kinase inhibitors." \
-p 'Protocol:
1. On Day 1, seed ~3000 cells in 30 uL of growth medium into each well of a 384-well clear-bottom black assay plate (Corning 3712), using a WellMate plate filler in a cell culture hood. 

2. On Day 2, pin transfer performed by an ICCB-Longwood Screening Facility staff member using an Epson robot system. The pin transfer adds 100nL of each diluted compound from the 384-well compound library plate to each well of the assay plate.

3. On each day of Day 3, 4, and 5 (24, 48, and 72 hrs after pin transfer), perform the following:
(A) Prepare a cocktail of reagents in PBS that has 4g/mL Hoechst33342 (Sigma B2261), 4M LysoTracker-Red (Invitrogen L7528), and 2M DEVD-NucView488 (Biotium 10403).
(B) Add 10L of the reagent cocktail to each well of the assay plate using benchtop WellMate plate filler, so that the final concentration of Hoechst33342 is 1g/mL, LysoTracker-Red is 1M, and DEVD-NucView488 is 500nM.
(C) Incubate cells in a tissue culture incubator at 37C, 5% CO2 for 1.5 hrs.
(D) Prepare 2% formaldehyde in PBS and pre-warm it in 37C water bath. 
(E) Add 40L of the pre-warmed formaldehyde to each well of cells using benchtop WellMate, so that the final concentration of formaldehyde is 1%. Then immediately centrifuge the plates at 1000rpm at room temperature for 20 minutes, in a plate centrifuge, while the cells are being fixed. 
(F) After 20 mins of fixation and centrifugation, seal the plates with adhesive plate seals. 
(G) Image the plates, ideally within the same day, using the ImageXpress Micro screening microscope (Molecular Devices) and the 10x objective lens. Image 4 sites/per well

Filter information:
DAPI [Excitation 377/50; Emission 447/60]
FITC [Excitation 482/35; Emission 536/40]
Texas Red [Excitation 562/40; Emission 624/40]

4. After image acquisition, image analysis is done using a customized Matlab program developed by Dr. Tiao Xie (Harvard Medical School). The program does segmentation on the DAPI channel to identify all nuclei, then it counts the bright, rounded cells in the Texas Red channel (LysoTracker-Red) to score mitotic cells. Finally it detects bright spots in the FITC channel (NucView) to score apoptotic cells. We also identify a population of late-stage dead cells with a “blurry” DAPI morphology, and no NucView Signal or LysoTracker Red signal.

5. When reporting data, 5 parameters are reported for each replicate for each cell line and compound condition:
a. Cell Count: The total number of cells (nuclei) stained with Hoechst 33342 and detected in the DAPI channel.
b. Interphase cells: The total number of cells less the number of Apoptotic cells, Dead cells, and Mitotic cells.
c. Apoptotic cells: The cells stained with NucView.
d. Dead cells: The “late-stage” dead cells with blurry DAPI morphology that do not stain with either NucView or LysoTracker Red.
e. Mitotic cells: The cells that stain brightly with LysoTracker Red and that have a rounded morphology.

Reference for NucView:
Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/tang_MitoApop2_Calu-3.xls \
-s 10013 -i 
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Tang Mitosis/Apoptosis ver.II: Caski cells.'  \
-i 10014 \
--summary "Tang Mitosis/Apoptosis ver.II: Caski cells. Dose response of anti-mitotic compounds in human cancer cell line Caski at 24 and 48 hours to determine effect on apoptosis, mitosis and cell death. 

In screening for small-molecule compounds that are effective at killing cancer cells, one-dimensional readout GI50, which is the EC50 value of growth inhibition, is usually used as the only criterion. A major problem with this one-readout approach is that other useful information is discarded, which could be critical for understanding the action of the compounds. In this screen, we use a single-cell-based imaging assay that can report multi-dimensional physiological responses in cells treated with small molecule kinase inhibitors." \
-p 'Protocol:
1. On Day 1, seed ~3000 cells in 30 uL of growth medium into each well of a 384-well clear-bottom black assay plate (Corning 3712), using a WellMate plate filler in a cell culture hood. 

2. On Day 2, pin transfer performed by an ICCB-Longwood Screening Facility staff member using an Epson robot system. The pin transfer adds 100nL of each diluted compound from the 384-well compound library plate to each well of the assay plate.

3. On each day of Day 3, 4, and 5 (24, 48, and 72 hrs after pin transfer), perform the following:
(A) Prepare a cocktail of reagents in PBS that has 4g/mL Hoechst33342 (Sigma B2261), 4M LysoTracker-Red (Invitrogen L7528), and 2M DEVD-NucView488 (Biotium 10403).
(B) Add 10L of the reagent cocktail to each well of the assay plate using benchtop WellMate plate filler, so that the final concentration of Hoechst33342 is 1g/mL, LysoTracker-Red is 1M, and DEVD-NucView488 is 500nM.
(C) Incubate cells in a tissue culture incubator at 37C, 5% CO2 for 1.5 hrs.
(D) Prepare 2% formaldehyde in PBS and pre-warm it in 37C water bath. 
(E) Add 40L of the pre-warmed formaldehyde to each well of cells using benchtop WellMate, so that the final concentration of formaldehyde is 1%. Then immediately centrifuge the plates at 1000rpm at room temperature for 20 minutes, in a plate centrifuge, while the cells are being fixed. 
(F) After 20 mins of fixation and centrifugation, seal the plates with adhesive plate seals. 
(G) Image the plates, ideally within the same day, using the ImageXpress Micro screening microscope (Molecular Devices) and the 10x objective lens. Image 4 sites/per well

Filter information:
DAPI [Excitation 377/50; Emission 447/60]
FITC [Excitation 482/35; Emission 536/40]
Texas Red [Excitation 562/40; Emission 624/40]

4. After image acquisition, image analysis is done using a customized Matlab program developed by Dr. Tiao Xie (Harvard Medical School). The program does segmentation on the DAPI channel to identify all nuclei, then it counts the bright, rounded cells in the Texas Red channel (LysoTracker-Red) to score mitotic cells. Finally it detects bright spots in the FITC channel (NucView) to score apoptotic cells. We also identify a population of late-stage dead cells with a “blurry” DAPI morphology, and no NucView Signal or LysoTracker Red signal.

5. When reporting data, 5 parameters are reported for each replicate for each cell line and compound condition:
a. Cell Count: The total number of cells (nuclei) stained with Hoechst 33342 and detected in the DAPI channel.
b. Interphase cells: The total number of cells less the number of Apoptotic cells, Dead cells, and Mitotic cells.
c. Apoptotic cells: The cells stained with NucView.
d. Dead cells: The “late-stage” dead cells with blurry DAPI morphology that do not stain with either NucView or LysoTracker Red.
e. Mitotic cells: The cells that stain brightly with LysoTracker Red and that have a rounded morphology.

Reference for NucView:
Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/tang_MitoApop2_Caski.xls \
-s 10014 -i 
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Tang Mitosis/Apoptosis ver.II: Colo-679 cells.'  \
-i 10015 \
--summary "Tang Mitosis/Apoptosis ver.II: Colo-679 cells. Dose response of anti-mitotic compounds in human cancer cell line Colo-679 at 24, 48 and 72 hours to determine effect on apoptosis, mitosis and cell death. 

In screening for small-molecule compounds that are effective at killing cancer cells, one-dimensional readout GI50, which is the EC50 value of growth inhibition, is usually used as the only criterion. A major problem with this one-readout approach is that other useful information is discarded, which could be critical for understanding the action of the compounds. In this screen, we use a single-cell-based imaging assay that can report multi-dimensional physiological responses in cells treated with small molecule kinase inhibitors." \
-p 'Protocol:
1. On Day 1, seed ~3000 cells in 30 uL of growth medium into each well of a 384-well clear-bottom black assay plate (Corning 3712), using a WellMate plate filler in a cell culture hood. 

2. On Day 2, pin transfer performed by an ICCB-Longwood Screening Facility staff member using an Epson robot system. The pin transfer adds 100nL of each diluted compound from the 384-well compound library plate to each well of the assay plate.

3. On each day of Day 3, 4, and 5 (24, 48, and 72 hrs after pin transfer), perform the following:
(A) Prepare a cocktail of reagents in PBS that has 4g/mL Hoechst33342 (Sigma B2261), 4M LysoTracker-Red (Invitrogen L7528), and 2M DEVD-NucView488 (Biotium 10403).
(B) Add 10L of the reagent cocktail to each well of the assay plate using benchtop WellMate plate filler, so that the final concentration of Hoechst33342 is 1g/mL, LysoTracker-Red is 1M, and DEVD-NucView488 is 500nM.
(C) Incubate cells in a tissue culture incubator at 37C, 5% CO2 for 1.5 hrs.
(D) Prepare 2% formaldehyde in PBS and pre-warm it in 37C water bath. 
(E) Add 40L of the pre-warmed formaldehyde to each well of cells using benchtop WellMate, so that the final concentration of formaldehyde is 1%. Then immediately centrifuge the plates at 1000rpm at room temperature for 20 minutes, in a plate centrifuge, while the cells are being fixed. 
(F) After 20 mins of fixation and centrifugation, seal the plates with adhesive plate seals. 
(G) Image the plates, ideally within the same day, using the ImageXpress Micro screening microscope (Molecular Devices) and the 10x objective lens. Image 4 sites/per well

Filter information:
DAPI [Excitation 377/50; Emission 447/60]
FITC [Excitation 482/35; Emission 536/40]
Texas Red [Excitation 562/40; Emission 624/40]

4. After image acquisition, image analysis is done using a customized Matlab program developed by Dr. Tiao Xie (Harvard Medical School). The program does segmentation on the DAPI channel to identify all nuclei, then it counts the bright, rounded cells in the Texas Red channel (LysoTracker-Red) to score mitotic cells. Finally it detects bright spots in the FITC channel (NucView) to score apoptotic cells. We also identify a population of late-stage dead cells with a “blurry” DAPI morphology, and no NucView Signal or LysoTracker Red signal.

5. When reporting data, 5 parameters are reported for each replicate for each cell line and compound condition:
a. Cell Count: The total number of cells (nuclei) stained with Hoechst 33342 and detected in the DAPI channel.
b. Interphase cells: The total number of cells less the number of Apoptotic cells, Dead cells, and Mitotic cells.
c. Apoptotic cells: The cells stained with NucView.
d. Dead cells: The “late-stage” dead cells with blurry DAPI morphology that do not stain with either NucView or LysoTracker Red.
e. Mitotic cells: The cells that stain brightly with LysoTracker Red and that have a rounded morphology.

Reference for NucView:
Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/tang_MitoApop2_Colo-679.xls \
-s 10015 -i 
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Tang Mitosis/Apoptosis ver.II: HEC-1 cells.'  \
-i 10016 \
--summary "Tang Mitosis/Apoptosis ver.II: HEC-1 cells. Dose response of anti-mitotic compounds in human cancer cell line HEC-1 at 24, 48 and 72 hours to determine effect on apoptosis, mitosis and cell death. 

In screening for small-molecule compounds that are effective at killing cancer cells, one-dimensional readout GI50, which is the EC50 value of growth inhibition, is usually used as the only criterion. A major problem with this one-readout approach is that other useful information is discarded, which could be critical for understanding the action of the compounds. In this screen, we use a single-cell-based imaging assay that can report multi-dimensional physiological responses in cells treated with small molecule kinase inhibitors." \
-p 'Protocol:
1. On Day 1, seed ~3000 cells in 30 uL of growth medium into each well of a 384-well clear-bottom black assay plate (Corning 3712), using a WellMate plate filler in a cell culture hood. 

2. On Day 2, pin transfer performed by an ICCB-Longwood Screening Facility staff member using an Epson robot system. The pin transfer adds 100nL of each diluted compound from the 384-well compound library plate to each well of the assay plate.

3. On each day of Day 3, 4, and 5 (24, 48, and 72 hrs after pin transfer), perform the following:
(A) Prepare a cocktail of reagents in PBS that has 4g/mL Hoechst33342 (Sigma B2261), 4M LysoTracker-Red (Invitrogen L7528), and 2M DEVD-NucView488 (Biotium 10403).
(B) Add 10L of the reagent cocktail to each well of the assay plate using benchtop WellMate plate filler, so that the final concentration of Hoechst33342 is 1g/mL, LysoTracker-Red is 1M, and DEVD-NucView488 is 500nM.
(C) Incubate cells in a tissue culture incubator at 37C, 5% CO2 for 1.5 hrs.
(D) Prepare 2% formaldehyde in PBS and pre-warm it in 37C water bath. 
(E) Add 40L of the pre-warmed formaldehyde to each well of cells using benchtop WellMate, so that the final concentration of formaldehyde is 1%. Then immediately centrifuge the plates at 1000rpm at room temperature for 20 minutes, in a plate centrifuge, while the cells are being fixed. 
(F) After 20 mins of fixation and centrifugation, seal the plates with adhesive plate seals. 
(G) Image the plates, ideally within the same day, using the ImageXpress Micro screening microscope (Molecular Devices) and the 10x objective lens. Image 4 sites/per well

Filter information:
DAPI [Excitation 377/50; Emission 447/60]
FITC [Excitation 482/35; Emission 536/40]
Texas Red [Excitation 562/40; Emission 624/40]

4. After image acquisition, image analysis is done using a customized Matlab program developed by Dr. Tiao Xie (Harvard Medical School). The program does segmentation on the DAPI channel to identify all nuclei, then it counts the bright, rounded cells in the Texas Red channel (LysoTracker-Red) to score mitotic cells. Finally it detects bright spots in the FITC channel (NucView) to score apoptotic cells. We also identify a population of late-stage dead cells with a “blurry” DAPI morphology, and no NucView Signal or LysoTracker Red signal.

5. When reporting data, 5 parameters are reported for each replicate for each cell line and compound condition:
a. Cell Count: The total number of cells (nuclei) stained with Hoechst 33342 and detected in the DAPI channel.
b. Interphase cells: The total number of cells less the number of Apoptotic cells, Dead cells, and Mitotic cells.
c. Apoptotic cells: The cells stained with NucView.
d. Dead cells: The “late-stage” dead cells with blurry DAPI morphology that do not stain with either NucView or LysoTracker Red.
e. Mitotic cells: The cells that stain brightly with LysoTracker Red and that have a rounded morphology.

Reference for NucView:
Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/tang_MitoApop2_HEC-1.xls \
-s 10016 -i 
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Tang Mitosis/Apoptosis ver.II: Ishikawa-02-ER cells.'  \
-i 10017 \
--summary "Tang Mitosis/Apoptosis ver.II: Ishikawa-02-ER cells. Dose response of anti-mitotic compounds in human cancer cell line Ishikawa-02-ER at 24, 48 and 72 hours to determine effect on apoptosis, mitosis and cell death. 

In screening for small-molecule compounds that are effective at killing cancer cells, one-dimensional readout GI50, which is the EC50 value of growth inhibition, is usually used as the only criterion. A major problem with this one-readout approach is that other useful information is discarded, which could be critical for understanding the action of the compounds. In this screen, we use a single-cell-based imaging assay that can report multi-dimensional physiological responses in cells treated with small molecule kinase inhibitors." \
-p 'Protocol:
1. On Day 1, seed ~3000 cells in 30 uL of growth medium into each well of a 384-well clear-bottom black assay plate (Corning 3712), using a WellMate plate filler in a cell culture hood. 

2. On Day 2, pin transfer performed by an ICCB-Longwood Screening Facility staff member using an Epson robot system. The pin transfer adds 100nL of each diluted compound from the 384-well compound library plate to each well of the assay plate.

3. On each day of Day 3, 4, and 5 (24, 48, and 72 hrs after pin transfer), perform the following:
(A) Prepare a cocktail of reagents in PBS that has 4g/mL Hoechst33342 (Sigma B2261), 4M LysoTracker-Red (Invitrogen L7528), and 2M DEVD-NucView488 (Biotium 10403).
(B) Add 10L of the reagent cocktail to each well of the assay plate using benchtop WellMate plate filler, so that the final concentration of Hoechst33342 is 1g/mL, LysoTracker-Red is 1M, and DEVD-NucView488 is 500nM.
(C) Incubate cells in a tissue culture incubator at 37C, 5% CO2 for 1.5 hrs.
(D) Prepare 2% formaldehyde in PBS and pre-warm it in 37C water bath. 
(E) Add 40L of the pre-warmed formaldehyde to each well of cells using benchtop WellMate, so that the final concentration of formaldehyde is 1%. Then immediately centrifuge the plates at 1000rpm at room temperature for 20 minutes, in a plate centrifuge, while the cells are being fixed. 
(F) After 20 mins of fixation and centrifugation, seal the plates with adhesive plate seals. 
(G) Image the plates, ideally within the same day, using the ImageXpress Micro screening microscope (Molecular Devices) and the 10x objective lens. Image 4 sites/per well

Filter information:
DAPI [Excitation 377/50; Emission 447/60]
FITC [Excitation 482/35; Emission 536/40]
Texas Red [Excitation 562/40; Emission 624/40]

4. After image acquisition, image analysis is done using a customized Matlab program developed by Dr. Tiao Xie (Harvard Medical School). The program does segmentation on the DAPI channel to identify all nuclei, then it counts the bright, rounded cells in the Texas Red channel (LysoTracker-Red) to score mitotic cells. Finally it detects bright spots in the FITC channel (NucView) to score apoptotic cells. We also identify a population of late-stage dead cells with a “blurry” DAPI morphology, and no NucView Signal or LysoTracker Red signal.

5. When reporting data, 5 parameters are reported for each replicate for each cell line and compound condition:
a. Cell Count: The total number of cells (nuclei) stained with Hoechst 33342 and detected in the DAPI channel.
b. Interphase cells: The total number of cells less the number of Apoptotic cells, Dead cells, and Mitotic cells.
c. Apoptotic cells: The cells stained with NucView.
d. Dead cells: The “late-stage” dead cells with blurry DAPI morphology that do not stain with either NucView or LysoTracker Red.
e. Mitotic cells: The cells that stain brightly with LysoTracker Red and that have a rounded morphology.

Reference for NucView:
Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/tang_MitoApop2_Ishikawa-02-ER.xls \
-s 10017 -i 
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Tang Mitosis/Apoptosis ver.II: JHH-6 cells.'  \
-i 10018 \
--summary "Tang Mitosis/Apoptosis ver.II: JHH-6 cells. Dose response of anti-mitotic compounds in human cancer cell line JHH-6 at 24, 48 and 72 hours to determine effect on apoptosis, mitosis and cell death. 

In screening for small-molecule compounds that are effective at killing cancer cells, one-dimensional readout GI50, which is the EC50 value of growth inhibition, is usually used as the only criterion. A major problem with this one-readout approach is that other useful information is discarded, which could be critical for understanding the action of the compounds. In this screen, we use a single-cell-based imaging assay that can report multi-dimensional physiological responses in cells treated with small molecule kinase inhibitors." \
-p 'Protocol:
1. On Day 1, seed ~3000 cells in 30 uL of growth medium into each well of a 384-well clear-bottom black assay plate (Corning 3712), using a WellMate plate filler in a cell culture hood. 

2. On Day 2, pin transfer performed by an ICCB-Longwood Screening Facility staff member using an Epson robot system. The pin transfer adds 100nL of each diluted compound from the 384-well compound library plate to each well of the assay plate.

3. On each day of Day 3, 4, and 5 (24, 48, and 72 hrs after pin transfer), perform the following:
(A) Prepare a cocktail of reagents in PBS that has 4g/mL Hoechst33342 (Sigma B2261), 4M LysoTracker-Red (Invitrogen L7528), and 2M DEVD-NucView488 (Biotium 10403).
(B) Add 10L of the reagent cocktail to each well of the assay plate using benchtop WellMate plate filler, so that the final concentration of Hoechst33342 is 1g/mL, LysoTracker-Red is 1M, and DEVD-NucView488 is 500nM.
(C) Incubate cells in a tissue culture incubator at 37C, 5% CO2 for 1.5 hrs.
(D) Prepare 2% formaldehyde in PBS and pre-warm it in 37C water bath. 
(E) Add 40L of the pre-warmed formaldehyde to each well of cells using benchtop WellMate, so that the final concentration of formaldehyde is 1%. Then immediately centrifuge the plates at 1000rpm at room temperature for 20 minutes, in a plate centrifuge, while the cells are being fixed. 
(F) After 20 mins of fixation and centrifugation, seal the plates with adhesive plate seals. 
(G) Image the plates, ideally within the same day, using the ImageXpress Micro screening microscope (Molecular Devices) and the 10x objective lens. Image 4 sites/per well

Filter information:
DAPI [Excitation 377/50; Emission 447/60]
FITC [Excitation 482/35; Emission 536/40]
Texas Red [Excitation 562/40; Emission 624/40]

4. After image acquisition, image analysis is done using a customized Matlab program developed by Dr. Tiao Xie (Harvard Medical School). The program does segmentation on the DAPI channel to identify all nuclei, then it counts the bright, rounded cells in the Texas Red channel (LysoTracker-Red) to score mitotic cells. Finally it detects bright spots in the FITC channel (NucView) to score apoptotic cells. We also identify a population of late-stage dead cells with a “blurry” DAPI morphology, and no NucView Signal or LysoTracker Red signal.

5. When reporting data, 5 parameters are reported for each replicate for each cell line and compound condition:
a. Cell Count: The total number of cells (nuclei) stained with Hoechst 33342 and detected in the DAPI channel.
b. Interphase cells: The total number of cells less the number of Apoptotic cells, Dead cells, and Mitotic cells.
c. Apoptotic cells: The cells stained with NucView.
d. Dead cells: The “late-stage” dead cells with blurry DAPI morphology that do not stain with either NucView or LysoTracker Red.
e. Mitotic cells: The cells that stain brightly with LysoTracker Red and that have a rounded morphology.

Reference for NucView:
Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/tang_MitoApop2_JHH-6.xls \
-s 10018 -i
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Tang Mitosis/Apoptosis ver.II: Kyse-150 cells.'  \
-i 10019 \
--summary "Tang Mitosis/Apoptosis ver.II: Kyse-150 cells. Dose response of anti-mitotic compounds in human cancer cell line Kyse-150 at 24, 48 and 72 hours to determine effect on apoptosis, mitosis and cell death. 

In screening for small-molecule compounds that are effective at killing cancer cells, one-dimensional readout GI50, which is the EC50 value of growth inhibition, is usually used as the only criterion. A major problem with this one-readout approach is that other useful information is discarded, which could be critical for understanding the action of the compounds. In this screen, we use a single-cell-based imaging assay that can report multi-dimensional physiological responses in cells treated with small molecule kinase inhibitors." \
-p 'Protocol:
1. On Day 1, seed ~3000 cells in 30 uL of growth medium into each well of a 384-well clear-bottom black assay plate (Corning 3712), using a WellMate plate filler in a cell culture hood. 

2. On Day 2, pin transfer performed by an ICCB-Longwood Screening Facility staff member using an Epson robot system. The pin transfer adds 100nL of each diluted compound from the 384-well compound library plate to each well of the assay plate.

3. On each day of Day 3, 4, and 5 (24, 48, and 72 hrs after pin transfer), perform the following:
(A) Prepare a cocktail of reagents in PBS that has 4g/mL Hoechst33342 (Sigma B2261), 4M LysoTracker-Red (Invitrogen L7528), and 2M DEVD-NucView488 (Biotium 10403).
(B) Add 10L of the reagent cocktail to each well of the assay plate using benchtop WellMate plate filler, so that the final concentration of Hoechst33342 is 1g/mL, LysoTracker-Red is 1M, and DEVD-NucView488 is 500nM.
(C) Incubate cells in a tissue culture incubator at 37C, 5% CO2 for 1.5 hrs.
(D) Prepare 2% formaldehyde in PBS and pre-warm it in 37C water bath. 
(E) Add 40L of the pre-warmed formaldehyde to each well of cells using benchtop WellMate, so that the final concentration of formaldehyde is 1%. Then immediately centrifuge the plates at 1000rpm at room temperature for 20 minutes, in a plate centrifuge, while the cells are being fixed. 
(F) After 20 mins of fixation and centrifugation, seal the plates with adhesive plate seals. 
(G) Image the plates, ideally within the same day, using the ImageXpress Micro screening microscope (Molecular Devices) and the 10x objective lens. Image 4 sites/per well

Filter information:
DAPI [Excitation 377/50; Emission 447/60]
FITC [Excitation 482/35; Emission 536/40]
Texas Red [Excitation 562/40; Emission 624/40]

4. After image acquisition, image analysis is done using a customized Matlab program developed by Dr. Tiao Xie (Harvard Medical School). The program does segmentation on the DAPI channel to identify all nuclei, then it counts the bright, rounded cells in the Texas Red channel (LysoTracker-Red) to score mitotic cells. Finally it detects bright spots in the FITC channel (NucView) to score apoptotic cells. We also identify a population of late-stage dead cells with a “blurry” DAPI morphology, and no NucView Signal or LysoTracker Red signal.

5. When reporting data, 5 parameters are reported for each replicate for each cell line and compound condition:
a. Cell Count: The total number of cells (nuclei) stained with Hoechst 33342 and detected in the DAPI channel.
b. Interphase cells: The total number of cells less the number of Apoptotic cells, Dead cells, and Mitotic cells.
c. Apoptotic cells: The cells stained with NucView.
d. Dead cells: The “late-stage” dead cells with blurry DAPI morphology that do not stain with either NucView or LysoTracker Red.
e. Mitotic cells: The cells that stain brightly with LysoTracker Red and that have a rounded morphology.

Reference for NucView:
Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/tang_MitoApop2_Kyse-150.xls \
-s 10019 -i
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Tang Mitosis/Apoptosis ver.II: Kyse-450 cells.'  \
-i 10020 \
--summary "Tang Mitosis/Apoptosis ver.II: Kyse-450 cells. Dose response of anti-mitotic compounds in human cancer cell line Kyse-450 at 24, 48 and 72 hours to determine effect on apoptosis, mitosis and cell death. 

In screening for small-molecule compounds that are effective at killing cancer cells, one-dimensional readout GI50, which is the EC50 value of growth inhibition, is usually used as the only criterion. A major problem with this one-readout approach is that other useful information is discarded, which could be critical for understanding the action of the compounds. In this screen, we use a single-cell-based imaging assay that can report multi-dimensional physiological responses in cells treated with small molecule kinase inhibitors." \
-p 'Protocol:
1. On Day 1, seed ~3000 cells in 30 uL of growth medium into each well of a 384-well clear-bottom black assay plate (Corning 3712), using a WellMate plate filler in a cell culture hood. 

2. On Day 2, pin transfer performed by an ICCB-Longwood Screening Facility staff member using an Epson robot system. The pin transfer adds 100nL of each diluted compound from the 384-well compound library plate to each well of the assay plate.

3. On each day of Day 3, 4, and 5 (24, 48, and 72 hrs after pin transfer), perform the following:
(A) Prepare a cocktail of reagents in PBS that has 4g/mL Hoechst33342 (Sigma B2261), 4M LysoTracker-Red (Invitrogen L7528), and 2M DEVD-NucView488 (Biotium 10403).
(B) Add 10L of the reagent cocktail to each well of the assay plate using benchtop WellMate plate filler, so that the final concentration of Hoechst33342 is 1g/mL, LysoTracker-Red is 1M, and DEVD-NucView488 is 500nM.
(C) Incubate cells in a tissue culture incubator at 37C, 5% CO2 for 1.5 hrs.
(D) Prepare 2% formaldehyde in PBS and pre-warm it in 37C water bath. 
(E) Add 40L of the pre-warmed formaldehyde to each well of cells using benchtop WellMate, so that the final concentration of formaldehyde is 1%. Then immediately centrifuge the plates at 1000rpm at room temperature for 20 minutes, in a plate centrifuge, while the cells are being fixed. 
(F) After 20 mins of fixation and centrifugation, seal the plates with adhesive plate seals. 
(G) Image the plates, ideally within the same day, using the ImageXpress Micro screening microscope (Molecular Devices) and the 10x objective lens. Image 4 sites/per well

Filter information:
DAPI [Excitation 377/50; Emission 447/60]
FITC [Excitation 482/35; Emission 536/40]
Texas Red [Excitation 562/40; Emission 624/40]

4. After image acquisition, image analysis is done using a customized Matlab program developed by Dr. Tiao Xie (Harvard Medical School). The program does segmentation on the DAPI channel to identify all nuclei, then it counts the bright, rounded cells in the Texas Red channel (LysoTracker-Red) to score mitotic cells. Finally it detects bright spots in the FITC channel (NucView) to score apoptotic cells. We also identify a population of late-stage dead cells with a “blurry” DAPI morphology, and no NucView Signal or LysoTracker Red signal.

5. When reporting data, 5 parameters are reported for each replicate for each cell line and compound condition:
a. Cell Count: The total number of cells (nuclei) stained with Hoechst 33342 and detected in the DAPI channel.
b. Interphase cells: The total number of cells less the number of Apoptotic cells, Dead cells, and Mitotic cells.
c. Apoptotic cells: The cells stained with NucView.
d. Dead cells: The “late-stage” dead cells with blurry DAPI morphology that do not stain with either NucView or LysoTracker Red.
e. Mitotic cells: The cells that stain brightly with LysoTracker Red and that have a rounded morphology.

Reference for NucView:
Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/tang_MitoApop2_Kyse-450.xls \
-s 10020 -i
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Tang Mitosis/Apoptosis ver.II: LNZTA3WT4 cells.'  \
-i 10021 \
--summary "Tang Mitosis/Apoptosis ver.II: LNZTA3WT4 cells. Dose response of anti-mitotic compounds in human cancer cell line LNZTA3WT4 at 24, 48 and 72 hours to determine effect on apoptosis, mitosis and cell death. 

In screening for small-molecule compounds that are effective at killing cancer cells, one-dimensional readout GI50, which is the EC50 value of growth inhibition, is usually used as the only criterion. A major problem with this one-readout approach is that other useful information is discarded, which could be critical for understanding the action of the compounds. In this screen, we use a single-cell-based imaging assay that can report multi-dimensional physiological responses in cells treated with small molecule kinase inhibitors." \
-p 'Protocol:
1. On Day 1, seed ~3000 cells in 30 uL of growth medium into each well of a 384-well clear-bottom black assay plate (Corning 3712), using a WellMate plate filler in a cell culture hood. 

2. On Day 2, pin transfer performed by an ICCB-Longwood Screening Facility staff member using an Epson robot system. The pin transfer adds 100nL of each diluted compound from the 384-well compound library plate to each well of the assay plate.

3. On each day of Day 3, 4, and 5 (24, 48, and 72 hrs after pin transfer), perform the following:
(A) Prepare a cocktail of reagents in PBS that has 4g/mL Hoechst33342 (Sigma B2261), 4M LysoTracker-Red (Invitrogen L7528), and 2M DEVD-NucView488 (Biotium 10403).
(B) Add 10L of the reagent cocktail to each well of the assay plate using benchtop WellMate plate filler, so that the final concentration of Hoechst33342 is 1g/mL, LysoTracker-Red is 1M, and DEVD-NucView488 is 500nM.
(C) Incubate cells in a tissue culture incubator at 37C, 5% CO2 for 1.5 hrs.
(D) Prepare 2% formaldehyde in PBS and pre-warm it in 37C water bath. 
(E) Add 40L of the pre-warmed formaldehyde to each well of cells using benchtop WellMate, so that the final concentration of formaldehyde is 1%. Then immediately centrifuge the plates at 1000rpm at room temperature for 20 minutes, in a plate centrifuge, while the cells are being fixed. 
(F) After 20 mins of fixation and centrifugation, seal the plates with adhesive plate seals. 
(G) Image the plates, ideally within the same day, using the ImageXpress Micro screening microscope (Molecular Devices) and the 10x objective lens. Image 4 sites/per well

Filter information:
DAPI [Excitation 377/50; Emission 447/60]
FITC [Excitation 482/35; Emission 536/40]
Texas Red [Excitation 562/40; Emission 624/40]

4. After image acquisition, image analysis is done using a customized Matlab program developed by Dr. Tiao Xie (Harvard Medical School). The program does segmentation on the DAPI channel to identify all nuclei, then it counts the bright, rounded cells in the Texas Red channel (LysoTracker-Red) to score mitotic cells. Finally it detects bright spots in the FITC channel (NucView) to score apoptotic cells. We also identify a population of late-stage dead cells with a “blurry” DAPI morphology, and no NucView Signal or LysoTracker Red signal.

5. When reporting data, 5 parameters are reported for each replicate for each cell line and compound condition:
a. Cell Count: The total number of cells (nuclei) stained with Hoechst 33342 and detected in the DAPI channel.
b. Interphase cells: The total number of cells less the number of Apoptotic cells, Dead cells, and Mitotic cells.
c. Apoptotic cells: The cells stained with NucView.
d. Dead cells: The “late-stage” dead cells with blurry DAPI morphology that do not stain with either NucView or LysoTracker Red.
e. Mitotic cells: The cells that stain brightly with LysoTracker Red and that have a rounded morphology.

Reference for NucView:
Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/tang_MitoApop2_LNZTA3WT4.xls \
-s 10021 -i
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Tang Mitosis/Apoptosis ver.II: MDA-MB-435S cells.'  \
-i 10022 \
--summary "Tang Mitosis/Apoptosis ver.II: MDA-MB-435S cells. Dose response of anti-mitotic compounds in human cancer cell line MDA-MB-435S at 24  hours to determine effect on apoptosis, mitosis and cell death. 

In screening for small-molecule compounds that are effective at killing cancer cells, one-dimensional readout GI50, which is the EC50 value of growth inhibition, is usually used as the only criterion. A major problem with this one-readout approach is that other useful information is discarded, which could be critical for understanding the action of the compounds. In this screen, we use a single-cell-based imaging assay that can report multi-dimensional physiological responses in cells treated with small molecule kinase inhibitors." \
-p 'Protocol:
1. On Day 1, seed ~3000 cells in 30 uL of growth medium into each well of a 384-well clear-bottom black assay plate (Corning 3712), using a WellMate plate filler in a cell culture hood. 

2. On Day 2, pin transfer performed by an ICCB-Longwood Screening Facility staff member using an Epson robot system. The pin transfer adds 100nL of each diluted compound from the 384-well compound library plate to each well of the assay plate.

3. On each day of Day 3, 4, and 5 (24, 48, and 72 hrs after pin transfer), perform the following:
(A) Prepare a cocktail of reagents in PBS that has 4g/mL Hoechst33342 (Sigma B2261), 4M LysoTracker-Red (Invitrogen L7528), and 2M DEVD-NucView488 (Biotium 10403).
(B) Add 10L of the reagent cocktail to each well of the assay plate using benchtop WellMate plate filler, so that the final concentration of Hoechst33342 is 1g/mL, LysoTracker-Red is 1M, and DEVD-NucView488 is 500nM.
(C) Incubate cells in a tissue culture incubator at 37C, 5% CO2 for 1.5 hrs.
(D) Prepare 2% formaldehyde in PBS and pre-warm it in 37C water bath. 
(E) Add 40L of the pre-warmed formaldehyde to each well of cells using benchtop WellMate, so that the final concentration of formaldehyde is 1%. Then immediately centrifuge the plates at 1000rpm at room temperature for 20 minutes, in a plate centrifuge, while the cells are being fixed. 
(F) After 20 mins of fixation and centrifugation, seal the plates with adhesive plate seals. 
(G) Image the plates, ideally within the same day, using the ImageXpress Micro screening microscope (Molecular Devices) and the 10x objective lens. Image 4 sites/per well

Filter information:
DAPI [Excitation 377/50; Emission 447/60]
FITC [Excitation 482/35; Emission 536/40]
Texas Red [Excitation 562/40; Emission 624/40]

4. After image acquisition, image analysis is done using a customized Matlab program developed by Dr. Tiao Xie (Harvard Medical School). The program does segmentation on the DAPI channel to identify all nuclei, then it counts the bright, rounded cells in the Texas Red channel (LysoTracker-Red) to score mitotic cells. Finally it detects bright spots in the FITC channel (NucView) to score apoptotic cells. We also identify a population of late-stage dead cells with a “blurry” DAPI morphology, and no NucView Signal or LysoTracker Red signal.

5. When reporting data, 5 parameters are reported for each replicate for each cell line and compound condition:
a. Cell Count: The total number of cells (nuclei) stained with Hoechst 33342 and detected in the DAPI channel.
b. Interphase cells: The total number of cells less the number of Apoptotic cells, Dead cells, and Mitotic cells.
c. Apoptotic cells: The cells stained with NucView.
d. Dead cells: The “late-stage” dead cells with blurry DAPI morphology that do not stain with either NucView or LysoTracker Red.
e. Mitotic cells: The cells that stain brightly with LysoTracker Red and that have a rounded morphology.

Reference for NucView:
Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/tang_MitoApop2_MDA-MB-435S.xls \
-s 10022 -i
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Tang Mitosis/Apoptosis ver.II: MT-3 cells.'  \
-i 10023 \
--summary "Tang Mitosis/Apoptosis ver.II: MT-3 cells. Dose response of anti-mitotic compounds in human cancer cell line MT-3 at 24, 48 and 72 hours to determine effect on apoptosis, mitosis and cell death. 

In screening for small-molecule compounds that are effective at killing cancer cells, one-dimensional readout GI50, which is the EC50 value of growth inhibition, is usually used as the only criterion. A major problem with this one-readout approach is that other useful information is discarded, which could be critical for understanding the action of the compounds. In this screen, we use a single-cell-based imaging assay that can report multi-dimensional physiological responses in cells treated with small molecule kinase inhibitors." \
-p 'Protocol:
1. On Day 1, seed ~3000 cells in 30 uL of growth medium into each well of a 384-well clear-bottom black assay plate (Corning 3712), using a WellMate plate filler in a cell culture hood. 

2. On Day 2, pin transfer performed by an ICCB-Longwood Screening Facility staff member using an Epson robot system. The pin transfer adds 100nL of each diluted compound from the 384-well compound library plate to each well of the assay plate.

3. On each day of Day 3, 4, and 5 (24, 48, and 72 hrs after pin transfer), perform the following:
(A) Prepare a cocktail of reagents in PBS that has 4g/mL Hoechst33342 (Sigma B2261), 4M LysoTracker-Red (Invitrogen L7528), and 2M DEVD-NucView488 (Biotium 10403).
(B) Add 10L of the reagent cocktail to each well of the assay plate using benchtop WellMate plate filler, so that the final concentration of Hoechst33342 is 1g/mL, LysoTracker-Red is 1M, and DEVD-NucView488 is 500nM.
(C) Incubate cells in a tissue culture incubator at 37C, 5% CO2 for 1.5 hrs.
(D) Prepare 2% formaldehyde in PBS and pre-warm it in 37C water bath. 
(E) Add 40L of the pre-warmed formaldehyde to each well of cells using benchtop WellMate, so that the final concentration of formaldehyde is 1%. Then immediately centrifuge the plates at 1000rpm at room temperature for 20 minutes, in a plate centrifuge, while the cells are being fixed. 
(F) After 20 mins of fixation and centrifugation, seal the plates with adhesive plate seals. 
(G) Image the plates, ideally within the same day, using the ImageXpress Micro screening microscope (Molecular Devices) and the 10x objective lens. Image 4 sites/per well

Filter information:
DAPI [Excitation 377/50; Emission 447/60]
FITC [Excitation 482/35; Emission 536/40]
Texas Red [Excitation 562/40; Emission 624/40]

4. After image acquisition, image analysis is done using a customized Matlab program developed by Dr. Tiao Xie (Harvard Medical School). The program does segmentation on the DAPI channel to identify all nuclei, then it counts the bright, rounded cells in the Texas Red channel (LysoTracker-Red) to score mitotic cells. Finally it detects bright spots in the FITC channel (NucView) to score apoptotic cells. We also identify a population of late-stage dead cells with a “blurry” DAPI morphology, and no NucView Signal or LysoTracker Red signal.

5. When reporting data, 5 parameters are reported for each replicate for each cell line and compound condition:
a. Cell Count: The total number of cells (nuclei) stained with Hoechst 33342 and detected in the DAPI channel.
b. Interphase cells: The total number of cells less the number of Apoptotic cells, Dead cells, and Mitotic cells.
c. Apoptotic cells: The cells stained with NucView.
d. Dead cells: The “late-stage” dead cells with blurry DAPI morphology that do not stain with either NucView or LysoTracker Red.
e. Mitotic cells: The cells that stain brightly with LysoTracker Red and that have a rounded morphology.

Reference for NucView:
Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/tang_MitoApop2_MT-3.xls \
-s 10023 -i
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Tang Mitosis/Apoptosis ver.II: NCI-1651 cells.'  \
-i 10024 \
--summary "Tang Mitosis/Apoptosis ver.II: NCI-1651 cells. Dose response of anti-mitotic compounds in human cancer cell line NCI-1651 at 24, 48 and 72 hours to determine effect on apoptosis, mitosis and cell death. 

In screening for small-molecule compounds that are effective at killing cancer cells, one-dimensional readout GI50, which is the EC50 value of growth inhibition, is usually used as the only criterion. A major problem with this one-readout approach is that other useful information is discarded, which could be critical for understanding the action of the compounds. In this screen, we use a single-cell-based imaging assay that can report multi-dimensional physiological responses in cells treated with small molecule kinase inhibitors." \
-p 'Protocol:
1. On Day 1, seed ~3000 cells in 30 uL of growth medium into each well of a 384-well clear-bottom black assay plate (Corning 3712), using a WellMate plate filler in a cell culture hood. 

2. On Day 2, pin transfer performed by an ICCB-Longwood Screening Facility staff member using an Epson robot system. The pin transfer adds 100nL of each diluted compound from the 384-well compound library plate to each well of the assay plate.

3. On each day of Day 3, 4, and 5 (24, 48, and 72 hrs after pin transfer), perform the following:
(A) Prepare a cocktail of reagents in PBS that has 4g/mL Hoechst33342 (Sigma B2261), 4M LysoTracker-Red (Invitrogen L7528), and 2M DEVD-NucView488 (Biotium 10403).
(B) Add 10L of the reagent cocktail to each well of the assay plate using benchtop WellMate plate filler, so that the final concentration of Hoechst33342 is 1g/mL, LysoTracker-Red is 1M, and DEVD-NucView488 is 500nM.
(C) Incubate cells in a tissue culture incubator at 37C, 5% CO2 for 1.5 hrs.
(D) Prepare 2% formaldehyde in PBS and pre-warm it in 37C water bath. 
(E) Add 40L of the pre-warmed formaldehyde to each well of cells using benchtop WellMate, so that the final concentration of formaldehyde is 1%. Then immediately centrifuge the plates at 1000rpm at room temperature for 20 minutes, in a plate centrifuge, while the cells are being fixed. 
(F) After 20 mins of fixation and centrifugation, seal the plates with adhesive plate seals. 
(G) Image the plates, ideally within the same day, using the ImageXpress Micro screening microscope (Molecular Devices) and the 10x objective lens. Image 4 sites/per well

Filter information:
DAPI [Excitation 377/50; Emission 447/60]
FITC [Excitation 482/35; Emission 536/40]
Texas Red [Excitation 562/40; Emission 624/40]

4. After image acquisition, image analysis is done using a customized Matlab program developed by Dr. Tiao Xie (Harvard Medical School). The program does segmentation on the DAPI channel to identify all nuclei, then it counts the bright, rounded cells in the Texas Red channel (LysoTracker-Red) to score mitotic cells. Finally it detects bright spots in the FITC channel (NucView) to score apoptotic cells. We also identify a population of late-stage dead cells with a “blurry” DAPI morphology, and no NucView Signal or LysoTracker Red signal.

5. When reporting data, 5 parameters are reported for each replicate for each cell line and compound condition:
a. Cell Count: The total number of cells (nuclei) stained with Hoechst 33342 and detected in the DAPI channel.
b. Interphase cells: The total number of cells less the number of Apoptotic cells, Dead cells, and Mitotic cells.
c. Apoptotic cells: The cells stained with NucView.
d. Dead cells: The “late-stage” dead cells with blurry DAPI morphology that do not stain with either NucView or LysoTracker Red.
e. Mitotic cells: The cells that stain brightly with LysoTracker Red and that have a rounded morphology.

Reference for NucView:
Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/tang_MitoApop2_NCI-1651.xls \
-s 10024 -i
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Tang Mitosis/Apoptosis ver.II: NCI-H1915 cells.'  \
-i 10025 \
--summary "Tang Mitosis/Apoptosis ver.II: NCI-H1915 cells. Dose response of anti-mitotic compounds in human cancer cell line NCI-H1915 at 24, 48 and 72 hours to determine effect on apoptosis, mitosis and cell death. 

In screening for small-molecule compounds that are effective at killing cancer cells, one-dimensional readout GI50, which is the EC50 value of growth inhibition, is usually used as the only criterion. A major problem with this one-readout approach is that other useful information is discarded, which could be critical for understanding the action of the compounds. In this screen, we use a single-cell-based imaging assay that can report multi-dimensional physiological responses in cells treated with small molecule kinase inhibitors." \
-p 'Protocol:
1. On Day 1, seed ~3000 cells in 30 uL of growth medium into each well of a 384-well clear-bottom black assay plate (Corning 3712), using a WellMate plate filler in a cell culture hood. 

2. On Day 2, pin transfer performed by an ICCB-Longwood Screening Facility staff member using an Epson robot system. The pin transfer adds 100nL of each diluted compound from the 384-well compound library plate to each well of the assay plate.

3. On each day of Day 3, 4, and 5 (24, 48, and 72 hrs after pin transfer), perform the following:
(A) Prepare a cocktail of reagents in PBS that has 4g/mL Hoechst33342 (Sigma B2261), 4M LysoTracker-Red (Invitrogen L7528), and 2M DEVD-NucView488 (Biotium 10403).
(B) Add 10L of the reagent cocktail to each well of the assay plate using benchtop WellMate plate filler, so that the final concentration of Hoechst33342 is 1g/mL, LysoTracker-Red is 1M, and DEVD-NucView488 is 500nM.
(C) Incubate cells in a tissue culture incubator at 37C, 5% CO2 for 1.5 hrs.
(D) Prepare 2% formaldehyde in PBS and pre-warm it in 37C water bath. 
(E) Add 40L of the pre-warmed formaldehyde to each well of cells using benchtop WellMate, so that the final concentration of formaldehyde is 1%. Then immediately centrifuge the plates at 1000rpm at room temperature for 20 minutes, in a plate centrifuge, while the cells are being fixed. 
(F) After 20 mins of fixation and centrifugation, seal the plates with adhesive plate seals. 
(G) Image the plates, ideally within the same day, using the ImageXpress Micro screening microscope (Molecular Devices) and the 10x objective lens. Image 4 sites/per well

Filter information:
DAPI [Excitation 377/50; Emission 447/60]
FITC [Excitation 482/35; Emission 536/40]
Texas Red [Excitation 562/40; Emission 624/40]

4. After image acquisition, image analysis is done using a customized Matlab program developed by Dr. Tiao Xie (Harvard Medical School). The program does segmentation on the DAPI channel to identify all nuclei, then it counts the bright, rounded cells in the Texas Red channel (LysoTracker-Red) to score mitotic cells. Finally it detects bright spots in the FITC channel (NucView) to score apoptotic cells. We also identify a population of late-stage dead cells with a “blurry” DAPI morphology, and no NucView Signal or LysoTracker Red signal.

5. When reporting data, 5 parameters are reported for each replicate for each cell line and compound condition:
a. Cell Count: The total number of cells (nuclei) stained with Hoechst 33342 and detected in the DAPI channel.
b. Interphase cells: The total number of cells less the number of Apoptotic cells, Dead cells, and Mitotic cells.
c. Apoptotic cells: The cells stained with NucView.
d. Dead cells: The “late-stage” dead cells with blurry DAPI morphology that do not stain with either NucView or LysoTracker Red.
e. Mitotic cells: The cells that stain brightly with LysoTracker Red and that have a rounded morphology.

Reference for NucView:
Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/tang_MitoApop2_NCI-H1915.xls \
-s 10025 -i
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Tang Mitosis/Apoptosis ver.II: NCI-H2023 cells.'  \
-i 10026 \
--summary "Tang Mitosis/Apoptosis ver.II: NCI-H2023 cells. Dose response of anti-mitotic compounds in human cancer cell line NCI-H2023 at 24, 48 and 72 hours to determine effect on apoptosis, mitosis and cell death. 

In screening for small-molecule compounds that are effective at killing cancer cells, one-dimensional readout GI50, which is the EC50 value of growth inhibition, is usually used as the only criterion. A major problem with this one-readout approach is that other useful information is discarded, which could be critical for understanding the action of the compounds. In this screen, we use a single-cell-based imaging assay that can report multi-dimensional physiological responses in cells treated with small molecule kinase inhibitors." \
-p 'Protocol:
1. On Day 1, seed ~3000 cells in 30 uL of growth medium into each well of a 384-well clear-bottom black assay plate (Corning 3712), using a WellMate plate filler in a cell culture hood. 

2. On Day 2, pin transfer performed by an ICCB-Longwood Screening Facility staff member using an Epson robot system. The pin transfer adds 100nL of each diluted compound from the 384-well compound library plate to each well of the assay plate.

3. On each day of Day 3, 4, and 5 (24, 48, and 72 hrs after pin transfer), perform the following:
(A) Prepare a cocktail of reagents in PBS that has 4g/mL Hoechst33342 (Sigma B2261), 4M LysoTracker-Red (Invitrogen L7528), and 2M DEVD-NucView488 (Biotium 10403).
(B) Add 10L of the reagent cocktail to each well of the assay plate using benchtop WellMate plate filler, so that the final concentration of Hoechst33342 is 1g/mL, LysoTracker-Red is 1M, and DEVD-NucView488 is 500nM.
(C) Incubate cells in a tissue culture incubator at 37C, 5% CO2 for 1.5 hrs.
(D) Prepare 2% formaldehyde in PBS and pre-warm it in 37C water bath. 
(E) Add 40L of the pre-warmed formaldehyde to each well of cells using benchtop WellMate, so that the final concentration of formaldehyde is 1%. Then immediately centrifuge the plates at 1000rpm at room temperature for 20 minutes, in a plate centrifuge, while the cells are being fixed. 
(F) After 20 mins of fixation and centrifugation, seal the plates with adhesive plate seals. 
(G) Image the plates, ideally within the same day, using the ImageXpress Micro screening microscope (Molecular Devices) and the 10x objective lens. Image 4 sites/per well

Filter information:
DAPI [Excitation 377/50; Emission 447/60]
FITC [Excitation 482/35; Emission 536/40]
Texas Red [Excitation 562/40; Emission 624/40]

4. After image acquisition, image analysis is done using a customized Matlab program developed by Dr. Tiao Xie (Harvard Medical School). The program does segmentation on the DAPI channel to identify all nuclei, then it counts the bright, rounded cells in the Texas Red channel (LysoTracker-Red) to score mitotic cells. Finally it detects bright spots in the FITC channel (NucView) to score apoptotic cells. We also identify a population of late-stage dead cells with a “blurry” DAPI morphology, and no NucView Signal or LysoTracker Red signal.

5. When reporting data, 5 parameters are reported for each replicate for each cell line and compound condition:
a. Cell Count: The total number of cells (nuclei) stained with Hoechst 33342 and detected in the DAPI channel.
b. Interphase cells: The total number of cells less the number of Apoptotic cells, Dead cells, and Mitotic cells.
c. Apoptotic cells: The cells stained with NucView.
d. Dead cells: The “late-stage” dead cells with blurry DAPI morphology that do not stain with either NucView or LysoTracker Red.
e. Mitotic cells: The cells that stain brightly with LysoTracker Red and that have a rounded morphology.

Reference for NucView:
Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/tang_MitoApop2_NCI-H2023.xls \
-s 10026 -i
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Tang Mitosis/Apoptosis ver.II: PE-CA-PJ15 cells.'  \
-i 10027 \
--summary "Tang Mitosis/Apoptosis ver.II: PE-CA-PJ15 cells. Dose response of anti-mitotic compounds in human cancer cell line PE-CA-PJ15 at 24, 48 and 72 hours to determine effect on apoptosis, mitosis and cell death. 

In screening for small-molecule compounds that are effective at killing cancer cells, one-dimensional readout GI50, which is the EC50 value of growth inhibition, is usually used as the only criterion. A major problem with this one-readout approach is that other useful information is discarded, which could be critical for understanding the action of the compounds. In this screen, we use a single-cell-based imaging assay that can report multi-dimensional physiological responses in cells treated with small molecule kinase inhibitors." \
-p 'Protocol:
1. On Day 1, seed ~3000 cells in 30 uL of growth medium into each well of a 384-well clear-bottom black assay plate (Corning 3712), using a WellMate plate filler in a cell culture hood. 

2. On Day 2, pin transfer performed by an ICCB-Longwood Screening Facility staff member using an Epson robot system. The pin transfer adds 100nL of each diluted compound from the 384-well compound library plate to each well of the assay plate.

3. On each day of Day 3, 4, and 5 (24, 48, and 72 hrs after pin transfer), perform the following:
(A) Prepare a cocktail of reagents in PBS that has 4g/mL Hoechst33342 (Sigma B2261), 4M LysoTracker-Red (Invitrogen L7528), and 2M DEVD-NucView488 (Biotium 10403).
(B) Add 10L of the reagent cocktail to each well of the assay plate using benchtop WellMate plate filler, so that the final concentration of Hoechst33342 is 1g/mL, LysoTracker-Red is 1M, and DEVD-NucView488 is 500nM.
(C) Incubate cells in a tissue culture incubator at 37C, 5% CO2 for 1.5 hrs.
(D) Prepare 2% formaldehyde in PBS and pre-warm it in 37C water bath. 
(E) Add 40L of the pre-warmed formaldehyde to each well of cells using benchtop WellMate, so that the final concentration of formaldehyde is 1%. Then immediately centrifuge the plates at 1000rpm at room temperature for 20 minutes, in a plate centrifuge, while the cells are being fixed. 
(F) After 20 mins of fixation and centrifugation, seal the plates with adhesive plate seals. 
(G) Image the plates, ideally within the same day, using the ImageXpress Micro screening microscope (Molecular Devices) and the 10x objective lens. Image 4 sites/per well

Filter information:
DAPI [Excitation 377/50; Emission 447/60]
FITC [Excitation 482/35; Emission 536/40]
Texas Red [Excitation 562/40; Emission 624/40]

4. After image acquisition, image analysis is done using a customized Matlab program developed by Dr. Tiao Xie (Harvard Medical School). The program does segmentation on the DAPI channel to identify all nuclei, then it counts the bright, rounded cells in the Texas Red channel (LysoTracker-Red) to score mitotic cells. Finally it detects bright spots in the FITC channel (NucView) to score apoptotic cells. We also identify a population of late-stage dead cells with a “blurry” DAPI morphology, and no NucView Signal or LysoTracker Red signal.

5. When reporting data, 5 parameters are reported for each replicate for each cell line and compound condition:
a. Cell Count: The total number of cells (nuclei) stained with Hoechst 33342 and detected in the DAPI channel.
b. Interphase cells: The total number of cells less the number of Apoptotic cells, Dead cells, and Mitotic cells.
c. Apoptotic cells: The cells stained with NucView.
d. Dead cells: The “late-stage” dead cells with blurry DAPI morphology that do not stain with either NucView or LysoTracker Red.
e. Mitotic cells: The cells that stain brightly with LysoTracker Red and that have a rounded morphology.

Reference for NucView:
Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/tang_MitoApop2_PE-CA-PJ15.xls \
-s 10027 -i
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Tang Mitosis/Apoptosis ver.II: PL-4 cells.'  \
-i 10028 \
--summary "Tang Mitosis/Apoptosis ver.II: PL-4 cells. Dose response of anti-mitotic compounds in human cancer cell line PL-4 at 24, 48 and 72 hours to determine effect on apoptosis, mitosis and cell death. 

In screening for small-molecule compounds that are effective at killing cancer cells, one-dimensional readout GI50, which is the EC50 value of growth inhibition, is usually used as the only criterion. A major problem with this one-readout approach is that other useful information is discarded, which could be critical for understanding the action of the compounds. In this screen, we use a single-cell-based imaging assay that can report multi-dimensional physiological responses in cells treated with small molecule kinase inhibitors." \
-p 'Protocol:
1. On Day 1, seed ~3000 cells in 30 uL of growth medium into each well of a 384-well clear-bottom black assay plate (Corning 3712), using a WellMate plate filler in a cell culture hood. 

2. On Day 2, pin transfer performed by an ICCB-Longwood Screening Facility staff member using an Epson robot system. The pin transfer adds 100nL of each diluted compound from the 384-well compound library plate to each well of the assay plate.

3. On each day of Day 3, 4, and 5 (24, 48, and 72 hrs after pin transfer), perform the following:
(A) Prepare a cocktail of reagents in PBS that has 4g/mL Hoechst33342 (Sigma B2261), 4M LysoTracker-Red (Invitrogen L7528), and 2M DEVD-NucView488 (Biotium 10403).
(B) Add 10L of the reagent cocktail to each well of the assay plate using benchtop WellMate plate filler, so that the final concentration of Hoechst33342 is 1g/mL, LysoTracker-Red is 1M, and DEVD-NucView488 is 500nM.
(C) Incubate cells in a tissue culture incubator at 37C, 5% CO2 for 1.5 hrs.
(D) Prepare 2% formaldehyde in PBS and pre-warm it in 37C water bath. 
(E) Add 40L of the pre-warmed formaldehyde to each well of cells using benchtop WellMate, so that the final concentration of formaldehyde is 1%. Then immediately centrifuge the plates at 1000rpm at room temperature for 20 minutes, in a plate centrifuge, while the cells are being fixed. 
(F) After 20 mins of fixation and centrifugation, seal the plates with adhesive plate seals. 
(G) Image the plates, ideally within the same day, using the ImageXpress Micro screening microscope (Molecular Devices) and the 10x objective lens. Image 4 sites/per well

Filter information:
DAPI [Excitation 377/50; Emission 447/60]
FITC [Excitation 482/35; Emission 536/40]
Texas Red [Excitation 562/40; Emission 624/40]

4. After image acquisition, image analysis is done using a customized Matlab program developed by Dr. Tiao Xie (Harvard Medical School). The program does segmentation on the DAPI channel to identify all nuclei, then it counts the bright, rounded cells in the Texas Red channel (LysoTracker-Red) to score mitotic cells. Finally it detects bright spots in the FITC channel (NucView) to score apoptotic cells. We also identify a population of late-stage dead cells with a “blurry” DAPI morphology, and no NucView Signal or LysoTracker Red signal.

5. When reporting data, 5 parameters are reported for each replicate for each cell line and compound condition:
a. Cell Count: The total number of cells (nuclei) stained with Hoechst 33342 and detected in the DAPI channel.
b. Interphase cells: The total number of cells less the number of Apoptotic cells, Dead cells, and Mitotic cells.
c. Apoptotic cells: The cells stained with NucView.
d. Dead cells: The “late-stage” dead cells with blurry DAPI morphology that do not stain with either NucView or LysoTracker Red.
e. Mitotic cells: The cells that stain brightly with LysoTracker Red and that have a rounded morphology.

Reference for NucView:
Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/tang_MitoApop2_PL-4.xls \
-s 10028 -i
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Tang Mitosis/Apoptosis ver.II: SKOV3 cells.'  \
-i 10029 \
--summary "Tang Mitosis/Apoptosis ver.II: SKOV3 cells. Dose response of anti-mitotic compounds in human cancer cell line SKOV3 at 24 and 48 hours to determine effect on apoptosis, mitosis and cell death. 

In screening for small-molecule compounds that are effective at killing cancer cells, one-dimensional readout GI50, which is the EC50 value of growth inhibition, is usually used as the only criterion. A major problem with this one-readout approach is that other useful information is discarded, which could be critical for understanding the action of the compounds. In this screen, we use a single-cell-based imaging assay that can report multi-dimensional physiological responses in cells treated with small molecule kinase inhibitors." \
-p 'Protocol:
1. On Day 1, seed ~3000 cells in 30 uL of growth medium into each well of a 384-well clear-bottom black assay plate (Corning 3712), using a WellMate plate filler in a cell culture hood. 

2. On Day 2, pin transfer performed by an ICCB-Longwood Screening Facility staff member using an Epson robot system. The pin transfer adds 100nL of each diluted compound from the 384-well compound library plate to each well of the assay plate.

3. On each day of Day 3, 4, and 5 (24, 48, and 72 hrs after pin transfer), perform the following:
(A) Prepare a cocktail of reagents in PBS that has 4g/mL Hoechst33342 (Sigma B2261), 4M LysoTracker-Red (Invitrogen L7528), and 2M DEVD-NucView488 (Biotium 10403).
(B) Add 10L of the reagent cocktail to each well of the assay plate using benchtop WellMate plate filler, so that the final concentration of Hoechst33342 is 1g/mL, LysoTracker-Red is 1M, and DEVD-NucView488 is 500nM.
(C) Incubate cells in a tissue culture incubator at 37C, 5% CO2 for 1.5 hrs.
(D) Prepare 2% formaldehyde in PBS and pre-warm it in 37C water bath. 
(E) Add 40L of the pre-warmed formaldehyde to each well of cells using benchtop WellMate, so that the final concentration of formaldehyde is 1%. Then immediately centrifuge the plates at 1000rpm at room temperature for 20 minutes, in a plate centrifuge, while the cells are being fixed. 
(F) After 20 mins of fixation and centrifugation, seal the plates with adhesive plate seals. 
(G) Image the plates, ideally within the same day, using the ImageXpress Micro screening microscope (Molecular Devices) and the 10x objective lens. Image 4 sites/per well

Filter information:
DAPI [Excitation 377/50; Emission 447/60]
FITC [Excitation 482/35; Emission 536/40]
Texas Red [Excitation 562/40; Emission 624/40]

4. After image acquisition, image analysis is done using a customized Matlab program developed by Dr. Tiao Xie (Harvard Medical School). The program does segmentation on the DAPI channel to identify all nuclei, then it counts the bright, rounded cells in the Texas Red channel (LysoTracker-Red) to score mitotic cells. Finally it detects bright spots in the FITC channel (NucView) to score apoptotic cells. We also identify a population of late-stage dead cells with a “blurry” DAPI morphology, and no NucView Signal or LysoTracker Red signal.

5. When reporting data, 5 parameters are reported for each replicate for each cell line and compound condition:
a. Cell Count: The total number of cells (nuclei) stained with Hoechst 33342 and detected in the DAPI channel.
b. Interphase cells: The total number of cells less the number of Apoptotic cells, Dead cells, and Mitotic cells.
c. Apoptotic cells: The cells stained with NucView.
d. Dead cells: The “late-stage” dead cells with blurry DAPI morphology that do not stain with either NucView or LysoTracker Red.
e. Mitotic cells: The cells that stain brightly with LysoTracker Red and that have a rounded morphology.

Reference for NucView:
Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/tang_MitoApop2_SKOV3.xls \
-s 10029 -i
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Tang Mitosis/Apoptosis ver.II: T24 cells.'  \
-i 10030 \
--summary "Tang Mitosis/Apoptosis ver.II: T24 cells. Dose response of anti-mitotic compounds in human cancer cell line T24 at 24 and 48 hours to determine effect on apoptosis, mitosis and cell death. 

In screening for small-molecule compounds that are effective at killing cancer cells, one-dimensional readout GI50, which is the EC50 value of growth inhibition, is usually used as the only criterion. A major problem with this one-readout approach is that other useful information is discarded, which could be critical for understanding the action of the compounds. In this screen, we use a single-cell-based imaging assay that can report multi-dimensional physiological responses in cells treated with small molecule kinase inhibitors." \
-p 'Protocol:
1. On Day 1, seed ~3000 cells in 30 uL of growth medium into each well of a 384-well clear-bottom black assay plate (Corning 3712), using a WellMate plate filler in a cell culture hood. 

2. On Day 2, pin transfer performed by an ICCB-Longwood Screening Facility staff member using an Epson robot system. The pin transfer adds 100nL of each diluted compound from the 384-well compound library plate to each well of the assay plate.

3. On each day of Day 3, 4, and 5 (24, 48, and 72 hrs after pin transfer), perform the following:
(A) Prepare a cocktail of reagents in PBS that has 4g/mL Hoechst33342 (Sigma B2261), 4M LysoTracker-Red (Invitrogen L7528), and 2M DEVD-NucView488 (Biotium 10403).
(B) Add 10L of the reagent cocktail to each well of the assay plate using benchtop WellMate plate filler, so that the final concentration of Hoechst33342 is 1g/mL, LysoTracker-Red is 1M, and DEVD-NucView488 is 500nM.
(C) Incubate cells in a tissue culture incubator at 37C, 5% CO2 for 1.5 hrs.
(D) Prepare 2% formaldehyde in PBS and pre-warm it in 37C water bath. 
(E) Add 40L of the pre-warmed formaldehyde to each well of cells using benchtop WellMate, so that the final concentration of formaldehyde is 1%. Then immediately centrifuge the plates at 1000rpm at room temperature for 20 minutes, in a plate centrifuge, while the cells are being fixed. 
(F) After 20 mins of fixation and centrifugation, seal the plates with adhesive plate seals. 
(G) Image the plates, ideally within the same day, using the ImageXpress Micro screening microscope (Molecular Devices) and the 10x objective lens. Image 4 sites/per well

Filter information:
DAPI [Excitation 377/50; Emission 447/60]
FITC [Excitation 482/35; Emission 536/40]
Texas Red [Excitation 562/40; Emission 624/40]

4. After image acquisition, image analysis is done using a customized Matlab program developed by Dr. Tiao Xie (Harvard Medical School). The program does segmentation on the DAPI channel to identify all nuclei, then it counts the bright, rounded cells in the Texas Red channel (LysoTracker-Red) to score mitotic cells. Finally it detects bright spots in the FITC channel (NucView) to score apoptotic cells. We also identify a population of late-stage dead cells with a “blurry” DAPI morphology, and no NucView Signal or LysoTracker Red signal.

5. When reporting data, 5 parameters are reported for each replicate for each cell line and compound condition:
a. Cell Count: The total number of cells (nuclei) stained with Hoechst 33342 and detected in the DAPI channel.
b. Interphase cells: The total number of cells less the number of Apoptotic cells, Dead cells, and Mitotic cells.
c. Apoptotic cells: The cells stained with NucView.
d. Dead cells: The “late-stage” dead cells with blurry DAPI morphology that do not stain with either NucView or LysoTracker Red.
e. Mitotic cells: The cells that stain brightly with LysoTracker Red and that have a rounded morphology.

Reference for NucView:
Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/tang_MitoApop2_T24.xls \
-s 10030 -i
check_errs $? "create screen result import fails"

./run.sh edu.harvard.med.screensaver.io.screens.ScreenCreator \
-AE $ECOMMONS_ADMIN  \
-st SMALL_MOLECULE  \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-t 'Tang Mitosis/Apoptosis ver.II: WiDr cells.'  \
-i 10031 \
--summary "Tang Mitosis/Apoptosis ver.II: WiDr cells. Dose response of anti-mitotic compounds in human cancer cell line WiDr at 24, 48 and 72 hours to determine effect on apoptosis, mitosis and cell death. 

In screening for small-molecule compounds that are effective at killing cancer cells, one-dimensional readout GI50, which is the EC50 value of growth inhibition, is usually used as the only criterion. A major problem with this one-readout approach is that other useful information is discarded, which could be critical for understanding the action of the compounds. In this screen, we use a single-cell-based imaging assay that can report multi-dimensional physiological responses in cells treated with small molecule kinase inhibitors." \
-p 'Protocol:
1. On Day 1, seed ~3000 cells in 30 uL of growth medium into each well of a 384-well clear-bottom black assay plate (Corning 3712), using a WellMate plate filler in a cell culture hood. 

2. On Day 2, pin transfer performed by an ICCB-Longwood Screening Facility staff member using an Epson robot system. The pin transfer adds 100nL of each diluted compound from the 384-well compound library plate to each well of the assay plate.

3. On each day of Day 3, 4, and 5 (24, 48, and 72 hrs after pin transfer), perform the following:
(A) Prepare a cocktail of reagents in PBS that has 4g/mL Hoechst33342 (Sigma B2261), 4M LysoTracker-Red (Invitrogen L7528), and 2M DEVD-NucView488 (Biotium 10403).
(B) Add 10L of the reagent cocktail to each well of the assay plate using benchtop WellMate plate filler, so that the final concentration of Hoechst33342 is 1g/mL, LysoTracker-Red is 1M, and DEVD-NucView488 is 500nM.
(C) Incubate cells in a tissue culture incubator at 37C, 5% CO2 for 1.5 hrs.
(D) Prepare 2% formaldehyde in PBS and pre-warm it in 37C water bath. 
(E) Add 40L of the pre-warmed formaldehyde to each well of cells using benchtop WellMate, so that the final concentration of formaldehyde is 1%. Then immediately centrifuge the plates at 1000rpm at room temperature for 20 minutes, in a plate centrifuge, while the cells are being fixed. 
(F) After 20 mins of fixation and centrifugation, seal the plates with adhesive plate seals. 
(G) Image the plates, ideally within the same day, using the ImageXpress Micro screening microscope (Molecular Devices) and the 10x objective lens. Image 4 sites/per well

Filter information:
DAPI [Excitation 377/50; Emission 447/60]
FITC [Excitation 482/35; Emission 536/40]
Texas Red [Excitation 562/40; Emission 624/40]

4. After image acquisition, image analysis is done using a customized Matlab program developed by Dr. Tiao Xie (Harvard Medical School). The program does segmentation on the DAPI channel to identify all nuclei, then it counts the bright, rounded cells in the Texas Red channel (LysoTracker-Red) to score mitotic cells. Finally it detects bright spots in the FITC channel (NucView) to score apoptotic cells. We also identify a population of late-stage dead cells with a “blurry” DAPI morphology, and no NucView Signal or LysoTracker Red signal.

5. When reporting data, 5 parameters are reported for each replicate for each cell line and compound condition:
a. Cell Count: The total number of cells (nuclei) stained with Hoechst 33342 and detected in the DAPI channel.
b. Interphase cells: The total number of cells less the number of Apoptotic cells, Dead cells, and Mitotic cells.
c. Apoptotic cells: The cells stained with NucView.
d. Dead cells: The “late-stage” dead cells with blurry DAPI morphology that do not stain with either NucView or LysoTracker Red.
e. Mitotic cells: The cells that stain brightly with LysoTracker Red and that have a rounded morphology.

Reference for NucView:
Cen H, Mao F, Aronchik I, Fuentes RJ, Firestone GL. DEVD-NucView488: a novel class of enzyme substrates for real-time detection of caspase-3 activity in live cells. FASEB J. 2008 Jul;22(7):2243-52.' 
check_errs $? "create screen fails"

./run.sh edu.harvard.med.screensaver.io.screenresults.ScreenResultImporter \
-AE $ECOMMONS_ADMIN \
-f $DATA_DIRECTORY/screen/tang_MitoApop2_WiDr.xls \
-s 10031 -i

## Create the studies

LAB_HEAD_FIRST="Nathanael"
LAB_HEAD_LAST="Gray"
LAB_HEAD_EMAIL="nathanael_gray@dfci.harvard.edu"
#LAB_HEAD_FIRST="Qingsong"
#LAB_HEAD_LAST="Liu"
#LAB_HEAD_EMAIL="nkliuqs97@gmail.com"
LEAD_SCREENER_FIRST="Qingsong"
LEAD_SCREENER_LAST="Liu"
LEAD_SCREENER_EMAIL="qingsong_liu@hms.harvard.edu"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/LINCS-001-compounds_selection_master_study_fields.xls \
-t 'LINCS Compound Targets and Concentrations'  \
-i 300001 \
--parseLincsSpecificFacilityID \
--summary "Information about kinase targets, bioactive concentrations, and relevant publications for the indicated kinase inhibitors.  This information was  provided by the lab of Nathanael Gray."
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10008_sorafenib_ambit.xls \
-t 'Sorafenib KINOMEscan'  \
-i 300002 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10017_HG-6-64-1_ambit.xls \
-t 'HG-6-64-1 KINOMEscan'  \
-i 300003 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10029_GW-5074_ambit.xls \
-t 'GW-5074 KINOMEscan'  \
-i 300004 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10046_SB590885_ambit.xls \
-t 'SB590885 KINOMEscan'  \
-i 300005 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10049_PLX-4720_ambit.xls \
-t 'PLX-4720 KINOMEscan'  \
-i 300006 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10050_AZ-628_ambit.xls \
-t 'AZ-628 KINOMEscan'  \
-i 300007 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10068_PLX-4032_ambit.xls \
-t 'PLX-4032 KINOMEscan'  \
-i 300008 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10006_AZD7762_ambit.xls \
-t 'AZD7762 KINOMEscan'  \
-i 300009 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10009_CP466722_ambit.xls \
-t 'CP466722 KINOMEscan'  \
-i 300010 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10010_CP724714_ambit.xls \
-t 'CP724714 KINOMEscan'  \
-i 300011 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10012_GSK429286A_ambit.xls \
-t 'GSK429286A KINOMEscan'  \
-i 300012 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10013_GSK461364_ambit.xls \
-t 'GSK461364 KINOMEscan'  \
-i 300013 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10014_GW843682_ambit.xls \
-t 'GW843682 KINOMEscan'  \
-i 300014 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10027_PF02341066_ambit.xls \
-t 'PF02341066 KINOMEscan'  \
-i 300015 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10028_BMS345541_ambit.xls \
-t 'BMS345541 KINOMEscan'  \
-i 300016 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10034_AS601245_ambit.xls \
-t 'AS601245 KINOMEscan'  \
-i 300017 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10038_WH-4-023_ambit.xls \
-t 'WH-4-023 KINOMEscan'  \
-i 300018 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10055_BX-912_ambit.xls \
-t 'BX-912 KINOMEscan'  \
-i 300019 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10059_AZD-6482_ambit.xls \
-t 'AZD-6482 KINOMEscan'  \
-i 300020 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10060_TAK-715_ambit.xls \
-t 'TAK-715 KINOMEscan'  \
-i 300021 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10061_NU7441_ambit.xls \
-t 'NU7441 KINOMEscan'  \
-i 300022 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10065_KIN001-220_ambit.xls \
-t 'KIN001-220 KINOMEscan'  \
-i 300023 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10066_MLN8054_ambit.xls \
-t 'MLN8054 KINOMEscan'  \
-i 300024 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10067_AZD1152-HQPA_ambit.xls \
-t 'AZD1152-HQPA KINOMEscan'  \
-i 300025 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10071_PD0332991_ambit.xls \
-t 'PD0332991 KINOMEscan'  \
-i 300026 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10078_THZ-2-98-01_ambit.xls \
-t 'THZ-2-98-01 KINOMEscan'  \
-i 300027 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10092_JWE-035_ambit.xls \
-t 'JWE-035 KINOMEscan'  \
-i 300028 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10096_ZM-447439_ambit.xls \
-t 'ZM-447439 KINOMEscan'  \
-i 300029 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10100_JNK-9L_ambit.xls \
-t 'JNK-9L KINOMEscan'  \
-i 300030 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/ambit_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10008_sorafenib_kinativ.xls \
-t 'Sorafenib KiNativ'  \
-i 300031 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/kinativ_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10017_HG-6-64-01_kinativ.xls \
-t 'HG-6-64-01 KiNativ'  \
-i 300032 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/kinativ_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10029_GW-5074_kinativ.xls \
-t 'GW-5074 KiNativ'  \
-i 300033 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/kinativ_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10046_SB590885_kinativ.xls \
-t 'SB590885 KiNativ'  \
-i 300034 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/kinativ_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10049_PLX-4720_kinativ.xls \
-t 'PLX-4720 KiNativ'  \
-i 300035 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/kinativ_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10050_AZ-628_kinativ.xls \
-t 'AZ-628 KiNativ'  \
-i 300036 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/kinativ_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10068_PLX4032_kinativ.xls \
-t 'PLX4032 KiNativ'  \
-i 300037 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/kinativ_protocol.txt`"
check_errs $? "create study fails"

LAB_HEAD_FIRST="Cyril"
LAB_HEAD_LAST="Benes"
LAB_HEAD_EMAIL="cbenes@partners.org"
LEAD_SCREENER_FIRST="Cyril"
LEAD_SCREENER_LAST="Benes"
LEAD_SCREENER_EMAIL="cbenes@partners.org"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10013_template.xls \
-t 'GSK461364: MGH/Sanger Institute growth inhibition data (3 dose)'  \
-i 300038 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/cmt_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10020_template.xls \
-t 'Dasatinib: MGH/Sanger Institute growth inhibition data (3 dose)'  \
-i 300039 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/cmt_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10021_template.xls \
-t 'VX680: MGH/Sanger Institute growth inhibition data (3 dose)'  \
-i 300040 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/cmt_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10022_template.xls \
-t 'GNF2: MGH/Sanger Institute growth inhibition data (3 dose)'  \
-i 300041 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/cmt_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10023_template.xls \
-t 'Imatinib: MGH/Sanger Institute growth inhibition data (3 dose)'  \
-i 300042 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/cmt_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10024_template.xls \
-t 'NVP-TAE684: MGH/Sanger Institute growth inhibition data (3 dose)'  \
-i 300043 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/cmt_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10025_template.xls \
-t 'CGP60474: MGH/Sanger Institute growth inhibition data (3 dose)'  \
-i 300044 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/cmt_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10026_template.xls \
-t 'PD173074: MGH/Sanger Institute growth inhibition data (3 dose)'  \
-i 300045 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/cmt_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10027_template.xls \
-t 'PF02341066: MGH/Sanger Institute growth inhibition data (3 dose)'  \
-i 300046 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/cmt_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10032_template.xls \
-t 'AZD0530: MGH/Sanger Institute growth inhibition data (3 dose)'  \
-i 300047 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/cmt_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10038_template.xls \
-t 'WH-4-023: MGH/Sanger Institute growth inhibition data (3 dose)'  \
-i 300048 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/cmt_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10039_template.xls \
-t 'WH-4-025: MGH/Sanger Institute growth inhibition data (3 dose)'  \
-i 300049 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/cmt_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10041_template.xls \
-t 'BI-2536: MGH/Sanger Institute growth inhibition data (3 dose)'  \
-i 300050 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/cmt_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10043_template.xls \
-t 'KIN001-127: MGH/Sanger Institute growth inhibition data (3 dose)'  \
-i 300051 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/cmt_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10045_template.xls \
-t 'A443644: MGH/Sanger Institute growth inhibition data (3 dose)'  \
-i 300052 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/cmt_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10050_template.xls \
-t 'AZ-628: MGH/Sanger Institute growth inhibition data (3 dose)'  \
-i 300053 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/cmt_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10051_template.xls \
-t 'GW-572016: MGH/Sanger Institute growth inhibition data (3 dose)'  \
-i 300054 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/cmt_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10079_template.xls \
-t 'Torin1: MGH/Sanger Institute growth inhibition data (3 dose)'  \
-i 300055 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/cmt_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10107_template.xls \
-t 'MG-132: MGH/Sanger Institute growth inhibition data (3 dose)'  \
-i 300056 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/cmt_protocol.txt`"
check_errs $? "create study fails"

./run.sh edu.harvard.med.screensaver.io.screens.StudyCreator \
-AE $ECOMMONS_ADMIN -annotationNamesInCol1  \
-y SMALL_MOLECULE -yy IN_VITRO \
-hf $LAB_HEAD_FIRST -hl $LAB_HEAD_LAST -he $LAB_HEAD_EMAIL -lf $LEAD_SCREENER_FIRST -ll $LEAD_SCREENER_LAST -le $LEAD_SCREENER_EMAIL \
-keyByFacilityId \
--replace -f $DATA_DIRECTORY/study/HMSL10108_template.xls \
-t 'Geldanamycin: MGH/Sanger Institute growth inhibition data (3 dose)'  \
-i 300057 \
--parseLincsSpecificFacilityID \
--summary "`cat $DATA_DIRECTORY/study/cmt_protocol.txt`"
check_errs $? "create study fails"

## [#3110] Track data received date, data publicized date for compounds, studies, screens

psql -q -U $DB_USER $DB -f $DATA_DIRECTORY/adjust_dates_received.sql -v ON_ERROR_STOP=1
check_errs $? "drop_all.sh fails"

## Reagent QC Attachments
./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10001.101.01.pdf -i HMSL10001 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10001.101.01.pdf -i HMSL10001 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10004.101.01.pdf -i HMSL10004 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10004.101.01.pdf -i HMSL10004 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10005.101.01.pdf -i HMSL10005 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10005.101.01.pdf -i HMSL10005 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10006.101.01.pdf -i HMSL10006 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10006.101.01.pdf -i HMSL10006 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10010.101.01.pdf -i HMSL10010 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10010.101.01.pdf -i HMSL10010 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10011.101.01.pdf -i HMSL10011 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10011.101.01.pdf -i HMSL10011 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10012.101.01.pdf -i HMSL10012 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10012.101.01.pdf -i HMSL10012 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10013.101.01.pdf -i HMSL10013 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10013.101.01.pdf -i HMSL10013 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10014.101.01.pdf -i HMSL10014 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10014.101.01.pdf -i HMSL10014 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10015.101.01.pdf -i HMSL10015 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10015.101.01.pdf -i HMSL10015 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10016.101.01.pdf -i HMSL10016 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10016.101.01.pdf -i HMSL10016 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10018.101.01.pdf -i HMSL10018 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10018.101.01.pdf -i HMSL10018 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10020.101.01.pdf -i HMSL10020 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10020.101.01.pdf -i HMSL10020 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10021.101.01.pdf -i HMSL10021 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10021.101.01.pdf -i HMSL10021 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10023.103.01.pdf -i HMSL10023 -sid 103 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10023.103.01.pdf -i HMSL10023 -sid 103 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10024.101.01.pdf -i HMSL10024 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10024.101.01.pdf -i HMSL10024 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10024.101.01.pdf -i HMSL10024 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10029.101.01.pdf -i HMSL10029 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10029.101.01.pdf -i HMSL10029 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10032.101.01.pdf -i HMSL10032 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10032.101.01.pdf -i HMSL10032 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10034.101.01.pdf -i HMSL10034 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10034.101.01.pdf -i HMSL10034 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10035.101.01.pdf -i HMSL10035 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10035.101.01.pdf -i HMSL10035 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10036.101.01.pdf -i HMSL10036 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10036.101.01.pdf -i HMSL10036 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10037.101.01.pdf -i HMSL10037 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10037.101.01.pdf -i HMSL10037 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10038.101.01.pdf -i HMSL10038 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10038.101.01.pdf -i HMSL10038 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10039.101.01.pdf -i HMSL10039 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10039.101.01.pdf -i HMSL10039 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10040.101.01.pdf -i HMSL10040 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10041.101.01.pdf -i HMSL10041 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10041.101.01.pdf -i HMSL10041 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10042.101.01.pdf -i HMSL10042 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10042.101.01.pdf -i HMSL10042 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10043.101.01.pdf -i HMSL10043 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10043.101.01.pdf -i HMSL10043 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10043.101.01.pdf -i HMSL10043 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10046.101.01.pdf -i HMSL10046 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10046.101.01.pdf -i HMSL10046 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10048.101.01.pdf -i HMSL10048 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10048.101.01.pdf -i HMSL10048 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10050.101.01.pdf -i HMSL10050 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10050.101.01.pdf -i HMSL10050 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10051.104.01.pdf -i HMSL10051 -sid 104 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10051.104.01.pdf -i HMSL10051 -sid 104 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10051.104.01.pdf -i HMSL10051 -sid 104 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10052.101.01.pdf -i HMSL10052 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10053.101.01.pdf -i HMSL10053 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10053.101.01.pdf -i HMSL10053 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10053.101.01.pdf -i HMSL10053 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10054.101.01.pdf -i HMSL10054 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10054.101.01.pdf -i HMSL10054 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10054.101.01.pdf -i HMSL10054 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10055.101.01.pdf -i HMSL10055 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10055.101.01.pdf -i HMSL10055 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10056.101.01.pdf -i HMSL10056 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10056.101.01.pdf -i HMSL10056 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10056.101.01.pdf -i HMSL10056 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10057.102.01.pdf -i HMSL10057 -sid 102 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10057.102.01.pdf -i HMSL10057 -sid 102 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10059.101.01.pdf -i HMSL10059 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10059.101.01.pdf -i HMSL10059 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10059.101.01.pdf -i HMSL10059 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10060.101.01.pdf -i HMSL10060 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10060.101.01.pdf -i HMSL10060 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10061.101.01.pdf -i HMSL10061 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10061.101.01.pdf -i HMSL10061 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10062.101.01.pdf -i HMSL10062 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10062.101.01.pdf -i HMSL10062 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10062.101.01.pdf -i HMSL10062 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10064.101.01.pdf -i HMSL10064 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10064.101.01.pdf -i HMSL10064 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10064.101.01.pdf -i HMSL10064 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10066.101.01.pdf -i HMSL10066 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10066.101.01.pdf -i HMSL10066 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10066.101.01.pdf -i HMSL10066 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10068.101.01.pdf -i HMSL10068 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10068.101.01.pdf -i HMSL10068 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10069.101.01.pdf -i HMSL10069 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10069.101.01.pdf -i HMSL10069 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10070.101.01.pdf -i HMSL10070 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10070.101.01.pdf -i HMSL10070 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10071.101.01.pdf -i HMSL10071 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10071.101.01.pdf -i HMSL10071 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10072.101.01.pdf -i HMSL10072 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10072.101.01.pdf -i HMSL10072 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10073.101.01.pdf -i HMSL10073 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10073.101.01.pdf -i HMSL10073 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10074.101.01.pdf -i HMSL10074 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10074.101.01.pdf -i HMSL10074 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10074.101.01.pdf -i HMSL10074 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10078.101.01.pdf -i HMSL10078 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10078.101.01.pdf -i HMSL10078 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10082.101.01.pdf -i HMSL10082 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10082.101.01.pdf -i HMSL10082 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10083.101.01.pdf -i HMSL10083 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10083.101.01.pdf -i HMSL10083 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10086.101.01.pdf -i HMSL10086 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10086.101.01.pdf -i HMSL10086 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10088.101.01.pdf -i HMSL10088 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10088.101.01.pdf -i HMSL10088 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10089.101.01.pdf -i HMSL10089 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10089.101.01.pdf -i HMSL10089 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10090.101.01.pdf -i HMSL10090 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10090.101.01.pdf -i HMSL10090 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10091.101.01.pdf -i HMSL10091 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10091.101.01.pdf -i HMSL10091 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10092.101.01.pdf -i HMSL10092 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10092.101.01.pdf -i HMSL10092 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10093.101.01.pdf -i HMSL10093 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10093.101.01.pdf -i HMSL10093 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10094.101.01.pdf -i HMSL10094 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10094.101.01.pdf -i HMSL10094 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10095.101.01.pdf -i HMSL10095 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10095.101.01.pdf -i HMSL10095 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10096.101.01.pdf -i HMSL10096 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10096.101.01.pdf -i HMSL10096 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10096.101.01.pdf -i HMSL10096 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10097.101.01.pdf -i HMSL10097 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10097.101.01.pdf -i HMSL10097 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10098.101.01.pdf -i HMSL10098 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10098.101.01.pdf -i HMSL10098 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/NMR_HMSL10101.101.01.pdf -i HMSL10101 -sid 101 -bid 1 -type QC-NMR
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/LCMS_HMSL10101.101.01.pdf -i HMSL10101 -sid 101 -bid 1 -type QC-LCMS
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/qc/HPLC_HMSL10101.101.01.pdf -i HMSL10101 -sid 101 -bid 1 -type QC-HPLC
check_errs $? "attachment import fails"

# "Study-File" Attached files, for viewing in the study viewer

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/study/HMSL10013_GSK461364_CMT_Study300038.xls -i HMSL10013 -sid 101 -bid 2 -type Study-File
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/study/HMSL10020_Dasatinib_CMT_Study300039.xls -i HMSL10020 -sid 101 -bid 2 -type Study-File
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/study/HMSL10021_VX680_CMT_Study300040.xls -i HMSL10021 -sid 101 -bid 4 -type Study-File
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/study/HMSL10022_GNF2_CMT_Study300041.xls -i HMSL10022 -sid 101 -bid 2 -type Study-File
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/study/HMSL10023_Imatinib_CMT_Study300042.xls -i HMSL10023 -sid 103 -bid 2 -type Study-File
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/study/HMSL10024_NVP-TAE684_CMT_Study300043.xls -i HMSL10024 -sid 101 -bid 2 -type Study-File
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/study/HMSL10025_CGP60474_CMT_Study300044.xls -i HMSL10025 -sid 101 -bid 2 -type Study-File
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/study/HMSL10026_PD173074_CMT_Study300045.xls -i HMSL10026 -sid 101 -bid 2 -type Study-File
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/study/HMSL10027_PF02341066_CMT_Study300046.xls -i HMSL10027 -sid 101 -bid 2 -type Study-File
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/study/HMSL10032_AZD0530_CMT_Study300047.xls -i HMSL10032 -sid 101 -bid 2 -type Study-File
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/study/HMSL10038_WH-4-023_CMT_Study300048.xls -i HMSL10038 -sid 101 -bid 2 -type Study-File
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/study/HMSL10039_WH-4-025_CMT_Study300049.xls -i HMSL10039 -sid 101 -bid 2 -type Study-File
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/study/HMSL10041_BI-2536_CMT_Study300050.xls -i HMSL10041 -sid 101 -bid 3 -type Study-File
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/study/HMSL10043_KIN001-127_CMT_Study300051.xls -i HMSL10043 -sid 101 -bid 2 -type Study-File
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/study/HMSL10045_A443644_CMT_Study300052.xls -i HMSL10045 -sid 101 -bid 2 -type Study-File
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/study/HMSL10050_AZ-628_CMT_Study300053.xls -i HMSL10050 -sid 101 -bid 2 -type Study-File
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/study/HMSL10051_GW-572016_CMT_Study300054.xls -i HMSL10051 -sid 104 -bid 2 -type Study-File
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/study/HMSL10079_Torin1_CMT_Study300055.xls -i HMSL10079 -sid 101 -bid 2 -type Study-File
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/study/HMSL10107_MG-132_CMT_Study300056.xls -i HMSL10107 -sid 101 -bid 1 -type Study-File
check_errs $? "attachment import fails"

./run.sh edu.harvard.med.lincs.screensaver.io.libraries.ReagentAttachmentImporter \
-f $DATA_DIRECTORY/study/HMSL10108_Geldanamycin_CMT_Study300057.xls -i HMSL10108 -sid 101 -bid 1 -type Study-File
check_errs $? "attachment import fails"

# THIS SHOULD ALWAYS BE THE LAST COMMAND!
psql -q -U $DB_USER $DB -c analyze