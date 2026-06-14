#!/bin/bash

# SET PATHS, DATA, PARAMETERS AND GLOBS
CURR_DIR=$(pwd)
PROJECT_DIR=/bml/projects/07_inference-clinical-trial/projects/07-09_ntsec-lego-fmri-connectivity
DERIVATIVES_DIR=${PROJECT_DIR}/data/derivatives
RAW_DIR=${PROJECT_DIR}/data/rawdata
SEL_DATA_ARR=("NTUSEC254")
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
SUBJ_LEVEL_PREPROC="no"
DICOM2NII="no"
DICOM2NII_T1T2="no"
COPY_RAW2DERIVATIVES="no"
FILE_CLEANUP="no"
INHOMOGENEITY_CORRECTION="no"
REALIGN_RESLICE="no"
SLICE_TIME_CORRECTION="no"
COREG_EPI_T2="no"
COREG_T1_T2="no"
SEGMENT_T1="no"
DENOISE_EPI="no"
NORMALISE_EPI_MNI="no"
SMOOTH_EPI="no"

GROUP_LEVEL_PREPROC="no"
MAKE_SST="no"
NORMALISE_EPI_SST_MNI="no"
NORMALISE_T1_SST_MNI="no"

SUBJ_LEVEL_STATS="yes"
LVL1_SPEC="no"
LVL1_SPEC2="no"
LVL1_REST_SPEC="no"
LVL1_EST="no"
LVL1_EST2="no"
LVL1_CON="no"
LVL1_REST_CON="no"
LVL1_MERGE_RESIDUALS="no"
LVL1_REST_MERGE_RESIDUALS="yes"
LVL1_DETREND_BANDPASS_RESIDUALS="no"
LVL1_REST_DETREND_BANDPASS_RESIDUALS="yes"

