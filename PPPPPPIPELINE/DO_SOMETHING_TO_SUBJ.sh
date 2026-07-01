#!/bin/bash
export PATH=/usr/local/bin:$PATH
# SET PATHS, DATA, PARAMETERS AND GLOBS
CURR_DIR=$(pwd)
PROJECT_DIR=/bml/projects/07_inference-clinical-trial/projects/07-09_ntsec-lego-fmri-connectivity
DERIVATIVES_DIR=${PROJECT_DIR}/data/derivatives
RAW_DIR=${PROJECT_DIR}/data/rawdata
#SEL_DATA_ARR=("o15")
DATA_ARR_FULLPATH=(${PROJECT_DIR}/data/sourcedata/*)
EPI_FILENAME_GLOB=*REST*
T1_FILENAME_GLOB=*T1*.nii
T2_FILENAME_GLOB=*T2*.nii
UNWANTED_FILENAME_GLOBS=("*REP*MoCo*.*")
STUDY_SPECIFIC_OTHER_CLEANUP_SCRIPT=${PROJECT_DIR}/code/routines/spm_pipeline_other_cleanup.sh
REALIGN_TO_MEAN=1 # 1: Register to first
SLICE_TIME_SLICE_ORDER="eval('[2:2:36,1:2:36]')"
SLICE_TIME_REF_SLICE=2 # If SLICE_TIME_SLICE_ORDER is in ms, then this is in ms.
SLICE_TIME_TIME_ACQUISITION="eval('2-(2/36)')" # If SLICE_TIME_SLICE_ORDER is in ms, then this is 0.
COREG_OTHER=0
SEGMENT_AFF_REG=mni # Alt: mni | eastern | subj | none | 0 
NORM_RESAMPLING=3,3,3 #######################?
SMOOTH_KERNEL=8,8,8 #######################?
rc_GLOBS=("rc1" "rc2" "rc3" "rc4" "rc5" "rc6")
LVL1_STATS_UNITS=secs
LVL1_STATS_TR=2
LVL1_STATS_MICROTIME_RES=36      ##########SLICE?
LVL1_STATS_MICROTIME_ONSET=2 	########DUA CHI DAIN?
LVL1_MASK_THRESH=0.8
LVL1_MASK=""
LVL1_STATS_RESIDUALS=0 # 1: Save, 0: Do not save 
LVL1_STATS_DELETE_CONS=1 # 1: Delete, 0: Do not delete 
STUDY_SPECIFIC_MAKE_LVL1_CON_LIST_SCRIPT=${PROJECT_DIR}/code/routines/spm_make_lvl1_con_lists.sh # Be sure to check this file
STUDY_SPECIFIC_MAKE_LVL2_SPEC_LIST_SCRIPT=${PROJECT_DIR}/code/routines/bash_make_lvl2_spec_lists.sh # Be sure to check this file
STUDY_SPECIFIC_MAKE_LVL2_CON_LIST_SCRIPT=${PROJECT_DIR}/code/routines/bash_make_lvl2_con_lists.sh # Be sure to check this file
GROUP_NAME=group
LVL2_STATS_RESIDUALS=0 # 1: Save, 0: Do not save
LVL2_STATS_DELETE_CONS=1 # 1: Delete, 0: Do not delete

# SELECT ROUTINES
SUBJ_LEVEL_PREPROC="yes"   	


# SUBJECT LEVEL PREPROCESSING
if [[ "$SUBJ_LEVEL_PREPROC" == "yes" ]]; then

	# Set DATA_ARR
	if [[ "${SEL_DATA_ARR[@]}" == "" ]]; then
		TEMP=( "${DATA_ARR_FULLPATH[@]##*/}" )
		DATA_ARR=( "${TEMP[@]%/}" )
	else
		DATA_ARR=( "${SEL_DATA_ARR[@]}" )
	fi

	# Loop through subject directories
	for subj in "${DATA_ARR[@]}"; do
		echo "Working on ${subj}"
#######################################################################################
		subj2=${subj/NTUSEC/s0} ######s0008
		ORIG_DIR=/bml/projects/07_inference-clinical-trial/projects/07-05_ntsec-lego-fmri/data/derivatives
		#/pre_test/s0008/func/
		# show_vol.sh ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/ar*.nii
		# show_vol.sh ${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/ar*.nii

		cp ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/roi1_HIP_R/sw*.nii ${DERIVATIVES_DIR}/ZMAP/8mm/roi1_HIP_R/ses01
		cp ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/roi1_HIP_R/sw*.nii ${DERIVATIVES_DIR}/ZMAP/8mm/roi1_HIP_R/ses02
/nii/ses02/roi/roi1_HIP_R/

		# cp ${DERIVATIVES_DIR}/ZMAP/8mm/roi1_HIP_R/ses02/swZMAP_FIN_${subj}ROI1.nii ${DERIVATIVES_DIR}/ZMAP/8mm/roi1_HIP_R/ses02/swZMAP_FIN_${subj}ROI2.nii
		# mv ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/roi1_HIP_R/ZMAP_FIN_${subj}ROI1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/roi1_HIP_R/ZMAP_FIN_${subj}ROI1.nii
		mv ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/roi1_HIP_R/ZMAP_FIN_${subj}ROI2 ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/roi1_HIP_R/ZMAP_FIN_${subj}ROI2.nii
#######################################################################################
		echo "${subj} preprocessing done."
	done	
fi

cd ${CURR_DIR}
echo "Done!"
