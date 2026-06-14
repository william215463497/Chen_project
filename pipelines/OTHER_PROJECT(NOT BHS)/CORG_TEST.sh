#!/bin/bash

# SET PATHS, DATA, PARAMETERS AND GLOBS
CURR_DIR=$(pwd)
PROJECT_DIR=/bml/projects/07_inference-clinical-trial/projects/07-09_ntsec-lego-fmri-connectivity
DERIVATIVES_DIR=${PROJECT_DIR}/data/derivatives
RAW_DIR=${PROJECT_DIR}/data/rawdata
SEL_DATA_ARR=("NTUSEC008")
DATA_ARR_FULLPATH=(${PROJECT_DIR}/data/sourcedata/*)
EPI_FILENAME_GLOB=*VRIT*
T1_FILENAME_GLOB=*T1*.nii
T2_FILENAME_GLOB=*T2*.nii
UNWANTED_FILENAME_GLOBS=("*REP*MoCo*.*")
STUDY_SPECIFIC_OTHER_CLEANUP_SCRIPT=${PROJECT_DIR}/code/pipelines/specs/spm_pipeline_other_cleanup.sh
EPI_TR=2
#NVOLS_RUN=("150" "150")
REALIGN_TO_MEAN=0 #Register to mean, 0: register to first, 1: register to mean
REALIGN_PARAMS_GLOB=rp*.txt
SLICE_TIME_SLICE_ORDER="eval('[2:2:36,1:2:36]')"
SLICE_TIME_REF_SLICE=2 # If SLICE_TIME_SLICE_ORDER is in ms, then this is in ms.
SLICE_TIME_TIME_ACQUISITION=1.944
SLICE_TO_SLICE="eval('tr/nslices')"
#COREG_OTHER=0
SEGMENT_AFF_REG=mni # Alt: mni | eastern | subj | none | 0 
DENOISE_MASK_THRESHOLD=0.95
DENOISE_CENSOR_METHOD=none # Alt: None | FD
DENOISE_CENSOR_THRESHOLD=0.5 # If FD, 0.5 mm
NORM_RESAMPLING=3,3,3
SMOOTH_KERNEL=8,8,8
rc_GLOBS=("rc1" "rc2" "rc3" "rc4" "rc5" "rc6")
#LVL1_EPI_INPUT_PREFIX=swar
LVL1_EPI_INPUT_PREFIX=ar
LVL1_DENOISE_PARAMS_GLOB=multiple_regressors_epi*.txt
LVL1_STATS_UNITS=secs
LVL1_STATS_MICROTIME_RES=32
LVL1_STATS_MICROTIME_ONSET=2
LVL1_MASK_THRESH=0.8
LVL1_MASK=""
LVL1_STATS_DELETE_CONS=1 # 1: Delete, 0: Do not delete 
LVL1_STATS_RESIDUALS=1 # 1: Save, 0: Do not save
LVL1_RESIDUALS_FILENAME_PREFIX=Res_
LVL1_RESIDUALS_LOW_F=0.01
LVL1_RESIDUALS_HIGH_F=0.1
STUDY_SPECIFIC_MAKE_LVL1_CON_LIST_SCRIPT=/home/william_chen/bin/spm_make_lvl1_con_lists.sh # Be sure to check this file
STUDY_SPECIFIC_MAKE_REST_LVL1_CON_LIST_SCRIPT=/home/william_chen/bin/spm_make_lvl1_con_lists.sh # Be sure to check this file
STUDY_SPECIFIC_MAKE_LVL2_SPEC_LIST_SCRIPT=/home/william_chen/bin/bash_make_spm_lvl2_spec_lists.sh # Be sure to check this file
STUDY_SPECIFIC_MAKE_LVL2_CON_LIST_SCRIPT=/home/william_chen/bin/bash_make_spm_lvl2_con_lists.sh # Be sure to check this file
GROUP_NAME=group
LVL2_STATS_RESIDUALS=0 # 1: Save, 0: Do not save
LVL2_STATS_DELETE_CONS=1 # 1: Delete, 0: Do not delete

# SELECT ROUTINES
SUBJ_LEVEL_PREPROC="yes"
DICOM2NII="no"
DICOM2NII_T1T2="no"
COPY_RAW2DERIVATIVES="no"
FILE_CLEANUP="no"
INHOMOGENEITY_CORRECTION="no"
REALIGN_RESLICE="no"
SLICE_TIME_CORRECTION="no"
COREG_EPI_T1="yes"
COREG_T1_T2="no"
SEGMENT_T1="no"
DENOISE_EPI="no"
NORMALISE_EPI_MNI="no"
SMOOTH_EPI="no"


# Initiate derivatives directory
mkdir -p ${DERIVATIVES_DIR}

# SUBJECT LEVEL PREPROCESSING
if [[ "$SUBJ_LEVEL_PREPROC" == "yes" ]]; then

	# Set DATA_ARR
	if [[ "${SEL_DATA_ARR[@]}" == "" ]]; then
		TEMP=( "${DATA_ARR_FULLPATH[@]##*/}" )
		DATA_ARR=( "${TEMP[@]%/}" )
		echo "DATA_ARR=${DATA_ARR}"
	else
		DATA_ARR=( "${SEL_DATA_ARR[@]}" )
		echo "DATA_ARR=${DATA_ARR}"
	fi

	# Loop through subject directories
	for subj in "${DATA_ARR[@]}"; do

		echo "Working on ${subj}"

		########20260131 WILLIAM CORAG EPI TO T2
		########20260429 WILLIAM CORAG EPI TO T1

		if [[ "${COREG_EPI_T1}" == "yes" ]]; then
			echo "Working on ${subj}EPI to T2 coregistration."
			arEPI_DATA_VOL=$(ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/ar*.nii | sed -n '1p')
			echo "arEPI_DATA_VOL : ${arEPI_DATA_VOL}"
			T2_DATA_VOL=$(ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T2/TZU_T2/s*T2.nii)	
			# COREG_OTHER=$(ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/ar*.nii | sed -n '2,260p')	

			# 2. 建立一個文字檔，專門存放第 2 到 260 個 Volume
			COREG_OTHER_TXT="${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/coreg_other_vols.txt" > "${COREG_OTHER_TXT}" # 先清空或建立新檔案

			# 使用迴圈寫入 file.nii,2 一直到 file.nii,260
			for i in {2..260}; do
				echo "${arEPI_DATA_VOL},${i}" >> "${COREG_OTHER_TXT}"
			done

			echo "COREG_OTHER_TXT 檔案已建立於: ${COREG_OTHER_TXT}"
			read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			# echo "COREG_OTHER = ${arEPI_DATA_VOL}"
			#ls -v1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/ar*.nii | sed -n '2,260p' > ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/coreg_other.txt
			read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			spm_coreg ${T2_DATA_VOL} ${arEPI_DATA_VOL} ${COREG_OTHER_TXT} ${subj}_spm_coreg_EPI-tzuT2 1	
			read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty			
			echo "SES01_${subj} EPI to T2 coregistration done."

			T2_DATA_VOL=$(ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/T2/TZU_T2/s*T2.nii)	
			arEPI_DATA_VOL=$(ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/ar*.nii | sed -n '1p')
			COREG_OTHER=$(ls -v1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/ar*.nii | sed -n '2,260p')	
			echo "arEPI_DATA_VOL : ${arEPI_DATA_VOL}"
			spm_coreg ${T2_DATA_VOL} ${arEPI_DATA_VOL} ${COREG_OTHER} ${subj}_spm_coreg_T2-EPI 1	
			echo "${subj} EPI to T2 coregistration done."
		fi
		
		# Coregister T1 to EPI-coregistered T2
		if [[ "${COREG_T1_T2}" == "yes" ]]; then
			echo "Working on ${subj} T1 to EPI-coregistered T2 coregistration."
			T1_DATA_VOL=$(ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/T1*.nii)
			T2_DATA_VOL=$(ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T2/T2*.nii)
			echo "T1_DATA_VOL: ${T1_DATA_VOL}, "
			echo "T2_DATA_VOL: ${T2_DATA_VOL}, "
			spm_coreg ${T2_DATA_VOL} ${T1_DATA_VOL} ${COREG_OTHER} ${subj}_spm_coreg_T1-T2 1
			echo "SES01_${subj} T1 to EPI-coregistered T2 coregistration done."
			T1_DATA_VOL=$(ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/T1*.nii)
			T2_DATA_VOL=$(ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/T2/T2*.nii)
			spm_coreg ${T2_DATA_VOL} ${T1_DATA_VOL} ${COREG_OTHER} ${subj}_spm_coreg_T1-T2 1
			echo "${subj} T1 to EPI-coregistered T2 coregistration done."
			#read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
		fi
		
		# Segment T2-EPI-coregistered T1
		if [[ "${SEGMENT_T1}" == "yes" ]]; then
			echo "Working on ${subj} T1 segmentation."
			T1_DATA_VOL=$(ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/TZU_T1/${T1_FILENAME_GLOB})
			echo "SES01_T1_DATA_VOL: ${T1_DATA_VOL} "			
			spm_segment ${T1_DATA_VOL} ${SEGMENT_AFF_REG} ${subj}_spm_segment 1
			echo "SES01_${subj} T1 segmentation done."

			T1_DATA_VOL=$(ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/TZU_T1/${T1_FILENAME_GLOB})
			echo "SES02_T1_DATA_VOL: ${T1_DATA_VOL} "			
			spm_segment ${T1_DATA_VOL} ${SEGMENT_AFF_REG} ${subj}_spm_segment 1			
			echo "SES02_${subj} T1 segmentation done."
		fi
		
		# Extract denoising physiological parameters (runs PhysIO module)
		if [[ "${DENOISE_EPI}" == "yes" ]]; then
			echo "Working on SES01 ${subj} EPI denoising parameter extraction. WHYYYYYYYYYYY"
			rm -rf ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/REG_LIST.txt
			rm -rf ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/EPI_DATA_LIST.txt
			#read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			WM_MASK=${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/TZU_T1/c2s*.nii
			CSF_MASK=${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/TZU_T1/c3s*.nii
			REG_LIST=${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/REG_LIST.txt
			EPI_DATA_LIST=${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/EPI_DATA_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/ar*.nii >> ${EPI_DATA_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/rp*.txt >> ${REG_LIST}
			echo "SLICE_TO_SLICE:${SLICE_TO_SLICE}"
			read -p "BEFORE   Enter 開始掃描..." < /dev/tty
			spm_denoise_physio ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01 ${EPI_DATA_LIST} ${EPI_TR} ${SLICE_TIME_REF_SLICE} ${SLICE_TO_SLICE} ${WM_MASK} ${CSF_MASK} ${DENOISE_MASK_THRESHOLD} ${REG_LIST} ${DENOISE_CENSOR_METHOD} ${DENOISE_CENSOR_THRESHOLD} ${subj}_spm_denoise_EPI
			read -p "AFTER   Enter 開始掃描..." < /dev/tty
			rm -rf ${REG_LIST}
			rm -rf ${EPI_DATA_LIST}	
			echo "SES01 ${subj} REST EPI denoising parameter extraction done."

			############################SES01-02####################

			echo "Working on SES02 ${subj} EPI denoising parameter extraction."
			# rm -rf ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/EPI_DATA_LIST.txt
			# rm -rf ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/REG_LIST.txt		
			WM_MASK=${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/c2s*.nii
			CSF_MASK=${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/c3s*.nii
			REG_LIST=${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/REG_LIST.txt
			EPI_DATA_LIST=${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/EPI_DATA_LIST.txt
			read -p "BEFORE   Enter 開始掃描..." < /dev/tty
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/ar*.nii >> ${EPI_DATA_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/rp*.txt >> ${REG_LIST}
			spm_denoise_physio ${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02 ${EPI_DATA_LIST} ${EPI_TR} ${SLICE_TIME_REF_SLICE} ${SLICE_TO_SLICE} ${WM_MASK} ${CSF_MASK} ${DENOISE_MASK_THRESHOLD} ${REG_LIST} ${DENOISE_CENSOR_METHOD} ${DENOISE_CENSOR_THRESHOLD} ${subj}_spm_denoise_EPI
			rm -rf ${REG_LIST}
			rm -rf ${EPI_DATA_LIST}		
			echo "SES02 ${subj} REST EPI denoising parameter extraction done."
			
		fi

		# Normalise EPI to MNI
		if [[ "${NORMALISE_EPI_MNI}" == "yes" ]]; then
			echo "Working on ${subj} EPI normalisation to MNI."
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ar${EPI_FILENAME_GLOB}.nii >> ${EPI_DATA_LIST}
			DEF_FIELD_VOL=$(ls -1 ${DERIVATIVES_DIR}/${subj}/nii/y_*.nii)
			spm_normalise_write ${EPI_DATA_LIST} ${DEF_FIELD_VOL} ${NORM_RESAMPLING} ${subj}_spm_normalise 1
			rm -rf ${EPI_DATA_LIST}
			echo "${subj} EPI normalisation to MNI done."
		fi

		# Smooth EPI
		if [[ "${SMOOTH_EPI}" == "yes" ]]; then
			echo "Working on ${subj} EPI spatial smoothing."
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/war${EPI_FILENAME_GLOB}.nii >> ${EPI_DATA_LIST}
			spm_smooth ${EPI_DATA_LIST} ${SMOOTH_KERNEL} ${subj}_spm_smooth 1
			rm -rf ${EPI_DATA_LIST}
			echo "${subj} EPI spatial smoothing done."
		fi

		echo "${subj} preprocessing done."
	done
fi

cd ${CURR_DIR}
echo "Done!"