GROUP_LEVEL_STATS="no"
LVL2_SPEC="no"
LVL2_EST="no"
LVL2_CON="no"

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

		# Convert dicom to raw.
		if [[ "${DICOM2NII}" == "yes" ]]; then
			echo "Working on ${subj} DICOM conversion."
			mkdir -p ${PROJECT_DIR}/data/rawdata/$subj/nii/ses01
			mkdir -p ${PROJECT_DIR}/data/rawdata/$subj/nii/ses02

			mkdir -p ${PROJECT_DIR}/data/rawdata/$subj/nii/ses01/VRIT1
			mkdir -p ${PROJECT_DIR}/data/rawdata/$subj/nii/ses01/VRIT2
			mkdir -p ${PROJECT_DIR}/data/rawdata/$subj/nii/ses01/VRIT3
			mkdir -p ${PROJECT_DIR}/data/rawdata/$subj/nii/ses01/VRIT4
			mkdir -p ${PROJECT_DIR}/data/rawdata/$subj/nii/ses02/VRIT1
			mkdir -p ${PROJECT_DIR}/data/rawdata/$subj/nii/ses02/VRIT2
			mkdir -p ${PROJECT_DIR}/data/rawdata/$subj/nii/ses02/VRIT3
			mkdir -p ${PROJECT_DIR}/data/rawdata/$subj/nii/ses02/VRIT4

			dcm2niix -o ${PROJECT_DIR}/data/rawdata/$subj/nii/ses01/VRIT1 ${PROJECT_DIR}/data/sourcedata/${subj}/ses01/brain/mri/func/VRIT1/
			dcm2niix -o ${PROJECT_DIR}/data/rawdata/$subj/nii/ses01/VRIT2 ${PROJECT_DIR}/data/sourcedata/${subj}/ses01/brain/mri/func/VRIT2/
			dcm2niix -o ${PROJECT_DIR}/data/rawdata/$subj/nii/ses01/VRIT3 ${PROJECT_DIR}/data/sourcedata/${subj}/ses01/brain/mri/func/VRIT3/
			dcm2niix -o ${PROJECT_DIR}/data/rawdata/$subj/nii/ses01/VRIT4 ${PROJECT_DIR}/data/sourcedata/${subj}/ses01/brain/mri/func/VRIT4/
			dcm2niix -o ${PROJECT_DIR}/data/rawdata/$subj/nii/ses02/VRIT1 ${PROJECT_DIR}/data/sourcedata/${subj}/ses02/brain/mri/func/VRIT1/
			dcm2niix -o ${PROJECT_DIR}/data/rawdata/$subj/nii/ses02/VRIT2 ${PROJECT_DIR}/data/sourcedata/${subj}/ses02/brain/mri/func/VRIT2/
			dcm2niix -o ${PROJECT_DIR}/data/rawdata/$subj/nii/ses02/VRIT3 ${PROJECT_DIR}/data/sourcedata/${subj}/ses02/brain/mri/func/VRIT3/
			dcm2niix -o ${PROJECT_DIR}/data/rawdata/$subj/nii/ses02/VRIT4 ${PROJECT_DIR}/data/sourcedata/${subj}/ses02/brain/mri/func/VRIT4/

			cp -rf ${PROJECT_DIR}/data/rawdata/$subj/nii/ses01 ${DERIVATIVES_DIR}/$subj/nii/ses01
			cp -rf ${PROJECT_DIR}/data/rawdata/$subj/nii/ses02 ${DERIVATIVES_DIR}/$subj/nii/ses02

			echo "${subj} DICOM conversion done."
		fi

		# Convert dicom to raw, copy to derivatives
		if [[ "${DICOM2NII_T1T2}" == "yes" ]]; then
			echo "Working on ${subj} DICOM conversion."
			mkdir -p ${PROJECT_DIR}/data/rawdata/$subj/nii/REST_SES01/T1
			mkdir -p ${PROJECT_DIR}/data/rawdata/$subj/nii/REST_SES01/T2
			mkdir -p ${PROJECT_DIR}/data/rawdata/$subj/nii/REST_SES02/T1
			mkdir -p ${PROJECT_DIR}/data/rawdata/$subj/nii/REST_SES02/T2
			dcm2niix -o ${PROJECT_DIR}/data/rawdata/$subj/nii/REST_SES01/T1 ${PROJECT_DIR}/data/sourcedata/${subj}/ses01/brain/mri/anat/T1/
			dcm2niix -o ${PROJECT_DIR}/data/rawdata/$subj/nii/REST_SES01/T2 ${PROJECT_DIR}/data/sourcedata/${subj}/ses01/brain/mri/anat/T2/
			dcm2niix -o ${PROJECT_DIR}/data/rawdata/$subj/nii/REST_SES02/T1 ${PROJECT_DIR}/data/sourcedata/${subj}/ses02/brain/mri/anat/T1/
			dcm2niix -o ${PROJECT_DIR}/data/rawdata/$subj/nii/REST_SES02/T2 ${PROJECT_DIR}/data/sourcedata/${subj}/ses02/brain/mri/anat/T2/
			cp -rf ${PROJECT_DIR}/data/rawdata/$subj/nii/REST_SES01/T1 ${DERIVATIVES_DIR}/$subj/nii/REST_SES01
			cp -rf ${PROJECT_DIR}/data/rawdata/$subj/nii/REST_SES01/T2 ${DERIVATIVES_DIR}/$subj/nii/REST_SES01
			cp -rf ${PROJECT_DIR}/data/rawdata/$subj/nii/REST_SES02/T1 ${DERIVATIVES_DIR}/$subj/nii/REST_SES02
			cp -rf ${PROJECT_DIR}/data/rawdata/$subj/nii/REST_SES02/T2 ${DERIVATIVES_DIR}/$subj/nii/REST_SES02		
			echo "${subj} DICOM conversion done."
		fi

		# Copy to derivatives
		if [[ "${COPY_RAW2DERIVATIVES}" == "yes" ]]; then
			cp -rf ${PROJECT_DIR}/data/rawdata/$subj ${DERIVATIVES_DIR}/
			echo "${subj} NIfTI files copied to derivatives directory."
		fi

		# Check and/or cleanup unwanted files
		if [[ "${FILE_CLEANUP}" == "yes" ]]; then
			echo "Working on ${subj} unwanted file checking and removal."
			for file in "${UNWANTED_FILENAME_GLOBS[@]}"; do
				rm -rf ${DERIVATIVES_DIR}/${subj}/nii/${file}
			done
			bash "${STUDY_SPECIFIC_OTHER_CLEANUP_SCRIPT}"
			echo "${subj} unwanted files removed. Now is a good time to check your remaining files first"
			EPI_FILES=( ${DERIVATIVES_DIR}/${subj}/nii/${EPI_FILENAME_GLOB}.nii ) 
			for (( file=0; file<${#EPI_FILES[@]}; file++ )); do
				echo ${EPI_FILES[${file}]} >> ${PROJECT_DIR}/code/pipelines/specs/EPI_${file}_DATA_LIST.txt
			done
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/${T2_FILENAME_GLOB} >> ${PROJECT_DIR}/code/pipelines/specs/T2_DATA_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/${T1_FILENAME_GLOB} >> ${PROJECT_DIR}/code/pipelines/specs/T1_DATA_LIST.txt
			echo "List of files updated in project code directory."
		fi

		# Enter subject level directory
		cd ${DERIVATIVES_DIR}/${subj}/nii
		EPI_DATA_LIST=${DERIVATIVES_DIR}/${subj}/nii/EPI_DATA_LIST.txt

		# Inhomogeneity correction
		if [[ "${INHOMOGENEITY_CORRECTION}" == "yes" ]]; then
			echo "Working on ${subj} inhomogeneity correction."



			echo "${subj} inhomogeneity correction done."
		fi

		# Realign and reslice EPI files
		if [[ "${REALIGN_RESLICE}" == "yes" ]]; then
			echo "Working on ${subj} realignment and reslicing."
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/REST*.nii >> ${EPI_DATA_LIST}
			# echo "EPI_DATA_LIST:  ${EPI_DATA_LIST} "
			spm_realign_reslice.sh ${EPI_DATA_LIST} ${REALIGN_TO_MEAN} ${subj}_spm_realign_reslice 1
			rm -rf ${EPI_DATA_LIST}

			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/REST*.nii >> ${EPI_DATA_LIST}
			spm_realign_reslice.sh ${EPI_DATA_LIST} ${REALIGN_TO_MEAN} ${subj}_spm_realign_reslice 1
			rm -rf ${EPI_DATA_LIST}

			echo "${subj} realign and reslice done."
		fi

		# Slice-time correct realigned-resliced EPI files
		if [[ "${SLICE_TIME_CORRECTION}" == "yes" ]]; then
			echo "Working on ${subj} slice time correction."
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/r*.nii >> ${EPI_DATA_LIST}
			#read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			spm_slice-timing.sh ${EPI_DATA_LIST} ${SLICE_TIME_REF_SLICE} ${SLICE_TIME_SLICE_ORDER} ${SLICE_TIME_TIME_ACQUISITION} ${subj}_spm_slice-timing 1
			rm -rf ${EPI_DATA_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/r*.nii >> ${EPI_DATA_LIST}
			spm_slice-timing.sh ${EPI_DATA_LIST} ${SLICE_TIME_REF_SLICE} ${SLICE_TIME_SLICE_ORDER} ${SLICE_TIME_TIME_ACQUISITION} ${subj}_spm_slice-timing 1
			rm -rf ${EPI_DATA_LIST}
			echo "${subj} slice time correction done."
		fi

		########20260131 WILLIAM CORAG EPI TO T2
		########20260429 WILLIAM CORAG EPI TO T1
		if [[ "${COREG_EPI_T2}" == "yes" ]]; then
			echo "Working on ${subj}EPI to T2 coregistration."
			arEPI_DATA_VOL=$(ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/ar*.nii | sed -n '1p')
			echo "arEPI_DATA_VOL : ${arEPI_DATA_VOL}"
			T2_DATA_VOL=$(ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T2/TZU_T2/s*T2.nii)	
			COREG_OTHER=$(ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/ar*.nii)
			echo "COREG_OTHER: = ${COREG_OTHER}"
			# read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			spm_coreg2 ${T2_DATA_VOL} ${arEPI_DATA_VOL} ${COREG_OTHER} ${subj}_spm_coreg_EPI-tzuT2 1	
			# read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty			
			echo "SES01_${subj} EPI to T2 coregistration done."

			echo "Working on ${subj}EPI to T2 coregistration."
			arEPI_DATA_VOL=$(ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/ar*.nii | sed -n '1p')
			echo "arEPI_DATA_VOL : ${arEPI_DATA_VOL}"
			T2_DATA_VOL=$(ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/T2/TZU_T2/s*T2.nii)	
			COREG_OTHER=$(ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/ar*.nii)
			echo "COREG_OTHER: = ${COREG_OTHER}"
			# read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			spm_coreg2 ${T2_DATA_VOL} ${arEPI_DATA_VOL} ${COREG_OTHER} ${subj}_spm_coreg_EPI-tzuT2 1	
			# read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty			
			echo "SES02_${subj} EPI to T2 coregistration done."
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
			echo "Working on SES01 ${subj} EPI denoising parameter extraction."
			rm -rf ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/REG_LIST.txt
			rm -rf ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/EPI_DATA_LIST.txt
			#read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			WM_MASK=${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/c2s*.nii
			CSF_MASK=${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/c3s*.nii
			REG_LIST=${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/REG_LIST.txt
			EPI_DATA_LIST=${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/EPI_DATA_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/ar*.nii >> ${EPI_DATA_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/rp*.txt >> ${REG_LIST}
			echo "SLICE_TO_SLICE:${SLICE_TO_SLICE}"
			#read -p "BEFORE   Enter 開始掃描..." < /dev/tty
			spm_denoise_physio ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01 ${EPI_DATA_LIST} ${EPI_TR} ${SLICE_TIME_REF_SLICE} ${SLICE_TO_SLICE} ${WM_MASK} ${CSF_MASK} ${DENOISE_MASK_THRESHOLD} ${REG_LIST} ${DENOISE_CENSOR_METHOD} ${DENOISE_CENSOR_THRESHOLD} ${subj}_spm_denoise_EPI
			#read -p "AFTER   Enter 開始掃描..." < /dev/tty
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
			#read -p "BEFORE   Enter 開始掃描..." < /dev/tty
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/ar*.nii >> ${EPI_DATA_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/rp*.txt >> ${REG_LIST}
			spm_denoise_physio ${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02 ${EPI_DATA_LIST} ${EPI_TR} ${SLICE_TIME_REF_SLICE} ${SLICE_TO_SLICE} ${WM_MASK} ${CSF_MASK} ${DENOISE_MASK_THRESHOLD} ${REG_LIST} ${DENOISE_CENSOR_METHOD} ${DENOISE_CENSOR_THRESHOLD} ${subj}_spm_denoise_EPI
			rm -rf ${REG_LIST}
			rm -rf ${EPI_DATA_LIST}		
			#read -p "BEFORE   Enter 開始掃描..." < /dev/tty
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

# GROUP LEVEL PREPROCESSING
if [[ "$GROUP_LEVEL_PREPROC" == "yes" ]]; then

	echo "Working on group level"

	# Set DATA_ARR
	TEMP=( "${DATA_ARR_FULLPATH[@]##*/}" )
	DATA_ARR=( "${TEMP[@]%/}" )
	echo "TEMP=${TEMP}, DATA_ARR=${DATA_ARR}, "
	#read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty

	if [[ "${MAKE_SST}" == "yes" ]]; then

		# Make SST
		echo "Working on SST"
		mkdir -p ${DERIVATIVES_DIR}/SST
		cd ${DERIVATIVES_DIR}/SST
		rm -rf rc_DATA_LIST.txt

		for IMAGE in "${rc_GLOBS[@]}"; do
			rm -rf ${IMAGE}_LIST.txt
			for subj in "${DATA_ARR[@]}"; do
				#read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
				ls -1 ${DERIVATIVES_DIR}/$subj/nii/ses01/T1/$IMAGE*.nii >> ${IMAGE}_LIST.txt
				ls -1 ${DERIVATIVES_DIR}/$subj/nii/ses02/T1/$IMAGE*.nii >> ${IMAGE}_LIST.txt	
				#read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			done
			echo "${IMAGE}_LIST.txt" >> rc_DATA_LIST.txt
			#read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
		done

		#read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
		spm_make_SST rc_DATA_LIST.txt spm_make_SST 1
		read -r FIRST_SUBJ_FULLFILE < rc1_LIST.txt
		FIRST_SUBJ_DIR=${FIRST_SUBJ_FULLFILE%/*}
		mv ${FIRST_SUBJ_DIR}/Template_*.nii ${DERIVATIVES_DIR}/SST/
		rm -rf rc_DATA_LIST.txt rc*_LIST.txt
		echo "SST done."
	fi

	if [[ ${NORMALISE_EPI_SST_MNI} == "yes" ]]; then

		# Normalise EPI to SST then to MNI and smooth
		echo "Working on EPI to SST to MNI normalisation and smoothing"
		rm -rf ${DERIVATIVES_DIR}/SST/FLOW_FIELD_LIST.txt
		rm -rf ${DERIVATIVES_DIR}/SST/IMAGE_FILE_LIST.txt
		for subj in "${DATA_ARR[@]}"; do
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/u_*.nii >> ${DERIVATIVES_DIR}/SST/FLOW_FIELD_LIST.txt
			IMAGE_FILES=(${DERIVATIVES_DIR}/${subj}/nii/ar${EPI_FILENAME_GLOB}.nii)
			echo ${IMAGE_FILES[*]} >> ${DERIVATIVES_DIR}/SST/IMAGE_FILE_LIST.txt
		done
		spm_normalise-sst-mni ${DERIVATIVES_DIR}/SST/Template_6.nii ${DERIVATIVES_DIR}/SST/FLOW_FIELD_LIST.txt ${DERIVATIVES_DIR}/SST/IMAGE_FILE_LIST.txt ${NORM_RESAMPLING} ${SMOOTH_KERNEL} ${DERIVATIVES_DIR}/SST/spm_normalise_epi_sst-mni 1
		rm -rf ${DERIVATIVES_DIR}/SST/FLOW_FIELD_LIST.txt ${DERIVATIVES_DIR}/SST/IMAGE_FILE_LIST.txt
		echo "EPI to SST to MNI normalisation and smoothing done"
	fi

	if [[ ${NORMALISE_T1_SST_MNI} == "yes" ]]; then

		# Normalise T1 to SST then to MNI
		echo "Working on T1 to SST to MNI normalisation"
		rm -rf ${DERIVATIVES_DIR}/SST/FLOW_FIELD_LIST.txt
		rm -rf ${DERIVATIVES_DIR}/SST/T1_IMAGE_FILE_LIST.txt
		for subj in "${DATA_ARR[@]}"; do
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/u_*.nii >> ${DERIVATIVES_DIR}/SST/FLOW_FIELD_LIST.txt
			ls ${PROJECT_DIR}/data/rawdata/${subj}/nii/${T1_FILENAME_GLOB} | sed 's/rawdata/derivatives/' >> ${DERIVATIVES_DIR}/SST/T1_IMAGE_FILE_LIST.txt
		done
		spm_normalise-sst-mni ${DERIVATIVES_DIR}/SST/Template_6.nii ${DERIVATIVES_DIR}/SST/FLOW_FIELD_LIST.txt ${DERIVATIVES_DIR}/SST/T1_IMAGE_FILE_LIST.txt NaN,NaN,NaN 0,0,0 ${DERIVATIVES_DIR}/SST/spm_normalise_T1_sst-mni 1
		rm -rf ${DERIVATIVES_DIR}/SST/FLOW_FIELD_LIST.txt ${DERIVATIVES_DIR}/SST/T1_IMAGE_FILE_LIST.txt
		echo "T1 to SST to MNI normalisation done"
	fi

fi

# SUBJECT LEVEL STATISTICS (AND RESTING STATE POST-PROCESSING)
if [[ "$SUBJ_LEVEL_STATS" == "yes" ]]; then

	# Set DATA_ARR
	if [[ "${SEL_DATA_ARR}" == "" ]]; then
		TEMP=( "${DATA_ARR_FULLPATH[@]##*/}" )
		DATA_ARR=( "${TEMP[@]%/}" )
		#echo "DATA_ARR=${DATA_ARR}"
	else
		DATA_ARR=( "${SEL_DATA_ARR[@]}" )
		echo "DATA_ARR=${DATA_ARR}"
	fi

	# Loop through subject directories
	for subj in "${DATA_ARR[@]}"; do

		# RESULTS_DIR1=${DERIVATIVES_DIR}/${subj}/ses01/VRIT1/results
		# mkdir -p ${RESULTS_DIR1}
		# RESULTS_DIR2=${DERIVATIVES_DIR}/${subj}/ses01/VRIT2/results
		# mkdir -p ${RESULTS_DIR2}
		# RESULTS_DIR3=${DERIVATIVES_DIR}/${subj}/ses01/VRIT3/results
		# mkdir -p ${RESULTS_DIR3}
		# RESULTS_DIR4=${DERIVATIVES_DIR}/${subj}/ses01/VRIT4/results
		# mkdir -p ${RESULTS_DIR4}
		
		#cd ${RESULTS_DIR1}

		# LEVEL 1 SPECIFICATION
		if [[ ${LVL1_SPEC} == "yes" ]]; then
			rm -rf ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST}
			RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses01/VRIT1/results
			mkdir -p ${RESULTS_DIR}
			cd ${RESULTS_DIR}
			echo "Working on SES1VRIT1 ${subj} level 1 stats specification."
			EPI_DATA_LIST=${DERIVATIVES_DIR}/${subj}/nii/EPI_DATA_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/VRIT1/${LVL1_EPI_INPUT_PREFIX}*.nii >> ${EPI_DATA_LIST}
			SOA_LIST=${DERIVATIVES_DIR}/${subj}/nii/SOA_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/t*p1*conditions.mat >> ${SOA_LIST}
			REG_LIST=${DERIVATIVES_DIR}/${subj}/nii/REG_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/VRIT1/${LVL1_DENOISE_PARAMS_GLOB} >> ${REG_LIST}
 			#read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			spm_lvl1_spec ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST} ${RESULTS_DIR} ${LVL1_STATS_UNITS} ${EPI_TR} ${LVL1_STATS_MICROTIME_RES} ${LVL1_STATS_MICROTIME_ONSET} "${LVL1_MASK}" ${LVL1_MASK_THRESH} ${subj}_spm_lvl1_spec 1
			rm -rf ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST}

			echo "Working on SES1VRIT2 ${subj} level 1 stats specification."
			RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses01/VRIT2/results
			mkdir -p ${RESULTS_DIR}
			cd ${RESULTS_DIR}			
			EPI_DATA_LIST=${DERIVATIVES_DIR}/${subj}/nii/EPI_DATA_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/VRIT2/${LVL1_EPI_INPUT_PREFIX}*.nii >> ${EPI_DATA_LIST}
			SOA_LIST=${DERIVATIVES_DIR}/${subj}/nii/SOA_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/t*p2*conditions.mat >> ${SOA_LIST}
			REG_LIST=${DERIVATIVES_DIR}/${subj}/nii/REG_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/VRIT2/${LVL1_DENOISE_PARAMS_GLOB} >> ${REG_LIST}
			spm_lvl1_spec ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST} ${RESULTS_DIR} ${LVL1_STATS_UNITS} ${EPI_TR} ${LVL1_STATS_MICROTIME_RES} ${LVL1_STATS_MICROTIME_ONSET} "${LVL1_MASK}" ${LVL1_MASK_THRESH} ${subj}_spm_lvl1_spec 1
			rm -rf ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST}

			echo "Working on SES1VRIT3 ${subj} level 1 stats specification."
			RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses01/VRIT3/results
			mkdir -p ${RESULTS_DIR}
			cd ${RESULTS_DIR}	
			EPI_DATA_LIST=${DERIVATIVES_DIR}/${subj}/nii/EPI_DATA_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/VRIT3/${LVL1_EPI_INPUT_PREFIX}*.nii >> ${EPI_DATA_LIST}
			SOA_LIST=${DERIVATIVES_DIR}/${subj}/nii/SOA_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/t*a1*conditions.mat >> ${SOA_LIST}
			REG_LIST=${DERIVATIVES_DIR}/${subj}/nii/REG_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/VRIT3/${LVL1_DENOISE_PARAMS_GLOB} >> ${REG_LIST}
			spm_lvl1_spec ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST} ${RESULTS_DIR} ${LVL1_STATS_UNITS} ${EPI_TR} ${LVL1_STATS_MICROTIME_RES} ${LVL1_STATS_MICROTIME_ONSET} "${LVL1_MASK}" ${LVL1_MASK_THRESH} ${subj}_spm_lvl1_spec 1
			rm -rf ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST}

			echo "Working on SES1VRIT4 ${subj} level 1 stats specification."
			RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses01/VRIT4/results
			mkdir -p ${RESULTS_DIR}
			cd ${RESULTS_DIR}			
			EPI_DATA_LIST=${DERIVATIVES_DIR}/${subj}/nii/EPI_DATA_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/VRIT4/${LVL1_EPI_INPUT_PREFIX}*.nii >> ${EPI_DATA_LIST}
			SOA_LIST=${DERIVATIVES_DIR}/${subj}/nii/SOA_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/t*a2*conditions.mat >> ${SOA_LIST}
			REG_LIST=${DERIVATIVES_DIR}/${subj}/nii/REG_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/VRIT4/${LVL1_DENOISE_PARAMS_GLOB} >> ${REG_LIST}
			spm_lvl1_spec ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST} ${RESULTS_DIR} ${LVL1_STATS_UNITS} ${EPI_TR} ${LVL1_STATS_MICROTIME_RES} ${LVL1_STATS_MICROTIME_ONSET} "${LVL1_MASK}" ${LVL1_MASK_THRESH} ${subj}_spm_lvl1_spec 1
			rm -rf ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST}
			echo "${subj} SES01 level 1 specification done."

			####################################################################################

			echo "Working on SES2VRIT1 ${subj} level 1 stats specification."
			RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT1/results
			mkdir -p ${RESULTS_DIR}
			cd ${RESULTS_DIR}	
			EPI_DATA_LIST=${DERIVATIVES_DIR}/${subj}/nii/EPI_DATA_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT1/${LVL1_EPI_INPUT_PREFIX}*.nii >> ${EPI_DATA_LIST}
			SOA_LIST=${DERIVATIVES_DIR}/${subj}/nii/SOA_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/t*p1*conditions.mat >> ${SOA_LIST}
			REG_LIST=${DERIVATIVES_DIR}/${subj}/nii/REG_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT1/${LVL1_DENOISE_PARAMS_GLOB} >> ${REG_LIST}
			#read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			spm_lvl1_spec ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST} ${RESULTS_DIR} ${LVL1_STATS_UNITS} ${EPI_TR} ${LVL1_STATS_MICROTIME_RES} ${LVL1_STATS_MICROTIME_ONSET} "${LVL1_MASK}" ${LVL1_MASK_THRESH} ${subj}_spm_lvl1_spec 1
			rm -rf ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST}

			RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT2/results
			mkdir -p ${RESULTS_DIR}
			cd ${RESULTS_DIR}	
			echo "Working on SES2VRIT2 ${subj} level 1 stats specification."
			EPI_DATA_LIST=${DERIVATIVES_DIR}/${subj}/nii/EPI_DATA_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT2/${LVL1_EPI_INPUT_PREFIX}*.nii >> ${EPI_DATA_LIST}
			SOA_LIST=${DERIVATIVES_DIR}/${subj}/nii/SOA_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/t*p2*conditions.mat >> ${SOA_LIST}
			REG_LIST=${DERIVATIVES_DIR}/${subj}/nii/REG_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT2/${LVL1_DENOISE_PARAMS_GLOB} >> ${REG_LIST}
			spm_lvl1_spec ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST} ${RESULTS_DIR} ${LVL1_STATS_UNITS} ${EPI_TR} ${LVL1_STATS_MICROTIME_RES} ${LVL1_STATS_MICROTIME_ONSET} "${LVL1_MASK}" ${LVL1_MASK_THRESH} ${subj}_spm_lvl1_spec 1
			rm -rf ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST}


			RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT3/results
			mkdir -p ${RESULTS_DIR}
			cd ${RESULTS_DIR}	
			echo "Working on SES2VRIT3 ${subj} level 1 stats specification."
			EPI_DATA_LIST=${DERIVATIVES_DIR}/${subj}/nii/EPI_DATA_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT3/${LVL1_EPI_INPUT_PREFIX}*.nii >> ${EPI_DATA_LIST}
			SOA_LIST=${DERIVATIVES_DIR}/${subj}/nii/SOA_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/t*a1*conditions.mat >> ${SOA_LIST}
			REG_LIST=${DERIVATIVES_DIR}/${subj}/nii/REG_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT3/${LVL1_DENOISE_PARAMS_GLOB} >> ${REG_LIST}
			spm_lvl1_spec ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST} ${RESULTS_DIR} ${LVL1_STATS_UNITS} ${EPI_TR} ${LVL1_STATS_MICROTIME_RES} ${LVL1_STATS_MICROTIME_ONSET} "${LVL1_MASK}" ${LVL1_MASK_THRESH} ${subj}_spm_lvl1_spec 1
			rm -rf ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST}

			RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT4/results
			mkdir -p ${RESULTS_DIR}
			cd ${RESULTS_DIR}	
			echo "Working on SES2VRIT4 ${subj} level 1 stats specification."
			EPI_DATA_LIST=${DERIVATIVES_DIR}/${subj}/nii/EPI_DATA_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT4/${LVL1_EPI_INPUT_PREFIX}*.nii >> ${EPI_DATA_LIST}
			SOA_LIST=${DERIVATIVES_DIR}/${subj}/nii/SOA_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/t*a2*conditions.mat >> ${SOA_LIST}
			REG_LIST=${DERIVATIVES_DIR}/${subj}/nii/REG_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT4/${LVL1_DENOISE_PARAMS_GLOB} >> ${REG_LIST}
			spm_lvl1_spec ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST} ${RESULTS_DIR} ${LVL1_STATS_UNITS} ${EPI_TR} ${LVL1_STATS_MICROTIME_RES} ${LVL1_STATS_MICROTIME_ONSET} "${LVL1_MASK}" ${LVL1_MASK_THRESH} ${subj}_spm_lvl1_spec 1
			rm -rf ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST}

		fi

		if [[ ${LVL1_SPEC2} == "yes" ]]; then
			EPI_DATA_LIST=${DERIVATIVES_DIR}/${subj}/nii/ses01/results/EPI_DATA_LIST.txt
			SOA_LIST=${DERIVATIVES_DIR}/${subj}/nii/ses01/results/SOA_LIST.txt
			REG_LIST=${DERIVATIVES_DIR}/${subj}/nii/ses01/results/REG_LIST.txt
			rm -rf ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST}
			RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses01/results
			rm -rf ${RESULTS_DIR}/spm.mat
			mkdir -p ${RESULTS_DIR}
			cd ${RESULTS_DIR}
			echo "Working on SES1 ${subj} level 1 stats specification."

			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/VRIT1/${LVL1_EPI_INPUT_PREFIX}*.nii >> ${EPI_DATA_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/VRIT2/${LVL1_EPI_INPUT_PREFIX}*.nii >> ${EPI_DATA_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/VRIT3/${LVL1_EPI_INPUT_PREFIX}*.nii >> ${EPI_DATA_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/VRIT4/${LVL1_EPI_INPUT_PREFIX}*.nii >> ${EPI_DATA_LIST}

			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/t*p1*conditions.mat >> ${SOA_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/t*p2*conditions.mat >> ${SOA_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/t*a1*conditions.mat >> ${SOA_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/t*a2*conditions.mat >> ${SOA_LIST}


			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/VRIT1/${LVL1_DENOISE_PARAMS_GLOB} >> ${REG_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/VRIT2/${LVL1_DENOISE_PARAMS_GLOB} >> ${REG_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/VRIT3/${LVL1_DENOISE_PARAMS_GLOB} >> ${REG_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/VRIT4/${LVL1_DENOISE_PARAMS_GLOB} >> ${REG_LIST}

 			#read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			spm_lvl1_spec ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST} ${RESULTS_DIR} ${LVL1_STATS_UNITS} ${EPI_TR} ${LVL1_STATS_MICROTIME_RES} ${LVL1_STATS_MICROTIME_ONSET} "${LVL1_MASK}" ${LVL1_MASK_THRESH} ${subj}_spm_lvl1_spec 1
			rm -rf ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST}

			#############################################
			EPI_DATA_LIST=${DERIVATIVES_DIR}/${subj}/nii/ses02/results/EPI_DATA_LIST.txt
			SOA_LIST=${DERIVATIVES_DIR}/${subj}/nii/ses02/results/SOA_LIST.txt
			REG_LIST=${DERIVATIVES_DIR}/${subj}/nii/ses02/results/REG_LIST.txt
			rm -rf ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST}
			RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses02/results
			mkdir -p ${RESULTS_DIR}
			rm -rf ${RESULTS_DIR}/spm.mat
			cd ${RESULTS_DIR}
			echo "Working on SES2 ${subj} level 1 stats specification."

			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT1/${LVL1_EPI_INPUT_PREFIX}*.nii >> ${EPI_DATA_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT2/${LVL1_EPI_INPUT_PREFIX}*.nii >> ${EPI_DATA_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT3/${LVL1_EPI_INPUT_PREFIX}*.nii >> ${EPI_DATA_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT4/${LVL1_EPI_INPUT_PREFIX}*.nii >> ${EPI_DATA_LIST}

			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/t*p1*conditions.mat >> ${SOA_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/t*p2*conditions.mat >> ${SOA_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/t*a1*conditions.mat >> ${SOA_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/t*a2*conditions.mat >> ${SOA_LIST}


			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT1/${LVL1_DENOISE_PARAMS_GLOB} >> ${REG_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT2/${LVL1_DENOISE_PARAMS_GLOB} >> ${REG_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT3/${LVL1_DENOISE_PARAMS_GLOB} >> ${REG_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT4/${LVL1_DENOISE_PARAMS_GLOB} >> ${REG_LIST}

 			#read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			spm_lvl1_spec ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST} ${RESULTS_DIR} ${LVL1_STATS_UNITS} ${EPI_TR} ${LVL1_STATS_MICROTIME_RES} ${LVL1_STATS_MICROTIME_ONSET} "${LVL1_MASK}" ${LVL1_MASK_THRESH} ${subj}_spm_lvl1_spec 1
			rm -rf ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST}

			echo " ${subj} SES02 FFFFFFin."
		fi

		if [[ ${LVL1_REST_SPEC} == "yes" ]]; then
			rm -rf ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST}
			RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/results
			mkdir -p ${RESULTS_DIR}
			cd ${RESULTS_DIR}
			echo "Working on SES1 REST1 ${subj} level 1 stats specification."
			EPI_DATA_LIST=${DERIVATIVES_DIR}/${subj}/nii/EPI_DATA_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/${LVL1_EPI_INPUT_PREFIX}*.nii >> ${EPI_DATA_LIST}
			touch ${DERIVATIVES_DIR}/${subj}/nii/SOA_LIST.txt
			SOA_LIST="${DERIVATIVES_DIR}/${subj}/nii/SOA_LIST.txt"
			#ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/t*a1*conditions.mat >> ${SOA_LIST}
			REG_LIST=${DERIVATIVES_DIR}/${subj}/nii/REG_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/${LVL1_DENOISE_PARAMS_GLOB} >> ${REG_LIST}

			spm_lvl1_spec_REST2 ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST} ${RESULTS_DIR} ${LVL1_STATS_UNITS} ${EPI_TR} ${LVL1_STATS_MICROTIME_RES} ${LVL1_STATS_MICROTIME_ONSET} "${LVL1_MASK}" ${LVL1_MASK_THRESH} ${subj}_spm_lvl1_spec 1
			rm -rf ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST}
			#read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty

			RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/results
			mkdir -p ${RESULTS_DIR}
			cd ${RESULTS_DIR}
			echo "Working on SES2 REST1 ${subj} level 1 stats specification."
			EPI_DATA_LIST=${DERIVATIVES_DIR}/${subj}/nii/EPI_DATA_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/${LVL1_EPI_INPUT_PREFIX}*.nii >> ${EPI_DATA_LIST}
			touch ${DERIVATIVES_DIR}/${subj}/nii/SOA_LIST.txt
			SOA_LIST="${DERIVATIVES_DIR}/${subj}/nii/SOA_LIST.txt"
			#ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/t*a1*conditions.mat >> ${SOA_LIST}
			REG_LIST=${DERIVATIVES_DIR}/${subj}/nii/REG_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/${LVL1_DENOISE_PARAMS_GLOB} >> ${REG_LIST}
			#read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			spm_lvl1_spec_REST2 ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST} ${RESULTS_DIR} ${LVL1_STATS_UNITS} ${EPI_TR} ${LVL1_STATS_MICROTIME_RES} ${LVL1_STATS_MICROTIME_ONSET} "${LVL1_MASK}" ${LVL1_MASK_THRESH} ${subj}_spm_lvl1_spec 1
			rm -rf ${EPI_DATA_LIST} ${SOA_LIST} ${REG_LIST}

		fi

		# LEVEL 1 ESTIMATION
		if [[ ${LVL1_EST} == "yes" ]]; then
			echo "Working on ${subj} SES01 level 1 stats estimation."
			RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/results
			spm_stats_est ${RESULTS_DIR}/SPM.mat ${LVL1_STATS_RESIDUALS} ${subj}_spm_lvl1_est 1

			echo "Working on ${subj} SES02 level 1 stats estimation."
			RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/results
			spm_stats_est ${RESULTS_DIR}/SPM.mat ${LVL1_STATS_RESIDUALS} ${subj}_spm_lvl1_est 1

			#read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			echo "${subj} level 1 estimation done."

		fi

		if [[ ${LVL1_EST2} == "yes" ]]; then
			echo "Working on ${subj} SES01 level 1 stats estimation."
			# RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses01/results
			# echo "RESULTS_DIR= ${RESULTS_DIR}"
			# spm_stats_est ${RESULTS_DIR}/SPM.mat ${LVL1_STATS_RESIDUALS} ${subj}_spm_lvl1_est 1

			echo "Working on ${subj} SES02 level 1 stats estimation."
			RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses02/results
			spm_stats_est ${RESULTS_DIR}/SPM.mat ${LVL1_STATS_RESIDUALS} ${subj}_spm_lvl1_est 1

			#read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			echo "${subj} level 1 estimation done."

		fi

		# LEVEL 1 CONTRAST
		if [[ ${LVL1_CON} == "yes" ]]; then
			echo "Working on ${subj} VRIT1 level 1 stats contrasts."
			RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses01/results
			SOA_LIST=${RESULTS_DIR}/SOA_LIST.txt
			CONTYPE_LIST=${RESULTS_DIR}/CONTYPE_LIST.txt
			CONNAME_LIST=${RESULTS_DIR}/CONNAMES_LIST.txt
			CONVEC_LIST=${RESULTS_DIR}/CONVEC_LIST.txt
			rm -rf ${SOA_LIST} ${CONTYPE_LIST} ${CONVEC_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/t*p1*conditions.mat >> ${SOA_LIST}
			#read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			spm_eval_stats_lists ${STUDY_SPECIFIC_MAKE_LVL1_CON_LIST_SCRIPT} ${SOA_LIST} ${CONTYPE_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			#read -p "請確認spm_eval_stats_lists，按 Enter 開始掃描..." < /dev/tty
			spm_stats_con ${RESULTS_DIR}/SPM.mat ${CONTYPE_LIST} ${CONNAME_LIST} ${CONVEC_LIST} ${LVL1_STATS_DELETE_CONS} ${subj}_spm_lvl1_con 1
			rm -rf ${SOA_LIST} ${CONTYPE_LIST} ${CONVEC_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			echo "${subj} S1V1 level 1 contrasts done."
			#read -p "請確認VRIT1正確，按 Enter 開始掃描..." < /dev/tty

			RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses01/VRIT2/results
			SOA_LIST=${RESULTS_DIR}/SOA_LIST.txt
			CONTYPE_LIST=${RESULTS_DIR}/CONTYPE_LIST.txt
			CONNAME_LIST=${RESULTS_DIR}/CONNAMES_LIST.txt
			CONVEC_LIST=${RESULTS_DIR}/CONVEC_LIST.txt
			rm -rf ${SOA_LIST} ${CONTYPE_LIST} ${CONVEC_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/t*p2*conditions.mat >> ${SOA_LIST}
			spm_eval_stats_lists ${STUDY_SPECIFIC_MAKE_LVL1_CON_LIST_SCRIPT} ${SOA_LIST} ${CONTYPE_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			spm_stats_con ${RESULTS_DIR}/SPM.mat ${CONTYPE_LIST} ${CONNAME_LIST} ${CONVEC_LIST} ${LVL1_STATS_DELETE_CONS} ${subj}_spm_lvl1_con 1
			rm -rf ${SOA_LIST} ${CONTYPE_LIST} ${CONVEC_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			echo "${subj} S1V2 level 1 contrasts done."

			RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses01/VRIT3/results
			SOA_LIST=${RESULTS_DIR}/SOA_LIST.txt
			CONTYPE_LIST=${RESULTS_DIR}/CONTYPE_LIST.txt
			CONNAME_LIST=${RESULTS_DIR}/CONNAMES_LIST.txt
			CONVEC_LIST=${RESULTS_DIR}/CONVEC_LIST.txt
			rm -rf ${SOA_LIST} ${CONTYPE_LIST} ${CONVEC_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/t*a1*conditions.mat >> ${SOA_LIST}
			spm_eval_stats_lists ${STUDY_SPECIFIC_MAKE_LVL1_CON_LIST_SCRIPT} ${SOA_LIST} ${CONTYPE_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			spm_stats_con ${RESULTS_DIR}/SPM.mat ${CONTYPE_LIST} ${CONNAME_LIST} ${CONVEC_LIST} ${LVL1_STATS_DELETE_CONS} ${subj}_spm_lvl1_con 1
			rm -rf ${SOA_LIST} ${CONTYPE_LIST} ${CONVEC_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			echo "${subj} S1V3 level 1 contrasts done."

			RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses01/VRIT4/results
			SOA_LIST=${RESULTS_DIR}/SOA_LIST.txt
			CONTYPE_LIST=${RESULTS_DIR}/CONTYPE_LIST.txt
			CONNAME_LIST=${RESULTS_DIR}/CONNAMES_LIST.txt
			CONVEC_LIST=${RESULTS_DIR}/CONVEC_LIST.txt
			rm -rf ${SOA_LIST} ${CONTYPE_LIST} ${CONVEC_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/t*a2*conditions.mat >> ${SOA_LIST}
			spm_eval_stats_lists ${STUDY_SPECIFIC_MAKE_LVL1_CON_LIST_SCRIPT} ${SOA_LIST} ${CONTYPE_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			spm_stats_con ${RESULTS_DIR}/SPM.mat ${CONTYPE_LIST} ${CONNAME_LIST} ${CONVEC_LIST} ${LVL1_STATS_DELETE_CONS} ${subj}_spm_lvl1_con 1
			rm -rf ${SOA_LIST} ${CONTYPE_LIST} ${CONVEC_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			echo "${subj} S1V4 level 1 contrasts done."

			############################
			echo "Working on ${subj} SES02 level 1 stats contrasts."
			RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT1/results
			SOA_LIST=${RESULTS_DIR}/SOA_LIST.txt
			CONTYPE_LIST=${RESULTS_DIR}/CONTYPE_LIST.txt
			CONNAME_LIST=${RESULTS_DIR}/CONNAMES_LIST.txt
			CONVEC_LIST=${RESULTS_DIR}/CONVEC_LIST.txt
			rm -rf ${SOA_LIST} ${CONTYPE_LIST} ${CONVEC_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/t*p1*conditions.mat >> ${SOA_LIST}
			spm_eval_stats_lists ${STUDY_SPECIFIC_MAKE_LVL1_CON_LIST_SCRIPT} ${SOA_LIST} ${CONTYPE_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			spm_stats_con ${RESULTS_DIR}/SPM.mat ${CONTYPE_LIST} ${CONNAME_LIST} ${CONVEC_LIST} ${LVL1_STATS_DELETE_CONS} ${subj}_spm_lvl1_con 1
			rm -rf ${SOA_LIST} ${CONTYPE_LIST} ${CONVEC_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			echo "${subj} S2V1 level 1 contrasts done."


			RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT2/results
			SOA_LIST=${RESULTS_DIR}/SOA_LIST.txt
			CONTYPE_LIST=${RESULTS_DIR}/CONTYPE_LIST.txt
			CONNAME_LIST=${RESULTS_DIR}/CONNAMES_LIST.txt
			CONVEC_LIST=${RESULTS_DIR}/CONVEC_LIST.txt
			rm -rf ${SOA_LIST} ${CONTYPE_LIST} ${CONVEC_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/t*p2*conditions.mat >> ${SOA_LIST}
			spm_eval_stats_lists ${STUDY_SPECIFIC_MAKE_LVL1_CON_LIST_SCRIPT} ${SOA_LIST} ${CONTYPE_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			spm_stats_con ${RESULTS_DIR}/SPM.mat ${CONTYPE_LIST} ${CONNAME_LIST} ${CONVEC_LIST} ${LVL1_STATS_DELETE_CONS} ${subj}_spm_lvl1_con 1
			rm -rf ${SOA_LIST} ${CONTYPE_LIST} ${CONVEC_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			echo "${subj} S2V2 level 1 contrasts done."

			RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT3/results
			SOA_LIST=${RESULTS_DIR}/SOA_LIST.txt
			CONTYPE_LIST=${RESULTS_DIR}/CONTYPE_LIST.txt
			CONNAME_LIST=${RESULTS_DIR}/CONNAMES_LIST.txt
			CONVEC_LIST=${RESULTS_DIR}/CONVEC_LIST.txt
			rm -rf ${SOA_LIST} ${CONTYPE_LIST} ${CONVEC_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/t*a1*conditions.mat >> ${SOA_LIST}
			spm_eval_stats_lists ${STUDY_SPECIFIC_MAKE_LVL1_CON_LIST_SCRIPT} ${SOA_LIST} ${CONTYPE_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			spm_stats_con ${RESULTS_DIR}/SPM.mat ${CONTYPE_LIST} ${CONNAME_LIST} ${CONVEC_LIST} ${LVL1_STATS_DELETE_CONS} ${subj}_spm_lvl1_con 1
			rm -rf ${SOA_LIST} ${CONTYPE_LIST} ${CONVEC_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			echo "${subj} S2V3 level 1 contrasts done."

			RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT4/results
			SOA_LIST=${RESULTS_DIR}/SOA_LIST.txt
			CONTYPE_LIST=${RESULTS_DIR}/CONTYPE_LIST.txt
			CONNAME_LIST=${RESULTS_DIR}/CONNAMES_LIST.txt
			CONVEC_LIST=${RESULTS_DIR}/CONVEC_LIST.txt
			rm -rf ${SOA_LIST} ${CONTYPE_LIST} ${CONVEC_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/t*a2*conditions.mat >> ${SOA_LIST}
			spm_eval_stats_lists ${STUDY_SPECIFIC_MAKE_LVL1_CON_LIST_SCRIPT} ${SOA_LIST} ${CONTYPE_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			spm_stats_con ${RESULTS_DIR}/SPM.mat ${CONTYPE_LIST} ${CONNAME_LIST} ${CONVEC_LIST} ${LVL1_STATS_DELETE_CONS} ${subj}_spm_lvl1_con 1
			rm -rf ${SOA_LIST} ${CONTYPE_LIST} ${CONVEC_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			echo "${subj} S2V4 level 1 contrasts done."
			echo "${subj} S1S2 DDDDDDone."

		fi

		if [[ ${LVL1_REST_CON} == "yes" ]]; then
			echo "Working on ${subj} REST1 level 1 stats contrasts."
			RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/results/
			SOA_LIST=${RESULTS_DIR}/SOA_LIST.txt
			CONTYPE_LIST=${RESULTS_DIR}/CONTYPE_LIST.txt
			CONNAME_LIST=${RESULTS_DIR}/CONNAMES_LIST.txt
			CONVEC_LIST=${RESULTS_DIR}/CONVEC_LIST.txt
			rm -rf ${SOA_LIST} ${CONTYPE_LIST} ${CONVEC_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			# ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/t*p1*conditions.mat >> ${SOA_LIST}
			touch ${SOA_LIST}
			read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			spm_eval_stats_lists ${STUDY_SPECIFIC_MAKE_LVL1_CON_LIST_SCRIPT} ${SOA_LIST} ${CONTYPE_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			read -p "請確認spm_eval_stats_lists，按 Enter 開始掃描..." < /dev/tty
			spm_stats_con ${RESULTS_DIR}/SPM.mat ${CONTYPE_LIST} ${CONNAME_LIST} ${CONVEC_LIST} ${LVL1_STATS_DELETE_CONS} ${subj}_spm_lvl1_con 1
			rm -rf ${SOA_LIST} ${CONTYPE_LIST} ${CONVEC_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			echo "${subj} S1V1 level 1 contrasts done."
			read -p "請確認VRIT1正確，按 Enter 開始掃描..." < /dev/tty

			RESULTS_DIR=${DERIVATIVES_DIR}/${subj}/nii/ses01/VRIT2/results
			SOA_LIST=${RESULTS_DIR}/SOA_LIST.txt
			CONTYPE_LIST=${RESULTS_DIR}/CONTYPE_LIST.txt
			CONNAME_LIST=${RESULTS_DIR}/CONNAMES_LIST.txt
			CONVEC_LIST=${RESULTS_DIR}/CONVEC_LIST.txt
			rm -rf ${SOA_LIST} ${CONTYPE_LIST} ${CONVEC_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/t*p2*conditions.mat >> ${SOA_LIST}
			spm_eval_stats_lists ${STUDY_SPECIFIC_MAKE_LVL1_CON_LIST_SCRIPT} ${SOA_LIST} ${CONTYPE_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			spm_stats_con ${RESULTS_DIR}/SPM.mat ${CONTYPE_LIST} ${CONNAME_LIST} ${CONVEC_LIST} ${LVL1_STATS_DELETE_CONS} ${subj}_spm_lvl1_con 1
			rm -rf ${SOA_LIST} ${CONTYPE_LIST} ${CONVEC_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
			echo "${subj} S1V2 level 1 contrasts done."
			echo "${subj} S1S2 DDDDDDone."

		fi


		# MERGE RESIDUALS
		if [[ ${LVL1_MERGE_RESIDUALS} == "yes" ]]; then
			echo "Working on ${subj} level 1 merge residuals."
			run_end=0
			NVOLS_RUN=()
			for i in {1..4}; do
				epi_file=$(ls ${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT${i}/${LVL1_EPI_INPUT_PREFIX}*.nii)
				if [[ -z "${epi_file}" ]]; then
					echo "警告: ${subj} 的 VRIT${i} 找不到影像檔，跳過此受試者。"
					continue 2  # 跳出到外層處理下一個 subj
				fi
				NVOLS_RUN+=("$(fslval "${epi_file}" dim4)")
			done
			echo "${subj}最終產生的 NVOLS_RUN 陣列為: ${NVOLS_RUN[@]}"
			#read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty

			for ((run=0; run<${#NVOLS_RUN[@]}; run++ )); do
				cd ${DERIVATIVES_DIR}/${subj}/nii/ses02/results
				run_stt=$(( run_end + 1 ))
				run_end=$(( run_end + ${NVOLS_RUN[run]} ))
				input_files=$(seq -f "${LVL1_RESIDUALS_FILENAME_PREFIX}%04g.nii" $run_stt $run_end)
				fslmerge -tr "residuals_epi$(( run + 1 )).nii.gz" $input_files ${EPI_TR}
				fslmaths "residuals_epi$(( run + 1 )).nii.gz" -nan "residuals_epi$(( run + 1 )).nii.gz" # Set NaN to 0
				echo "${subj} ${run} level 1 merge residuals done."
				#read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			done
			rm -rf ${LVL1_RESIDUALS_FILENAME_PREFIX}*.nii
			echo "${subj} level 1 merge residuals done."
		fi

		if [[ ${LVL1_REST_MERGE_RESIDUALS} == "yes" ]]; then
			echo "Working on ${subj} level 1 merge residuals."
			run_end=0
			NVOLS_RUN=()
			epi_file=$(ls ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/ar*.nii)
			if [[ -z "${epi_file}" ]]; then
				echo "警告: ${subj} REST找不到影像檔，跳過此受試者。"
				continue 2 
			fi
			NVOLS_RUN+=("$(fslval "${epi_file}" dim4)")
			echo "${subj}最終產生的 NVOLS_RUN 陣列為: ${NVOLS_RUN[@]}"
			#read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty

			for ((run=0; run<${#NVOLS_RUN[@]}; run++ )); do
				cd ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/results
				run_stt=$(( run_end + 1 ))
				run_end=$(( run_end + ${NVOLS_RUN[run]} ))
				input_files=$(seq -f "${LVL1_RESIDUALS_FILENAME_PREFIX}%04g.nii" $run_stt $run_end)
				fslmerge -tr "residuals_epi$(( run + 1 )).nii.gz" $input_files ${EPI_TR}
				fslmaths "residuals_epi$(( run + 1 )).nii.gz" -nan "residuals_epi$(( run + 1 )).nii.gz" # Set NaN to 0
				echo "${subj} ${run} level 1 merge residuals done."
				#read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			done
			#rm -rf ${LVL1_RESIDUALS_FILENAME_PREFIX}*.nii

			# run_end=0
			# NVOLS_RUN=()
			# epi_file=$(ls ${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/ar*.nii)
			# if [[ -z "${epi_file}" ]]; then
			# 	echo "警告: ${subj} REST找不到影像檔，跳過此受試者。"
			# 	continue 2  # 跳出到外層處理下一個 subj
			# fi
			# NVOLS_RUN+=("$(fslval "${epi_file}" dim4)")
			# echo "${subj}最終產生的 NVOLS_RUN 陣列為: ${NVOLS_RUN[@]}"
			# #read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty

			# for ((run=0; run<${#NVOLS_RUN[@]}; run++ )); do
			# 	cd ${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/results
			# 	run_stt=$(( run_end + 1 ))
			# 	run_end=$(( run_end + ${NVOLS_RUN[run]} ))
			# 	input_files=$(seq -f "${LVL1_RESIDUALS_FILENAME_PREFIX}%04g.nii" $run_stt $run_end)
			# 	fslmerge -tr "residuals_epi$(( run + 1 )).nii.gz" $input_files ${EPI_TR}
			# 	fslmaths "residuals_epi$(( run + 1 )).nii.gz" -nan "residuals_epi$(( run + 1 )).nii.gz" # Set NaN to 0
			# 	echo "${subj} ${run} level 1 merge residuals done."
			# 	#read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			# done
			# #rm -rf ${LVL1_RESIDUALS_FILENAME_PREFIX}*.nii
			# echo "${subj} REST_SES02 level 1 merge residuals done."
		fi

		# DETREND AND BANDPASS FILTER RESIDUALS
		if [[ ${LVL1_DETREND_BANDPASS_RESIDUALS} == "yes" ]]; then
			echo "Working on SES02 ${subj} level 1 detrend and bandpass filter residuals."
			NVOLS_RUN=()
			for i in {1..4}; do
				epi_file=$(ls ${DERIVATIVES_DIR}/${subj}/nii/ses02/VRIT${i}/${LVL1_EPI_INPUT_PREFIX}*.nii)
				if [[ -z "${epi_file}" ]]; then
					echo "警告: ${subj} 的 VRIT${i} 找不到影像檔，跳過此受試者。"
					continue 2  # 跳出到外層處理下一個 subj
				fi
				NVOLS_RUN+=("$(fslval "${epi_file}" dim4)")
			done
			echo "${subj}最終產生的 NVOLS_RUN 陣列為: ${NVOLS_RUN[@]}"
			#read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty

			for ((run=0; run<${#NVOLS_RUN[@]}; run++ )); do
				cd ${DERIVATIVES_DIR}/${subj}/nii/ses02/results
				/usr/local/AFNI/abin/3dTproject -input "residuals_epi$(( run + 1 )).nii.gz" -prefix "bpd_residuals_epi$(( run + 1 )).nii.gz"  -polort 1 -passband ${LVL1_RESIDUALS_LOW_F} ${LVL1_RESIDUALS_HIGH_F} -dt ${EPI_TR}
			done
			echo "SES02 ${subj} level 1 detrend and bandpass filter residuals done."

		fi

		if [[ ${LVL1_REST_DETREND_BANDPASS_RESIDUALS} == "yes" ]]; then
			echo "Working on REST ${subj} level 1 detrend and bandpass filter residuals."
			run_end=0
			NVOLS_RUN=()
			epi_file=$(ls ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/ar*.nii)
			if [[ -z "${epi_file}" ]]; then
				echo "警告: ${subj} REST找不到影像檔，跳過此受試者。"
				continue 2  # 跳出到外層處理下一個 subj
			fi
			NVOLS_RUN+=("$(fslval "${epi_file}" dim4)")
			echo "${subj}最終產生的 NVOLS_RUN 陣列為: ${NVOLS_RUN[@]}"
			#read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty

			for ((run=0; run<${#NVOLS_RUN[@]}; run++ )); do
				cd ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/results
				/usr/local/afni/abin/3dTproject -input "residuals_epi$(( run + 1 )).nii.gz" \
					-prefix "bpd_residuals_epi$(( run + 1 )).nii.gz"  -polort 1 -passband \
				${LVL1_RESIDUALS_LOW_F} ${LVL1_RESIDUALS_HIGH_F} -dt ${EPI_TR}
			done
			echo "REST_SES01 ${subj} level 1 detrend and bandpass filter residuals done."

			# echo "Working on REST ${subj} level 1 detrend and bandpass filter residuals."
			# run_end=0
			# NVOLS_RUN=()
			# epi_file=$(ls ${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/ar*.nii)
			# NVOLS_RUN+=("$(fslval "${epi_file}" dim4)")
			# echo "${subj}最終產生的 NVOLS_RUN 陣列為: ${NVOLS_RUN[@]}"
			# #read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			# if [[ -z "${epi_file}" ]]; then
			# 	echo "警告: ${subj} REST找不到影像檔，跳過此受試者。"
			# 	continue 2  # 跳出到外層處理下一個 subj
			# fi
			# for ((run=0; run<${#NVOLS_RUN[@]}; run++ )); do
			# 	cd ${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/results
			# 	/usr/local/afni/abin/3dTproject -input "residuals_epi$(( run + 1 )).nii.gz" -prefix "bpd_residuals_epi$(( run + 1 )).nii.gz"  -polort 1 -passband ${LVL1_RESIDUALS_LOW_F} ${LVL1_RESIDUALS_HIGH_F} -dt ${EPI_TR}
			# done
			# echo "REST_SES02 ${subj} level 1 detrend and bandpass filter residuals done."

		fi




	done
fi

# GROUP LEVEL STATISTICS
if [[ "$GROUP_LEVEL_STATS" == "yes" ]]; then

	GRP_RESULTS_DIR=${DERIVATIVES_DIR}/group_results
	mkdir -p ${GRP_RESULTS_DIR}
	cd ${GRP_RESULTS_DIR}

	# LEVEL 2 SPECIFICATION (FULL FACTORIAL)
	if [[ ${LVL2_SPEC} == "yes" ]]; then
		echo "Working on level 2 stats specification (full factorial)."
		FACTOR_LIST=${GRP_RESULTS_DIR}/FACTOR_LIST.txt
		FACTOR_LEVELS_LIST=${GRP_RESULTS_DIR}/FACTOR_LEVELS_LIST.txt
		FACTOR_DEP_LIST=${GRP_RESULTS_DIR}/FACTOR_DEP_LIST.txt
		FACTOR_VAR_LIST=${GRP_RESULTS_DIR}/FACTOR_VAR_LIST.txt
		CELL_LEVELS_LIST=${GRP_RESULTS_DIR}/CELL_LEVELS_LIST.txt
		CELL_CON_FILES_LIST=${GRP_RESULTS_DIR}/CELL_CON_FILES_LIST.txt
		rm -rf ${FACTOR_LIST} ${FACTOR_LEVELS_LIST} ${FACTOR_DEP_LIST} ${FACTOR_VAR_LIST} ${CELL_LEVELS_LIST} ${CELL_CON_FILES_LIST}
		spm_eval_stats_lists ${STUDY_SPECIFIC_MAKE_LVL2_SPEC_LIST_SCRIPT} ${FACTOR_LIST} ${FACTOR_LEVELS_LIST} ${FACTOR_DEP_LIST} ${FACTOR_VAR_LIST} ${CELL_LEVELS_LIST} ${CELL_CON_FILES_LIST} 
		spm_lvl2_spec ${GRP_RESULTS_DIR} ${FACTOR_LIST} ${FACTOR_LEVELS_LIST} ${FACTOR_DEP_LIST} ${FACTOR_VAR_LIST} ${CELL_LEVELS_LIST} ${CELL_CON_FILES_LIST} ${GROUP_NAME}_spm_lvl2_spec 0
		rm -rf ${FACTOR_LIST} ${FACTOR_LEVELS_LIST} ${FACTOR_DEP_LIST} ${FACTOR_VAR_LIST} ${CELL_LEVELS_LIST} ${CELL_CON_FILES_LIST}
		echo "Group level full factorial specification done."
	fi

	# LEVEL 2 ESTIMATION
	if [[ ${LVL2_EST} == "yes" ]]; then

		echo "Working on level 2 stats estimation."
		spm_stats_est ${GRP_RESULTS_DIR}/SPM.mat ${LVL2_STATS_RESIDUALS} ${GROUP_NAME}_spm_lvl2_est 0
		echo "${subj} level 2 estimation done."
	fi

	# LEVEL 2 CONTRAST
	if [[ ${LVL2_CON} == "yes" ]]; then

		echo "Working on level 2 stats contrats."
		CONTYPE_LIST=${GRP_RESULTS_DIR}/CONTYPE_LIST.txt
		CONNAME_LIST=${GRP_RESULTS_DIR}/CONNAMES_LIST.txt
		CONVEC_LIST=${GRP_RESULTS_DIR}/CONVEC_LIST.txt
		rm -rf ${CONTYPE_LIST} ${CONVEC_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
		spm_eval_stats_lists ${STUDY_SPECIFIC_MAKE_LVL2_CON_LIST_SCRIPT} ${CONTYPE_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
		spm_stats_con ${GRP_RESULTS_DIR}/SPM.mat ${CONTYPE_LIST} ${CONNAME_LIST} ${CONVEC_LIST} ${LVL2_STATS_DELETE_CONS} ${GROUP_NAME}_spm_lvl2_con 0
		rm -rf ${CONTYPE_LIST} ${CONNAME_LIST} ${CONVEC_LIST}
		echo "${subj} level 2 contrasts done."

	fi

fi

cd ${CURR_DIR}
echo "Done!"

