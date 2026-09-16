# MadJax Tutorial
## Step 1: Find the initial sampling point (run madgraph 183 times)
This is mostly straightforward now.

```bash
mkdir tutorialMadJax
cd tutorialMadJax
# Set this to your current working directory
export TUTORIAL_BASE=$PWD
```

```bash
git clone git@github.com:jsamudio/cmseft.git --branch feature/EFTcoef

cd ${TUTORIAL_BASE}/cmseft/generation
cmssw-el8 # or el7 with some modifications to the setup script for Run 2
. setup.sh # Do this early because it takes time

cd samplePoint
. setup_mg5_samplingPoint.sh
# This will give a few prompts with what process you want. For example, type: p p > t t~

# To run, we should be in the MG5_aMC_v2_9_18/ directory
#cd MG5_aMC_v2_9_18
python2.7 ./bin/mg5_aMC proc_card.dat &> ttbar.log 
# This may take a while depending on the process, it is running 183 times.
# If you want to chop up the proc card and run on multiple machines, that is fine, just keep track.
# By this I mean, have multiple proc cards with n number of generate lines and submit each one as a job with its own log file to a batch system.

# Prep the cards
python3 prep_cards.py --log ttbar.log --cards-dir ttbar_cards/ --proc-card proc_card.dat --name ttbar_mj
```

For the tutorial, I have included a complete set of cards in `cmseft/generation/ttbar_mj` since this step can take a while.

**Add the model** `SMEFTsim_topU3l_MwScheme`
```bash
cd ${TUTORIAL_BASE}/cmseft/generation/genproductions/bin/MadGraph5_aMCatNLO/
mkdir -pv addons/models/
cd addons/models/
wget https://feynrules.irmp.ucl.ac.be/raw-attachment/wiki/SMEFT/SMEFTsim_topU3l_MwScheme_UFO.tar.gz
tar -xvzf SMEFTsim_topU3l_MwScheme_UFO.tar.gz
cd SMEFTsim_topU3l_MwScheme_UFO

# Copy the generated cards into the model directory for gridpack generation
cp -r ${TUTORIAL_BASE}/cmseft/generation/ttbar_mj .
```


## Step 2: Make the initial gridpack

You will also need to **clone `madjax` in another directory**. 

```bash
cd ${TUTORIAL_BASE}
git clone --branch export_executable git@github.com:jsamudio/madjax.git
# OR #
# git clone --branch export_executable https://github.com/jsamudio/madjax
```
Then, you will need to **symlink the madjax plugin directory** into the right place **in your working directory**.
```bash
cd ${TUTORIAL_BASE}/cmseft/generation/genproductions/bin/MadGraph5_aMCatNLO/
mkdir -p PLUGIN 
cd PLUGIN

# Create the symlink using the absolute path variable
ln -s ${TUTORIAL_BASE}/madjax/src/madjax/mg5/madjax_me_gen madjax_me_gen
```


To **create the gridpack**, make sure you are in an `el8` environment, and run the following:
> If running interactively, it is recommended to do this inside a **tmux** session to ensure the process is not interrupted. To create a tmux session: `tmux new -s <your_session_name>`
```bash
cd ${TUTORIAL_BASE}/cmseft/generation/genproductions/bin/MadGraph5_aMCatNLO/
tmux new -s one
# cmssw-el8
eval `scram unsetenv -sh`
. gridpack_generation.sh ttbar_mj addons/models/SMEFTsim_topU3l_MwScheme_UFO/ttbar_mj
 ```
 
## Step 3: Compile reweight functions and repack

Start by generating a test set of events and the python ME code for MadJax
```bash
cd ${TUTORIAL_BASE}/cmseft/generation/genproductions/bin/MadGraph5_aMCatNLO/
mkdir compileTest

# Copy the necessary helper scripts and the newly generated tarball
cp prep.sh compileTest/
cp compile_payload.sh compileTest/
cp pbs_example.pbs compileTest/
cp repack.sh compileTest/
mv ttbar_mj_el8_amd64_gcc10_CMSSW_12_4_8_tarball.tar.xz compileTest/

cd compileTest/
# ensure el8 env
cmssw-el8
bash prep.sh ttbar_mj_el8_amd64_gcc10_CMSSW_12_4_8_tarball.tar.xz

cd ${TUTORIAL_BASE}/cmseft/generation/genproductions/bin/MadGraph5_aMCatNLO/compileTest
```

Then, compile the reweight functions on the batch system. The payload can be used on PBS or HTCondor.
In the PBS example, it only compiles the first two subprocesses, so the user should adjust this based on the physics process.
```
mkdir logs
qsub pbs_example.pbs
```

Once this is done, there should be compiled reweight functions in `process/madevent/reweight_functions`.
Then repack the gridpack.

```
bash repack.sh ttbar_mj_el8_amd64_gcc10_CMSSW_12_4_8_tarball.tar.xz
```

and the final gridpack can be used in the nanogen fragment.

## Nanogen for testing

An example script is available in the repo.

```bash
cd ${TUTORIAL_BASE}/cmseft/generation
# cmssw-el8
. setup.sh
cmsRun nanogen_matching.py ${TUTORIAL_BASE}/cmseft/generation/genproductions/bin/MadGraph5_aMCatNLO/compileTest/ttbar_mj_el8_amd64_gcc10_CMSSW_12_4_8_tarball.tar.xz 5000 123456
```

## Validate against a fixed sample
A sample validation script is included.

```bash
cd ${TUTORIAL_BASE}/cmseft/generation
# cmssw-el8
. setup_hist.sh
python3 closure.py
```
