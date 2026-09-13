#!/bin/bash

echo "======================================================"
echo " MadJax SMEFT Generation Setup"
echo "======================================================"
while true; do
    read -e -p "Enter a short name for this project (e.g., ttbar): " PROJ_NAME
    if [[ -n "$PROJ_NAME" ]]; then
        break
    else
        echo "Please enter a valid project name."
    fi
done

# Define directories dynamically
MG_DIR="MG5_aMC_v2_9_18"
OUT_DIR="${PROJ_NAME}_xsec"
CARDS_DIR="${PROJ_NAME}_cards"

echo "======================================================"
echo " 1-2. Downloading and extracting MadGraph5_aMC@NLO..."
echo "======================================================"
wget -nc https://launchpad.net/mg5amcnlo/lts/2.9.x/+download/MG5_aMC_v2.9.18.tar.gz
tar -xaf MG5_aMC_v2.9.18.tar.gz

cp prep_cards.py "$MG_DIR/"
chmod +x "$MG_DIR/prep_cards.py"

echo "======================================================"
echo " 3-5. Downloading and extracting SMEFTsim UFO model..."
echo "======================================================"
mkdir -p "$MG_DIR/models"
cd "$MG_DIR/models" || exit 1
wget -nc https://feynrules.irmp.ucl.ac.be/raw-attachment/wiki/SMEFT/SMEFTsim_topU3l_MwScheme_UFO.tar.gz
tar -xvzf SMEFTsim_topU3l_MwScheme_UFO.tar.gz
cd ../../ # Return to script execution directory

echo "======================================================"
echo " 6. Applying SMEFTsim Patch..."
echo "======================================================"

# Apply the patch with flexible whitespace parsing (-l) to prevent copy/paste errors
cd "$MG_DIR" || exit 1
patch -p1 -l < ../smeft_fix.patch

echo "======================================================"
echo " 8. Interactive Process Setup"
echo "======================================================"
mkdir -p "$CARDS_DIR"

PROC_CARD="proc_card.dat"
PARAM_CARD="${CARDS_DIR}/param_card.dat"
RUN_CARD="${CARDS_DIR}/run_card.dat"

# Initialize proc_card header
cat << 'EOF' > "$PROC_CARD"
import model SMEFTsim_topU3l_MwScheme_UFO

define p = g u c d s b u~ c~ d~ s~ b~
define j = p
define l+ = e+ mu+ ta+
define l- = e- mu- ta-
define vl = ve vm vt
define vl~ = ve~ vm~ vt~
define had = u c d s u~ c~ d~ s~

set crash_on_error never
EOF

# Prompt for the base process
echo -e "\nDefine your base physics process. Do NOT include the NPprop=... constraint here."
echo "Example: p p > t t~ z"
while true; do
    read -e -p "Base process (generate): " primary_proc
    if [[ -n "$primary_proc" ]]; then
        break
    else
        echo "Please enter a valid base process."
    fi
done

# Prompt for additional processes (for merging)
ADDITIONAL_PROCS=()
echo -e "\nAdd additional multi-jet processes (e.g., 'p p > t t~ z j')."
echo "Type 'done' or leave blank when finished."
while true; do
    read -e -p "Additional process (add process): " add_proc
    if [[ "${add_proc,,}" == "done" || -z "$add_proc" ]]; then
        break
    fi
    ADDITIONAL_PROCS+=("$add_proc")
done

