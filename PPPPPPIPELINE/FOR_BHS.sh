#!/bin/bash

# SET PATHS, DATA, PARAMETERS AND GLOBS
CURR_DIR=$(pwd)
PROJECT_DIR=/bml/projects/07_inference-clinical-trial/projects/07-09_ntsec-lego-fmri-connectivity
DERIVATIVES_DIR=${PROJECT_DIR}/data/derivatives
RAW_DIR=${PROJECT_DIR}/data/rawdata

SEL_DATA_ARR=("NTUSEC266")
EXC_DATA_ARR=("")


ROI_NAME=("roi1_HIP_R")
ROI=("ROI1")

DATA_ARR_FULLPATH=(${PROJECT_DIR}/data/sourcedata/*)
NORM_RESAMPLING=3,3,3
SMOOTH_KERNEL=8,8,8

# SELECT ROUTINES
ROI_PREPROC="yes"
MNI2SST="yes"
SST2SUB="yes"
ROIROI_CSV_PY="yes"


################NOW is for ROI2 PFG

# Initiate derivatives directory
mkdir -p ${DERIVATIVES_DIR}

# SUBJECT LEVEL PREPROCESSING
if [[ "$ROI_PREPROC" == "yes" ]]; then
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


		if [[ "${MNI2SST}" == "yes" ]]; then
			echo "Working on ${subj} MNI_to_SST."
			# cd ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/ROIROI
			# MNI_to_SST ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/iy*nii ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/ROIROI/AAL3v1.nii ${subj}_roi_mni2sst 1
			# echo "${subj} SES01_MNI_to_SST done."

			cd ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/ROIROI
			MNI_to_SST ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/iy*nii ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/ROIROI/AAL3v1.nii ${subj}_roi_mni2sst 1
			echo "${subj} SES02_MNI_to_SST done."

		fi

		if [[ "${SST2SUB}" == "yes" ]]; then
			echo "Working on ${subj} SST_to_SUB."
			# cd ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/ROIROI
			# SST_to_SUB ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/u*.nii ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/ROIROI/SST*nii ${subj}_roi_SST2SUB 1
			# echo "${subj} MNI_to_SST done."

			echo "Working on ${subj} 02 SST_to_SUB."
			cd ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/ROIROI
			SST_to_SUB ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/u*.nii ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/ROIROI/SST*nii ${subj}_roi_SST2SUB 1
			echo "${subj} 02 MNI_to_SST done."
		fi

		if [[ "${ROIROI_CSV_PY}" == "yes" ]]; then
			echo "Working on ${subj} ROIROI_CSV_PY"
			source /bml/projects/07_inference-clinical-trial/projects/07-09_ntsec-lego-fmri-connectivity/.venv/bin/activate
			# cd ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/ROIROI
			# ROI_ROI_CSV_PY ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/results/residuals*.nii.gz ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/multiple_regressors*1.txt ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/ROIROI/wSSTAAL*.nii ${DERIVATIVES_DIR}/AAL_ATLAS/AAL3/AAL3v1.nii.txt ${subj}_roiroi_csv.csv
			# # read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty

			echo "Working on ${subj} 02 ROIROI_CSV_PY"
			cd ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/ROIROI		
			# read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			ROI_ROI_CSV_PY ${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/results/residuals*.nii.gz ${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/multiple_regressors*1.txt ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/ROIROI/wSSTAAL*.nii ${DERIVATIVES_DIR}/AAL_ATLAS/AAL3/AAL3v1.nii.txt ${subj}_roiroi_csv.csv

			deactivate
			echo "${subj} ZMAPSEED_PY done."
		fi



		echo "${subj} preprocessing done."
	
	done

fi

cd ${CURR_DIR}
echo "Done!"