# Array of all 182 quadratic SMEFT terms
WC_MODIFIERS=(
    "NPcbb^2==2 NPcpv^2==0"
    "NPcbd1^2==2 NPcpv^2==0"
    "NPcbd8^2==2 NPcpv^2==0"
    "NPcbe^2==2 NPcpv^2==0"
    "NPcbG^2==2 NPcpv^2==2"
    "NPcbG^2==2 NPcpv^2==0"
    "NPcbH^2==2 NPcpv^2==2"
    "NPcbH^2==2 NPcpv^2==0"
    "NPcbj1^2==2 NPcpv^2==0"
    "NPcbj8^2==2 NPcpv^2==0"
    "NPcbl^2==2 NPcpv^2==0"
    "NPcbu1^2==2 NPcpv^2==0"
    "NPcbu8^2==2 NPcpv^2==0"
    "NPcbW^2==2 NPcpv^2==2"
    "NPcbW^2==2 NPcpv^2==0"
    "NPcdd1^2==2 NPcpv^2==0"
    "NPcdd8^2==2 NPcpv^2==0"
    "NPced^2==2 NPcpv^2==0"
    "NPcee^2==2 NPcpv^2==0"
    "NPceu^2==2 NPcpv^2==0"
    "NPcG^2==2 NPcpv^2==0"
    "NPcGtil^2==2 NPcpv^2==2"
    "NPcH^2==2 NPcpv^2==0"
    "NPcHbox^2==2 NPcpv^2==0"
    "NPcHDD^2==2 NPcpv^2==0"
    "NPcHG^2==2 NPcpv^2==0"
    "NPcHGtil^2==2 NPcpv^2==2"
    "NPcHW^2==2 NPcpv^2==0"
    "NPcHWtil^2==2 NPcpv^2==2"
    "NPcjd1^2==2 NPcpv^2==0"
    "NPcjd8^2==2 NPcpv^2==0"
    "NPcje^2==2 NPcpv^2==0"
    "NPcjj11^2==2 NPcpv^2==0"
    "NPcjj18^2==2 NPcpv^2==0"
    "NPcjj31^2==2 NPcpv^2==0"
    "NPcjj38^2==2 NPcpv^2==0"
    "NPcju1^2==2 NPcpv^2==0"
    "NPcju8^2==2 NPcpv^2==0"
    "NPcld^2==2 NPcpv^2==0"
    "NPcle^2==2 NPcpv^2==0"
    "NPclj1^2==2 NPcpv^2==0"
    "NPclj3^2==2 NPcpv^2==0"
    "NPcll^2==2 NPcpv^2==0"
    "NPcll1^2==2 NPcpv^2==0"
    "NPclu^2==2 NPcpv^2==0"
    "NPcQb1^2==2 NPcpv^2==0"
    "NPcQb8^2==2 NPcpv^2==0"
    "NPcQd1^2==2 NPcpv^2==0"
    "NPcQd8^2==2 NPcpv^2==0"
    "NPcQe^2==2 NPcpv^2==0"
    "NPcQj11^2==2 NPcpv^2==0"
    "NPcQj18^2==2 NPcpv^2==0"
    "NPcQj31^2==2 NPcpv^2==0"
    "NPcQj38^2==2 NPcpv^2==0"
    "NPcQl1^2==2 NPcpv^2==0"
    "NPcQl3^2==2 NPcpv^2==0"
    "NPcQQ1^2==2 NPcpv^2==0"
    "NPcQQ8^2==2 NPcpv^2==0"
    "NPcQt1^2==2 NPcpv^2==0"
    "NPcQt8^2==2 NPcpv^2==0"
    "NPcpv^2==2 NPcQtQb1^2==2"
    "NPcQtQb1^2==2 NPcpv^2==0"
    "NPcpv^2==2 NPcQtQb8^2==2"
    "NPcQtQb8^2==2 NPcpv^2==0"
    "NPcQu1^2==2 NPcpv^2==0"
    "NPcQu8^2==2 NPcpv^2==0"
    "NPctb1^2==2 NPcpv^2==0"
    "NPctb8^2==2 NPcpv^2==0"
    "NPctd1^2==2 NPcpv^2==0"
    "NPctd8^2==2 NPcpv^2==0"
    "NPcte^2==2 NPcpv^2==0"
    "NPcpv^2==2 NPctG^2==2"
    "NPctG^2==2 NPcpv^2==0"
    "NPcbB^2==2 NPcpv^2==2"
    "NPcbB^2==2 NPcpv^2==0"
    "NPcpv^2==2 NPctB^2==2"
    "NPctB^2==2 NPcpv^2==0"
    "NPcHB^2==2 NPcpv^2==0"
    "NPcHBtil^2==2 NPcpv^2==2"
    "NPcpv^2==2 NPctH^2==2"
    "NPctH^2==2 NPcpv^2==0"
    "NPctj1^2==2 NPcpv^2==0"
    "NPctj8^2==2 NPcpv^2==0"
    "NPctl^2==2 NPcpv^2==0"
    "NPctt^2==2 NPcpv^2==0"
    "NPctu1^2==2 NPcpv^2==0"
    "NPctu8^2==2 NPcpv^2==0"
    "NPcpv^2==2 NPctW^2==2"
    "NPctW^2==2 NPcpv^2==0"
    "NPcud1^2==2 NPcpv^2==0"
    "NPcud8^2==2 NPcpv^2==0"
    "NPcuu1^2==2 NPcpv^2==0"
    "NPcuu8^2==2 NPcpv^2==0"
    "NPcW^2==2 NPcpv^2==0"
    "NPcpv^2==2 NPcWtil^2==2"
    "NPcHWB^2==2 NPcpv^2==0"
    "NPcHWBtil^2==2 NPcpv^2==2"
    "NPcHj3^2==2 NPcpv^2==0"
    "NPcHl3^2==2 NPcpv^2==0"
    "NPcHQ3^2==2 NPcpv^2==0"
    "NPcHtb^2==2 NPcpv^2==2"
    "NPcHtb^2==2 NPcpv^2==0"
    "NPcHbq^2==2 NPcpv^2==0"
    "NPcHd^2==2 NPcpv^2==0"
    "NPcHe^2==2 NPcpv^2==0"
    "NPcHj1^2==2 NPcpv^2==0"
    "NPcHl1^2==2 NPcpv^2==0"
    "NPcHQ1^2==2 NPcpv^2==0"
    "NPcHt^2==2 NPcpv^2==0"
    "NPcHu^2==2 NPcpv^2==0"
    "NPcjQtu1^2==2 NPcpv^2==2"
    "NPcjQtu1^2==2 NPcpv^2==0"
    "NPcjQtu8^2==2 NPcpv^2==2"
    "NPcjQtu8^2==2 NPcpv^2==0"
    "NPcjuQb1^2==2 NPcpv^2==2"
    "NPcjuQb1^2==2 NPcpv^2==0"
    "NPcjuQb8^2==2 NPcpv^2==2"
    "NPcjuQb8^2==2 NPcpv^2==0"
    "NPcpv^2==2 NPcQujb1^2==2"
    "NPcQujb1^2==2 NPcpv^2==0"
    "NPcpv^2==2 NPcQujb8^2==2"
    "NPcQujb8^2==2 NPcpv^2==0"
    "NPcpv^2==2 NPcuB^2==2"
    "NPcuB^2==2 NPcpv^2==0"
    "NPcpv^2==2 NPcuG^2==2"
    "NPcuG^2==2 NPcpv^2==0"
    "NPcpv^2==2 NPcuH^2==2"
    "NPcuH^2==2 NPcpv^2==0"
    "NPcpv^2==2 NPcuW^2==2"
    "NPcuW^2==2 NPcpv^2==0"
    "NPcdG^2==2 NPcpv^2==2"
    "NPcdG^2==2 NPcpv^2==0"
    "NPcdH^2==2 NPcpv^2==2"
    "NPcdH^2==2 NPcpv^2==0"
    "NPcdW^2==2 NPcpv^2==2"
    "NPcdW^2==2 NPcpv^2==0"
    "NPcjQbd1^2==2 NPcpv^2==2"
    "NPcjQbd1^2==2 NPcpv^2==0"
    "NPcjQbd8^2==2 NPcpv^2==2"
    "NPcjQbd8^2==2 NPcpv^2==0"
    "NPcjtQd1^2==2 NPcpv^2==2"
    "NPcjtQd1^2==2 NPcpv^2==0"
    "NPcjtQd8^2==2 NPcpv^2==2"
    "NPcjtQd8^2==2 NPcpv^2==0"
    "NPcpv^2==2 NPcQtjd1^2==2"
    "NPcQtjd1^2==2 NPcpv^2==0"
    "NPcpv^2==2 NPcQtjd8^2==2"
    "NPcQtjd8^2==2 NPcpv^2==0"
    "NPcdB^2==2 NPcpv^2==2"
    "NPcdB^2==2 NPcpv^2==0"
    "NPcjujd11^2==2 NPcpv^2==2"
    "NPcjujd11^2==2 NPcpv^2==0"
    "NPcjujd1^2==2 NPcpv^2==2"
    "NPcjujd1^2==2 NPcpv^2==0"
    "NPcjujd81^2==2 NPcpv^2==2"
    "NPcjujd81^2==2 NPcpv^2==0"
    "NPcjujd8^2==2 NPcpv^2==2"
    "NPcjujd8^2==2 NPcpv^2==0"
    "NPceH^2==2 NPcpv^2==2"
    "NPceH^2==2 NPcpv^2==0"
    "NPceW^2==2 NPcpv^2==2"
    "NPceW^2==2 NPcpv^2==0"
    "NPclebQ^2==2 NPcpv^2==2"
    "NPclebQ^2==2 NPcpv^2==0"
    "NPcleQt1^2==2 NPcpv^2==2"
    "NPcleQt1^2==2 NPcpv^2==0"
    "NPcleQt3^2==2 NPcpv^2==2"
    "NPcleQt3^2==2 NPcpv^2==0"
    "NPceB^2==2 NPcpv^2==2"
    "NPceB^2==2 NPcpv^2==0"
    "NPcleju1^2==2 NPcpv^2==2"
    "NPcleju1^2==2 NPcpv^2==0"
    "NPcleju3^2==2 NPcpv^2==2"
    "NPcleju3^2==2 NPcpv^2==0"
    "NPcledj^2==2 NPcpv^2==2"
    "NPcledj^2==2 NPcpv^2==0"
    "NPcpv^2==2 NPcutbd1^2==2"
    "NPcutbd1^2==2 NPcpv^2==0"
    "NPcpv^2==2 NPcutbd8^2==2"
    "NPcutbd8^2==2 NPcpv^2==0"
    "NPcHud^2==2 NPcpv^2==2"
    "NPcHud^2==2 NPcpv^2==0"
)

# Helper function to append a fully formatted execution block
write_block() {
    local modifier="$1"
    echo "" >> "$PROC_CARD"
    echo "generate ${primary_proc}        ${modifier}" >> "$PROC_CARD"

    # Append any additional jet bins
    for ap in "${ADDITIONAL_PROCS[@]}"; do
        echo "add process ${ap}        ${modifier}" >> "$PROC_CARD"
    done

    # Append the launch instructions
    cat << EOF >> "$PROC_CARD"
output $OUT_DIR -nojpeg
launch $OUT_DIR
${CARDS_DIR}/param_card.dat
${CARDS_DIR}/run_card.dat
done
EOF
}

echo "Generating proc_card.dat with 183 blocks..."

# 1. Output the Standard Model baseline
write_block "NPprop=0 SMHLOOP=0 NP=1 NP^2==0"

# 2. Iterate through all 182 SMEFT operators
for wc_mod in "${WC_MODIFIERS[@]}"; do
    write_block "NPprop=0 SMHLOOP=0 NP=1 NP^2==2 ${wc_mod}"
done

echo "Done generating proc_card.dat!"

# Initialize param_card
cat << 'EOF' > "$PARAM_CARD"
######################################################################
## PARAM_CARD AUTOMATICALY GENERATED BY MG5 FOLLOWING UFO MODEL   ####
######################################################################
##                                                                  ##
##  Width set on Auto will be computed following the information    ##
##        present in the decay.py files of the model.               ##
##        See  arXiv:1402.1178 for more details.                    ##
##                                                                  ##
######################################################################

###################################
## INFORMATION FOR MASS
###################################
Block mass
    1 4.670000e-03 # MD
    2 2.160000e-03 # MU
    3 9.300000e-02 # MS
    4 1.270000e+00 # MC
    5 4.180000e+00 # MB
    6 1.727600e+02 # MT
   11 5.110000e-04 # Me
   13 1.056600e-01 # MMU
   15 1.777000e+00 # MTA
   23 9.118760e+01 # MZ
   25 1.250900e+02 # MH
## Dependent parameters, given by model restrictions.
## Those values should be edited following the
## analytical expression. MG5 ignores those values
## but they are important for interfacing the output of MG5
## to external program such as Pythia.
  12 0.000000e+00 # ve : 0.0
  14 0.000000e+00 # vm : 0.0
  16 0.000000e+00 # vt : 0.0
  21 0.000000e+00 # g : 0.0
  22 0.000000e+00 # a : 0.0
  9000005 9.118760e+01 # z1 : MZ
  9000006 8.038700e+01 # w1+ : MWsm
  9000007 1.727600e+02 # t1 : MT
  9000008 1.250900e+02 # h1 : MH
  24 8.038700e+01 # w+ : MW

###################################
## INFORMATION FOR SMEFT
###################################
Block smeft
    1 1.00000e+00 # cG
    2 1.00000e+00 # cW
    3 1.00000e+00 # cH
    4 1.00000e+00 # cHbox
    5 1.00000e+00 # cHDD
    6 1.00000e+00 # cHG
    7 1.00000e+00 # cHW
    8 1.00000e+00 # cHB
    9 1.00000e+00 # cHWB
   10 1.00000e+00 # cuHRe
   11 1.00000e+00 # ctHRe
   12 1.00000e+00 # cdHRe
   13 1.00000e+00 # cbHRe
   14 1.00000e+00 # cuGRe
   15 1.00000e+00 # ctGRe
   16 1.00000e+00 # cuWRe
   17 1.00000e+00 # ctWRe
   18 1.00000e+00 # cuBRe
   19 1.00000e+00 # ctBRe
   20 1.00000e+00 # cdGRe
   21 1.00000e+00 # cbGRe
   22 1.00000e+00 # cdWRe
   23 1.00000e+00 # cbWRe
   24 1.00000e+00 # cdBRe
   25 1.00000e+00 # cbBRe
   26 1.00000e+00 # cHj1
   27 1.00000e+00 # cHQ1
   28 1.00000e+00 # cHj3
   29 1.00000e+00 # cHQ3
   30 1.00000e+00 # cHu
   31 1.00000e+00 # cHt
   32 1.00000e+00 # cHd
   33 1.00000e+00 # cHbq
   34 1.00000e+00 # cHudRe
   35 1.00000e+00 # cHtbRe
   36 1.00000e+00 # cjj11
   37 1.00000e+00 # cjj18
   38 1.00000e+00 # cjj31
   39 1.00000e+00 # cjj38
   40 1.00000e+00 # cQj11
   41 1.00000e+00 # cQj18
   42 1.00000e+00 # cQj31
   43 1.00000e+00 # cQj38
   44 1.00000e+00 # cQQ1
   45 1.00000e+00 # cQQ8
   46 1.00000e+00 # cuu1
   47 1.00000e+00 # cuu8
   48 1.00000e+00 # ctt
   49 1.00000e+00 # ctu1
   50 1.00000e+00 # ctu8
   51 1.00000e+00 # cdd1
   52 1.00000e+00 # cdd8
   53 1.00000e+00 # cbb
   54 1.00000e+00 # cbd1
   55 1.00000e+00 # cbd8
   56 1.00000e+00 # cud1
   57 1.00000e+00 # ctb1
   58 1.00000e+00 # ctd1
   59 1.00000e+00 # cbu1
   60 1.00000e+00 # cud8
   61 1.00000e+00 # ctb8
   62 1.00000e+00 # ctd8
   63 1.00000e+00 # cbu8
   64 1.00000e+00 # cutbd1Re
   65 1.00000e+00 # cutbd8Re
   66 1.00000e+00 # cju1
   67 1.00000e+00 # cQu1
   68 1.00000e+00 # cju8
   69 1.00000e+00 # cQu8
   70 1.00000e+00 # ctj1
   71 1.00000e+00 # ctj8
   72 1.00000e+00 # cQt1
   73 1.00000e+00 # cQt8
   74 1.00000e+00 # cjd1
   75 1.00000e+00 # cjd8
   76 1.00000e+00 # cQd1
   77 1.00000e+00 # cQd8
   78 1.00000e+00 # cbj1
   79 1.00000e+00 # cbj8
   80 1.00000e+00 # cQb1
   81 1.00000e+00 # cQb8
   82 1.00000e+00 # cjQtu1Re
   83 1.00000e+00 # cjQtu8Re
   84 1.00000e+00 # cjQbd1Re
   85 1.00000e+00 # cjQbd8Re
   86 1.00000e+00 # cjujd1Re
   87 1.00000e+00 # cjujd8Re
   88 1.00000e+00 # cjujd11Re
   89 1.00000e+00 # cjujd81Re
   90 1.00000e+00 # cQtjd1Re
   91 1.00000e+00 # cQtjd8Re
   92 1.00000e+00 # cjuQb1Re
   93 1.00000e+00 # cjuQb8Re
   94 1.00000e+00 # cQujb1Re
   95 1.00000e+00 # cQujb8Re
   96 1.00000e+00 # cjtQd1Re
   97 1.00000e+00 # cjtQd8Re
   98 1.00000e+00 # cQtQb1Re
   99 1.00000e+00 # cQtQb8Re
  100 1.00000e+00 # ceHRe
  101 1.00000e+00 # ceWRe
  102 1.00000e+00 # ceBRe
  103 1.00000e+00 # cHl1
  104 1.00000e+00 # cHl3
  105 1.00000e+00 # cHe
  106 1.00000e+00 # cll
  107 1.00000e+00 # cll1
  108 1.00000e+00 # clj1
  109 1.00000e+00 # clj3
  110 1.00000e+00 # cQl1
  111 1.00000e+00 # cQl3
  112 1.00000e+00 # cee
  113 1.00000e+00 # ceu
  114 1.00000e+00 # cte
  115 1.00000e+00 # ced
  116 1.00000e+00 # cbe
  117 1.00000e+00 # cje
  118 1.00000e+00 # cQe
  119 1.00000e+00 # clu
  120 1.00000e+00 # ctl
  121 1.00000e+00 # cld
  122 1.00000e+00 # cbl
  123 1.00000e+00 # cle
  124 1.00000e+00 # cledjRe
  125 1.00000e+00 # clebQRe
  126 1.00000e+00 # cleju1Re
  127 1.00000e+00 # cleQt1Re
  128 1.00000e+00 # cleju3Re
  129 1.00000e+00 # cleQt3Re

###################################
## INFORMATION FOR SMEFTCPV
###################################
Block smeftcpv
    1 1.000000e+00 # cGtil
    2 1.000000e+00 # cWtil
    3 1.000000e+00 # cHGtil
    4 1.000000e+00 # cHWtil
    5 1.000000e+00 # cHBtil
    6 1.000000e+00 # cHWBtil
    7 1.000000e+00 # cuGIm
    8 1.000000e+00 # ctGIm
    9 1.000000e+00 # cuWIm
   10 1.000000e+00 # ctWIm
   11 1.000000e+00 # cuBIm
   12 1.000000e+00 # ctBIm
   13 1.000000e+00 # cdGIm
   14 1.000000e+00 # cbGIm
   15 1.000000e+00 # cdWIm
   16 1.000000e+00 # cbWIm
   17 1.000000e+00 # cdBIm
   18 1.000000e+00 # cbBIm
   19 1.000000e+00 # cuHIm
   20 1.000000e+00 # ctHIm
   21 1.000000e+00 # cdHIm
   22 1.000000e+00 # cbHIm
   23 1.000000e+00 # cHudIm
   24 1.000000e+00 # cHtbIm
   25 1.000000e+00 # cutbd1Im
   26 1.000000e+00 # cutbd8Im
   27 1.000000e+00 # cjQtu1Im
   28 1.000000e+00 # cjQtu8Im
   29 1.000000e+00 # cjQbd1Im
   30 1.000000e+00 # cjQbd8Im
   31 1.000000e+00 # cjujd1Im
   32 1.000000e+00 # cjujd8Im
   33 1.000000e+00 # cjujd11Im
   34 1.000000e+00 # cjujd81Im
   35 1.000000e+00 # cQtjd1Im
   36 1.000000e+00 # cQtjd8Im
   37 1.000000e+00 # cjuQb1Im
   38 1.000000e+00 # cjuQb8Im
   39 1.000000e+00 # cQujb1Im
   40 1.000000e+00 # cQujb8Im
   41 1.000000e+00 # cjtQd1Im
   42 1.000000e+00 # cjtQd8Im
   43 1.000000e+00 # cQtQb1Im
   44 1.000000e+00 # cQtQb8Im
   45 1.000000e+00 # ceHIm
   46 1.000000e+00 # ceWIm
   47 1.000000e+00 # ceBIm
   48 1.000000e+00 # cledjIm
   49 1.000000e+00 # clebQIm
   50 1.000000e+00 # cleju1Im
   51 1.000000e+00 # cleju3Im
   52 1.000000e+00 # cleQt1Im
   53 1.000000e+00 # cleQt3Im

###################################
## INFORMATION FOR SMEFTCUTOFF
###################################
Block smeftcutoff
    1 1.000000e+03 # LambdaSMEFT

###################################
## INFORMATION FOR SMINPUTS
###################################
Block sminputs
    1 8.038700e+01 # MW
    2 1.166379e-05 # Gf
    3 1.179000e-01 # aS (Note that Parameter not used if you use a PDF set)

###################################
## INFORMATION FOR SWITCHES
###################################
Block switches
    1 0.000000e+00 # linearPropCorrections

###################################
## INFORMATION FOR YUKAWA
###################################
Block yukawa
    1 4.670000e-03 # ymdo
    2 2.160000e-03 # ymup
    3 9.300000e-02 # yms
    4 1.270000e+00 # ymc
    5 4.180000e+00 # ymb
    6 1.727600e+02 # ymt
   11 5.110000e-04 # yme
   13 1.056600e-01 # ymm
   15 1.777000e+00 # ymtau

###################################
## INFORMATION FOR DECAY
###################################
DECAY   6 1.330000e+00 # WT
DECAY  23 2.495200e+00 # WZ
DECAY  24 2.085000e+00 # WW
DECAY  25 4.070000e-03 # WH
## Dependent parameters, given by model restrictions.
## Those values should be edited following the
## analytical expression. MG5 ignores those values
## but they are important for interfacing the output of MG5
## to external program such as Pythia.
DECAY  1 0.000000e+00 # d : 0.0
DECAY  2 0.000000e+00 # u : 0.0
DECAY  3 0.000000e+00 # s : 0.0
DECAY  4 0.000000e+00 # c : 0.0
DECAY  5 0.000000e+00 # b : 0.0
DECAY  11 0.000000e+00 # e- : 0.0
DECAY  12 0.000000e+00 # ve : 0.0
DECAY  13 0.000000e+00 # mu- : 0.0
DECAY  14 0.000000e+00 # vm : 0.0
DECAY  15 0.000000e+00 # ta- : 0.0
DECAY  16 0.000000e+00 # vt : 0.0
DECAY  21 0.000000e+00 # g : 0.0
DECAY  22 0.000000e+00 # a : 0.0
DECAY  9000005 2.495200e+00 # z1 : WZ
DECAY  9000006 2.085000e+00 # w1+ : WW
DECAY  9000007 1.330000e+00 # t1 : WT
DECAY  9000008 4.070000e-03 # h1 : WH
#===========================================================
# QUANTUM NUMBERS OF NEW STATE(S) (NON SM PDG CODE)
#===========================================================

Block QNUMBERS 9000005  # z1
        1 0  # 3 times electric charge
        2 3  # number of spin states (2S+1)
        3 1  # colour rep (1: singlet, 3: triplet, 8: octet)
        4 0  # Particle/Antiparticle distinction (0=own anti)
Block QNUMBERS 9000006  # w1+
        1 3  # 3 times electric charge
        2 3  # number of spin states (2S+1)
        3 1  # colour rep (1: singlet, 3: triplet, 8: octet)
        4 1  # Particle/Antiparticle distinction (0=own anti)
Block QNUMBERS 9000007  # t1
        1 2  # 3 times electric charge
        2 2  # number of spin states (2S+1)
        3 3  # colour rep (1: singlet, 3: triplet, 8: octet)
        4 1  # Particle/Antiparticle distinction (0=own anti)
Block QNUMBERS 9000008  # h1
        1 0  # 3 times electric charge
        2 1  # number of spin states (2S+1)
        3 1  # colour rep (1: singlet, 3: triplet, 8: octet)
        4 0  # Particle/Antiparticle distinction (0=own anti)
EOF

# Initialize run_card
cat << 'EOF' > "$RUN_CARD"
#*********************************************************************
#                       MadGraph5_aMC@NLO                            *
#                                                                    *
#                     run_card.dat MadEvent                          *
#                                                                    *
#  This file is used to set the parameters of the run.               *
#                                                                    *
#  Some notation/conventions:                                        *
#                                                                    *
#   Lines starting with a '# ' are info or comments                  *
#                                                                    *
#   mind the format:   value    = variable     ! comment             *
#*********************************************************************
#
#******************* # Running parameters
#******************* #
#*********************************************************************
# Tag name for the run (one word)                                    *
#*********************************************************************
  tag_1     = run_tag ! name of the run
#*********************************************************************
# Run to generate the grid pack                                      *
#*********************************************************************
  .false.     = gridpack  !True = setting up the grid pack
#*********************************************************************
# Number of events and rnd seed                                      *
# Warning: Do not generate more than 1M events in a single run       *
# If you want to run Pythia, avoid more than 50k events in a run.    *
#*********************************************************************
  15000 = nevents ! Number of unweighted events requested
      0       = iseed   ! rnd seed (0=assigned automatically=default))
#*********************************************************************
# Collider type and energy                                           *
# lpp: 0=No PDF, 1=proton, -1=antiproton, 2=photon from proton,      *
#                                         3=photon from electron     *
#*********************************************************************
        1     = lpp1    ! beam 1 type
        1     = lpp2    ! beam 2 type
     6800     = ebeam1  ! beam 1 total energy in GeV
     6800     = ebeam2  ! beam 2 total energy in GeV
#*********************************************************************
# Beam polarization from -100 (left-handed) to 100 (right-handed)    *
#*********************************************************************
        0     = polbeam1 ! beam polarization for beam 1
        0     = polbeam2 ! beam polarization for beam 2
#*********************************************************************
# PDF CHOICE: this automatically fixes also alpha_s and its evol.    *
#*********************************************************************
 nn23lo1    = pdlabel     ! PDF set
230000 = lhaid
#*********************************************************************
# Renormalization and factorization scales                           *
#*********************************************************************
 F        = fixed_ren_scale  ! if .true. use fixed ren scale
 F        = fixed_fac_scale  ! if .true. use fixed fac scale
 91.1880  = scale            ! fixed ren scale
 91.1880  = dsqrt_q2fact1    ! fixed fact scale for pdf1
 91.1880  = dsqrt_q2fact2    ! fixed fact scale for pdf2
 1        = scalefact        ! scale factor for event-by-event scales
#*********************************************************************
# Matching - Warning! ickkw > 1 is still beta
#*********************************************************************
 0        = ickkw            ! 0 no matching, 1 MLM, 2 CKKW matching
 1        = alpsfact         ! scale factor for QCD emission vx
 F        = chcluster        ! cluster only according to channel diag
 5        = asrwgtflavor     ! highest quark flavor for a_s reweight
 T        = clusinfo         ! include clustering tag in output
 3.0      = lhe_version       ! Change the way clustering information pass to shower.
#*********************************************************************
#**********************************************************
#
#**********************************************************
# Automatic ptj and mjj cuts if xqcut > 0
# (turn off for VBF and single top processes)
#**********************************************************
   T  = auto_ptj_mjj  ! Automatic setting of ptj and mjj
#**********************************************************
#
#**********************************
# BW cutoff (M+/-bwcutoff*Gamma)
#**********************************
  15  = bwcutoff      ! (M+/-bwcutoff*Gamma)
#**********************************************************
# Apply pt/E/eta/dr/mij cuts on decay products or not
# (note that etmiss/ptll/ptheavy/ht/sorted cuts always apply)
#**********************************************************
   T  = cut_decays    ! Cut decay products
#*************************************************************
# Number of helicities to sum per event (0 = all helicities)
# 0 gives more stable result, but longer run time (needed for
# long decay chains e.g.).
# Use >=2 if most helicities contribute, e.g. pure QCD.
#*************************************************************
   0  = nhel          ! Number of helicities used per event
#******************* # Standard Cuts
#******************* #
#*********************************************************************
# Minimum and maximum pt's (for max, -1 means no cut)                *
#*********************************************************************
  10 = ptj       ! minimum pt for the jets
  0  = ptb       ! minimum pt for the b
  0  = pta       ! minimum pt for the photons
  0  = ptl       ! minimum pt for the charged leptons
  0  = misset    ! minimum missing Et (sum of neutrino's momenta)
  0  = ptheavy   ! minimum pt for one heavy final state
 -1  = ptjmax    ! maximum pt for the jets
 -1  = ptbmax    ! maximum pt for the b
 -1  = ptamax    ! maximum pt for the photons
 -1  = ptlmax    ! maximum pt for the charged leptons
 -1  = missetmax ! maximum missing Et (sum of neutrino's momenta)
#*********************************************************************
# Minimum and maximum E's (in the center of mass frame)              *
#*********************************************************************
  0  = ej     ! minimum E for the jets
  0  = eb     ! minimum E for the b
  0  = ea     ! minimum E for the photons
  0  = el     ! minimum E for the charged leptons
 -1   = ejmax ! maximum E for the jets
 -1   = ebmax ! maximum E for the b
 -1   = eamax ! maximum E for the photons
 -1   = elmax ! maximum E for the charged leptons
#*********************************************************************
# Maximum and minimum absolute rapidity (for max, -1 means no cut)   *
#*********************************************************************
  -1  = etaj    ! max rap for the jets
  -1  = etab    ! max rap for the b
  -1  = etaa    ! max rap for the photons
  5.0 = etal    ! max rap for the charged leptons
   0  = etajmin ! min rap for the jets
   0  = etabmin ! min rap for the b
   0  = etaamin ! min rap for the photons
   0  = etalmin ! main rap for the charged leptons
#*********************************************************************
# Minimum and maximum DeltaR distance                                *
#*********************************************************************
 0   = drjj    ! min distance between jets
 0   = drbb    ! min distance between b's
 0   = drll    ! min distance between leptons
 0   = draa    ! min distance between gammas
 0   = drbj    ! min distance between b and jet
 0   = draj    ! min distance between gamma and jet
 0   = drjl    ! min distance between jet and lepton
 0   = drab    ! min distance between gamma and b
 0   = drbl    ! min distance between b and lepton
 0   = dral    ! min distance between gamma and lepton
 -1  = drjjmax ! max distance between jets
 -1  = drbbmax ! max distance between b's
 -1  = drllmax ! max distance between leptons
 -1  = draamax ! max distance between gammas
 -1  = drbjmax ! max distance between b and jet
 -1  = drajmax ! max distance between gamma and jet
 -1  = drjlmax ! max distance between jet and lepton
 -1  = drabmax ! max distance between gamma and b
 -1  = drblmax ! max distance between b and lepton
 -1  = dralmax ! maxdistance between gamma and lepton
#*********************************************************************
# Minimum and maximum invariant mass for pairs                       *
# WARNING: for four lepton final state mmll cut require to have      *
#          different lepton masses for each flavor!                  * #*********************************************************************
 0   = mmjj    ! min invariant mass of a jet pair
 0   = mmbb    ! min invariant mass of a b pair
 0   = mmaa    ! min invariant mass of gamma gamma pair
 0   = mmll    ! min invariant mass of l+l- (same flavour) lepton pair
 -1  = mmjjmax ! max invariant mass of a jet pair
 -1  = mmbbmax ! max invariant mass of a b pair
 -1  = mmaamax ! max invariant mass of gamma gamma pair
 -1  = mmllmax ! max invariant mass of l+l- (same flavour) lepton pair
#*********************************************************************
# Minimum and maximum invariant mass for all letpons                 *
#*********************************************************************
  0  = mmnl    ! min invariant mass for all letpons (l+- and vl)
 -1  = mmnlmax ! max invariant mass for all letpons (l+- and vl)
#*********************************************************************
# Minimum and maximum pt for 4-momenta sum of leptons                *
#*********************************************************************
 0   = ptllmin  ! Minimum pt for 4-momenta sum of leptons(l and vl)
 -1  = ptllmax  ! Maximum pt for 4-momenta sum of leptons(l and vl)
#*********************************************************************
# Inclusive cuts                                                     *
#*********************************************************************
 0  = xptj ! minimum pt for at least one jet
 0  = xptb ! minimum pt for at least one b
 0  = xpta ! minimum pt for at least one photon
 0  = xptl ! minimum pt for at least one charged lepton
#*********************************************************************
# Control the pt's of the jets sorted by pt                          *
#*********************************************************************
 0   = ptj1min ! minimum pt for the leading jet in pt
 0   = ptj2min ! minimum pt for the second jet in pt
 0   = ptj3min ! minimum pt for the third jet in pt
 0   = ptj4min ! minimum pt for the fourth jet in pt
 -1  = ptj1max ! maximum pt for the leading jet in pt
 -1  = ptj2max ! maximum pt for the second jet in pt
 -1  = ptj3max ! maximum pt for the third jet in pt
 -1  = ptj4max ! maximum pt for the fourth jet in pt
 0   = cutuse  ! reject event if fails any (0) / all (1) jet pt cuts
#*********************************************************************
# Control the pt's of leptons sorted by pt                           *
#*********************************************************************
 0   = ptl1min ! minimum pt for the leading lepton in pt
 0   = ptl2min ! minimum pt for the second lepton in pt
 0   = ptl3min ! minimum pt for the third lepton in pt
 0   = ptl4min ! minimum pt for the fourth lepton in pt
 -1  = ptl1max ! maximum pt for the leading lepton in pt
 -1  = ptl2max ! maximum pt for the second lepton in pt
 -1  = ptl3max ! maximum pt for the third lepton in pt
 -1  = ptl4max ! maximum pt for the fourth lepton in pt
#*********************************************************************
# Control the Ht(k)=Sum of k leading jets                            *
#*********************************************************************
 0   = htjmin ! minimum jet HT=Sum(jet pt)
 -1  = htjmax ! maximum jet HT=Sum(jet pt)
 0   = ihtmin  !inclusive Ht for all partons (including b)
 -1  = ihtmax  !inclusive Ht for all partons (including b)
 0   = ht2min ! minimum Ht for the two leading jets
 0   = ht3min ! minimum Ht for the three leading jets
 0   = ht4min ! minimum Ht for the four leading jets
 -1  = ht2max ! maximum Ht for the two leading jets
 -1  = ht3max ! maximum Ht for the three leading jets
 -1  = ht4max ! maximum Ht for the four leading jets
#***********************************************************************
# Photon-isolation cuts, according to hep-ph/9801442                   *
# When ptgmin=0, all the other parameters are ignored                  *
# When ptgmin>0, pta and draj are not going to be used                 *
#***********************************************************************
   0 = ptgmin ! Min photon transverse momentum
 0.4 = R0gamma ! Radius of isolation code
 1.0 = xn ! n parameter of eq.(3.4) in hep-ph/9801442
 1.0 = epsgamma ! epsilon_gamma parameter of eq.(3.4) in hep-ph/9801442
 .true. = isoEM ! isolate photons from EM energy (photons and leptons)
#*********************************************************************
# WBF cuts                                                           *
#*********************************************************************
 0   = xetamin ! minimum rapidity for two jets in the WBF case
 0   = deltaeta ! minimum rapidity for two jets in the WBF case
#*********************************************************************
# KT DURHAM CUT                                                      *
#*********************************************************************
 -1    =  ktdurham
 0.4  =  dparameter
#*********************************************************************
# maximal pdg code for quark to be considered as a light jet         *
# (otherwise b cuts are applied)                                     *
#*********************************************************************
 5 = maxjetflavor    ! Maximum jet pdg code
#*********************************************************************
# Jet measure cuts                                                   *
#*********************************************************************
 0  = xqcut   ! minimum kt jet measure between partons
#*********************************************************************
#
#*********************************************************************
# Store info for systematics studies                                 *
# WARNING: If use_syst is T, matched Pythia output is                *
#          meaningful ONLY if plotted taking matchscale              *
#          reweighting into account!                                 *
#*********************************************************************
   F  = use_syst      ! Enable systematics studies
EOF

# Initialize extramodels.dat
echo "SMEFTsim_topU3l_MwScheme_UFO.tar.gz" > "${CARDS_DIR}/extramodels.dat"

# Save a copy of the patch to the cards directory for bundling
cp ../smeft_fix.patch "${CARDS_DIR}/fix_model.patch"

# Initialize reweight_card.dat dynamically
cat << EOF > "${CARDS_DIR}/reweight_card.dat"
change rwgt_dir rwgt
change process    ${primary_proc}        NPprop=0 SMHLOOP=0 NP=1
EOF

for ap in "${ADDITIONAL_PROCS[@]}"; do
    echo "change process    ${ap}        NPprop=0 SMHLOOP=0 NP=1 --add" >> "${CARDS_DIR}/reweight_card.dat"
done

# Append the rest of the reweight parameters
cat << 'EOF' >> "${CARDS_DIR}/reweight_card.dat"

launch --rwgt_name=MJEFT
set cG 1.0000e-50
set cW 1.0000e-50
set cH 1.0000e-50
set cHbox 1.0000e-50
set cHDD 1.0000e-50
set cHG 1.0000e-50
set cHW 1.0000e-50
set cHB 1.0000e-50
set cHWB 1.0000e-50
set cuHRe 1.0000e-50
set ctHRe 1.0000e-50
set cdHRe 1.0000e-50
set cbHRe 1.0000e-50
set cuGRe 1.0000e-50
set ctGRe 1.0000e-50
set cuWRe 1.0000e-50
set ctWRe 1.0000e-50
set cuBRe 1.0000e-50
set ctBRe 1.0000e-50
set cdGRe 1.0000e-50
set cbGRe 1.0000e-50
set cdWRe 1.0000e-50
set cbWRe 1.0000e-50
set cdBRe 1.0000e-50
set cbBRe 1.0000e-50
set cHj1 1.0000e-50
set cHQ1 1.0000e-50
set cHj3 1.0000e-50
set cHQ3 1.0000e-50
set cHu 1.0000e-50
set cHt 1.0000e-50
set cHd 1.0000e-50
set cHbq 1.0000e-50
set cHudRe 1.0000e-50
set cHtbRe 1.0000e-50
set cjj11 1.0000e-50
set cjj18 1.0000e-50
set cjj31 1.0000e-50
set cjj38 1.0000e-50
set cQj11 1.0000e-50
set cQj18 1.0000e-50
set cQj31 1.0000e-50
set cQj38 1.0000e-50
set cQQ1 1.0000e-50
set cQQ8 1.0000e-50
set cuu1 1.0000e-50
set cuu8 1.0000e-50
set ctt 1.0000e-50
set ctu1 1.0000e-50
set ctu8 1.0000e-50
set cdd1 1.0000e-50
set cdd8 1.0000e-50
set cbb 1.0000e-50
set cbd1 1.0000e-50
set cbd8 1.0000e-50
set cud1 1.0000e-50
set ctb1 1.0000e-50
set ctd1 1.0000e-50
set cbu1 1.0000e-50
set cud8 1.0000e-50
set ctb8 1.0000e-50
set ctd8 1.0000e-50
set cbu8 1.0000e-50
set cutbd1Re 1.0000e-50
set cutbd8Re 1.0000e-50
set cju1 1.0000e-50
set cQu1 1.0000e-50
set cju8 1.0000e-50
set cQu8 1.0000e-50
set ctj1 1.0000e-50
set ctj8 1.0000e-50
set cQt1 1.0000e-50
set cQt8 1.0000e-50
set cjd1 1.0000e-50
set cjd8 1.0000e-50
set cQd1 1.0000e-50
set cQd8 1.0000e-50
set cbj1 1.0000e-50
set cbj8 1.0000e-50
set cQb1 1.0000e-50
set cQb8 1.0000e-50
set cjQtu1Re 1.0000e-50
set cjQtu8Re 1.0000e-50
set cjQbd1Re 1.0000e-50
set cjQbd8Re 1.0000e-50
set cjujd1Re 1.0000e-50
set cjujd8Re 1.0000e-50
set cjujd11Re 1.0000e-50
set cjujd81Re 1.0000e-50
set cQtjd1Re 1.0000e-50
set cQtjd8Re 1.0000e-50
set cjuQb1Re 1.0000e-50
set cjuQb8Re 1.0000e-50
set cQujb1Re 1.0000e-50
set cQujb8Re 1.0000e-50
set cjtQd1Re 1.0000e-50
set cjtQd8Re 1.0000e-50
set cQtQb1Re 1.0000e-50
set cQtQb8Re 1.0000e-50
set ceHRe 1.0000e-50
set ceWRe 1.0000e-50
set ceBRe 1.0000e-50
set cHl1 1.0000e-50
set cHl3 1.0000e-50
set cHe 1.0000e-50
set cll 1.0000e-50
set cll1 1.0000e-50
set clj1 1.0000e-50
set clj3 1.0000e-50
set cQl1 1.0000e-50
set cQl3 1.0000e-50
set cee 1.0000e-50
set ceu 1.0000e-50
set cte 1.0000e-50
set ced 1.0000e-50
set cbe 1.0000e-50
set cje 1.0000e-50
set cQe 1.0000e-50
set clu 1.0000e-50
set ctl 1.0000e-50
set cld 1.0000e-50
set cbl 1.0000e-50
set cle 1.0000e-50
set cledjRe 1.0000e-50
set clebQRe 1.0000e-50
set cleju1Re 1.0000e-50
set cleQt1Re 1.0000e-50
set cleju3Re 1.0000e-50
set cleQt3Re 1.0000e-50
set cGtil 1.0000e-50
set cWtil 1.0000e-50
set cHGtil 1.0000e-50
set cHWtil 1.0000e-50
set cHBtil 1.0000e-50
set cHWBtil 1.0000e-50
set cuGIm 1.0000e-50
set ctGIm 1.0000e-50
set cuWIm 1.0000e-50
set ctWIm 1.0000e-50
set cuBIm 1.0000e-50
set ctBIm 1.0000e-50
set cdGIm 1.0000e-50
set cbGIm 1.0000e-50
set cdWIm 1.0000e-50
set cbWIm 1.0000e-50
set cdBIm 1.0000e-50
set cbBIm 1.0000e-50
set cuHIm 1.0000e-50
set ctHIm 1.0000e-50
set cdHIm 1.0000e-50
set cbHIm 1.0000e-50
set cHudIm 1.0000e-50
set cHtbIm 1.0000e-50
set cutbd1Im 1.0000e-50
set cutbd8Im 1.0000e-50
set cjQtu1Im 1.0000e-50
set cjQtu8Im 1.0000e-50
set cjQbd1Im 1.0000e-50
set cjQbd8Im 1.0000e-50
set cjujd1Im 1.0000e-50
set cjujd8Im 1.0000e-50
set cjujd11Im 1.0000e-50
set cjujd81Im 1.0000e-50
set cQtjd1Im 1.0000e-50
set cQtjd8Im 1.0000e-50
set cjuQb1Im 1.0000e-50
set cjuQb8Im 1.0000e-50
set cQujb1Im 1.0000e-50
set cQujb8Im 1.0000e-50
set cjtQd1Im 1.0000e-50
set cjtQd8Im 1.0000e-50
set cQtQb1Im 1.0000e-50
set cQtQb8Im 1.0000e-50
set ceHIm 1.0000e-50
set ceWIm 1.0000e-50
set ceBIm 1.0000e-50
set cledjIm 1.0000e-50
set clebQIm 1.0000e-50
set cleju1Im 1.0000e-50
set cleju3Im 1.0000e-50
set cleQt1Im 1.0000e-50
set cleQt3Im 1.0000e-50
EOF

echo ""
echo "======================================================"
echo " Setup complete!"
echo "======================================================"
echo " - Your execution card is at: $PROC_CARD"
echo " - Your configuration cards are stored in: $CARDS_DIR/"
echo ""
echo "CRITICAL: Ensure you open and verify the contents of ${CARDS_DIR}/run_card.dat before passing $PROC_CARD into MG5."
echo "======================================================"
