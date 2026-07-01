#!/bin/bash

# SET PATHS, DATA, PARAMETERS AND GLOBS
CURR_DIR=$(pwd)
PROJECT_DIR=/bml/projects/07_inference-clinical-trial/projects/07-09_ntsec-lego-fmri-connectivity
DERIVATIVES_DIR=${PROJECT_DIR}/data/derivatives
RAW_DIR=${PROJECT_DIR}/data/rawdata

# SEL_DATA_ARR=("NTUSEC008")
EXC_DATA_ARR=("")


ROI_NAME=("roi1_HIP_R")
ROI_NAME_SHORT=("HIP_R")
ROI=("ROI1")
NUM=("1")

DATA_ARR_FULLPATH=(${PROJECT_DIR}/data/sourcedata/*)
NORM_RESAMPLING=3,3,3
SMOOTH_KERNEL=8,8,8

# SELECT ROUTINES
ROI_PREPROC="yes"
MNI2SST="no"
SST2SUB="no"
ROIwithC1="no"
COREG_ROI_EPI="no"
ROItimeEPI="no"
ZMAP_PY="no"
ZMAPSEED_PY="no"
COREG_c1_ZMAP="no"
ZMAP_WITH_RC1="no"
# ZMAP_WITH_NORC1="no"
ZMAP_02min01="no"

NORMALISE_EPI_SST_MNI="yes"
NORMALISE_T1_SST_MNI="no"

################NOW is for ROI2 PFG

# Initiate derivatives directory
mkdir -p ${DERIVATIVES_DIR}

# SUBJECT LEVEL PREPROCESSING
if [[ "$ROI_PREPROC" == "yes" ]]; then

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



		if [[ "${MNI2SST}" == "yes" ]]; then
			echo "Working on ${subj} MNI_to_SST."
			mkdir -p ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}
			cd ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}
			cp ${DERIVATIVES_DIR}/MNI_SPHERE/${ROI_NAME_SHORT}*.nii ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}/
			MNI_to_SST ${DERIVATIVES_DIR}/SST/iy_Template_6.nii ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}/${ROI_NAME_SHORT}*nii ${subj}_roi_mni2sst 1
			echo "${subj} SES01_MNI_to_SST done."

			echo "Working on ${subj} 2MNI_to_SST."
			mkdir -p ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME}
			cd ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME}
			cp ${DERIVATIVES_DIR}/MNI_SPHERE/${ROI_NAME_SHORT}*.nii ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME}/
			MNI_to_SST ${DERIVATIVES_DIR}/SST/iy_Template_6.nii ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME}/${ROI_NAME_SHORT}*nii ${subj}_roi_mni2sst 1
			echo "${subj} SES02_MNI_to_SST done."
		fi

		if [[ "${SST2SUB}" == "yes" ]]; then
			echo "Working on ${subj} SST_to_SUB."
			cd ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}
			SST_to_SUB ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/u*.nii ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}/SST*nii ${subj}_roi_SST2SUB 1
			echo "${subj} MNI_to_SST done."

			echo "Working on ${subj} 2SST_to_SUB."
			cd ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME}
			SST_to_SUB ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/u*.nii ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME}/SST*nii ${subj}_roi_SST2SUB 1
			echo "${subj} MNI_to_SST done."
		fi

		if [[ "${ROIwithC1}" == "yes" ]]; then
			echo "Working on ${subj} ROIwithC1."
			cd ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}
			rm -f ./EPI_DATA_LIST.txt
			EPI_DATA_LIST=./EPI_DATA_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}/wSST*.nii | sed 's/$/,1/' >> ${EPI_DATA_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/c1*.nii | sed 's/$/,1/' >> ${EPI_DATA_LIST}
			# read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			ROIwithC1 ${EPI_DATA_LIST} ${subj}${ROI} ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME} ${subj}_roi_ROIwithC1 1
			rm ./EPI_DATA_LIST.txt
			echo "${subj} ROIwithC1 done."

			echo "Working on ${subj} 2ROIwithC1."
			cd ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME}
			rm -f ./EPI_DATA_LIST.txt
			EPI_DATA_LIST=./EPI_DATA_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME}/wSST*.nii >> ${EPI_DATA_LIST}
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/c1*.nii >> ${EPI_DATA_LIST}
			# read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			ROIwithC1 ${EPI_DATA_LIST} ${subj}${ROI} ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME} ${subj}_roi_ROIwithC1 1
			rm ./EPI_DATA_LIST.txt
			echo "${subj} ROIwithC1 done."
		fi

		if [[ "${COREG_ROI_EPI}" == "yes" ]]; then
			echo "Working on ${subj}ROI to EPI1 coregistration."
			cd ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}


			# read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			CORG_ROI_TO_EPI ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/results/bpd_res*.nii ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}/${subj}${ROI}*.nii ${subj}_0531COREG_ROI_EPI 1
			echo "SES01_${subj} ROI to EPI1 coregistration done."
			# read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty

			echo "Working on ${subj}ROI to EPI2 coregistration."
			cd ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME}
			CORG_ROI_TO_EPI ${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/results/bpd_res*.nii ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME}/${subj}${ROI}*.nii ${subj}_COREG_ROI_EPI 1
			echo "SES02_${subj} ROI to EPI1 coregistration done."
		fi


		if [[ "${ROItimeEPI}" == "yes" ]]; then
			echo "Working on ${subj} ROItimeEPI."
			cd ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}
			# read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			MASK_EPI_WITHROI ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}/r${subj}*.nii ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/results/bpd_res*.nii SEED${NUM}_ROIEPI.nii

			echo "Working on ${subj} 2ROItimeEPI."
			cd ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME}
			# read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			MASK_EPI_WITHROI ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME}/r${subj}*.nii ${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/results/bpd_res*.nii SEED${NUM}_ROIEPI.nii
			echo "${subj} ROItimeEPI done."
		fi



		if [[ "${ZMAP_PY}" == "yes" ]]; then
			echo "Working on ${subj} ZMAP_PY."
			source /bml/projects/07_inference-clinical-trial/projects/07-09_ntsec-lego-fmri-connectivity/.venv/bin/activate
			cd ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}
			# read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			FC_ZMAP_PY2 ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}/SEED*.nii ${DERIVATIVES_DIR}/${subj}/nii/ses01/REST_SES01/results/bpd_res*.nii ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}/${subj}_ZMAP${NUM}.nii ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/rc1_334_corgzmap/ZMAP_334mask/rc1*.nii

			echo "Working on ${subj} 2 ZMAP_PY."
			cd ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME}
			# read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			FC_ZMAP_PY2 ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME}/SEED*.nii ${DERIVATIVES_DIR}/${subj}/nii/ses02/REST_SES02/results/bpd_res*.nii ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME}/${subj}_ZMAP${NUM}.nii ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/rc1_334_corgzmap/ZMAP_334mask/rc1*.nii
			deactivate
			echo "${subj} ROItimeEPI done."
		fi


		# if [[ "${ZMAPSEED_PY}" == "yes" ]]; then
		# 	echo "Working on ${subj} ZMAP-SEED_PY."
		# 	source /bml/projects/07_inference-clinical-trial/projects/07-09_ntsec-lego-fmri-connectivity/.venv/bin/activate
		# 	cd ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}
		# 	# read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
		# 	ZMAPNOSEED_PY ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}/*ZMAP*.nii ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}/r*${ROI}.nii ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}/${subj}ZMAP01_NO_SEED.nii

		# 	echo "Working on ${subj} 2 ZMAP-SEED_PY."
		# 	cd ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME}
		# 	# read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
		# 	ZMAPNOSEED_PY ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME}/*ZMAP*.nii ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME}/r*${ROI}.nii ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME}/${subj}ZMAP02_NO_SEED.nii
		# 	deactivate
		# 	echo "${subj} ZMAPSEED_PY done."
		# fi


		# if [[ "${COREG_c1_ZMAP}" == "yes" ]]; then
		# 	echo "Working on ${subj}COREG_c1_ZMAP oregistration RESLICE"
		# 	cd ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/rc1_334_corgzmap
		# 	rm -f ./rc*
		# 	CORG_ROI_TO_EPI ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}/*ZMAP*.nii ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/rc1_334_corgzmap/c1* ${subj}_rc1_334_corgzmap 1
		# 	echo "SES01_${subj} C1 to Z coregistration RESLICE done."

		# 	echo "Working on ${subj}COREG_c1_ZMAP oregistration RESLICE 2"
		# 	cd ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/rc1_334_corgzmap
		# 	rm -f ./rc*
		# 	CORG_ROI_TO_EPI ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME}/*ZMAP*.nii ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/rc1_334_corgzmap/c1* ${subj}_rc1_334_corgzmap 1
		# 	echo "SES01_${subj} C1 to Z coregistration RESLICE done."
		# fi

		# if [[ "${ZMAP_WITH_RC1}" == "yes" ]]; then
		# 	echo "Working on ${subj} ZMAP_WITH_RC1."
		# 	cd ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}
		# 	rm -f ./EPI_DATA_LIST.txt
		# 	EPI_DATA_LIST=./EPI_DATA_LIST.txt
		# 	ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}/*ZMAP*.nii | sed 's/$/,1/' >> ${EPI_DATA_LIST}
		# 	ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/rc1_334_corgzmap/rc1*.nii | sed 's/$/,1/' >> ${EPI_DATA_LIST}
		# 	# read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
		# 	ZMAPWITHRC1 ${EPI_DATA_LIST} ZMAP_FIN_${subj}${ROI} ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME} ${subj}_ZMAP_WITH_RC1 1
		# 	rm ./EPI_DATA_LIST.txt


		# 	echo "Working on ${subj} 2ZMAP_WITH_RC1."
		# 	cd ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME}
		# 	rm -f ./EPI_DATA_LIST.txt
		# 	EPI_DATA_LIST=./EPI_DATA_LIST.txt
		# 	ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME}/*ZMAP*.nii | sed 's/$/,1/' >> ${EPI_DATA_LIST}
		# 	ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/rc1_334_corgzmap/rc1*.nii | sed 's/$/,1/' >> ${EPI_DATA_LIST}
		# 	# read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
		# 	ZMAPWITHRC1 ${EPI_DATA_LIST} ZMAP_FIN_${subj}${ROI} ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME} ${subj}_ZMAP_WITH_RC1 1
		# 	rm ./EPI_DATA_LIST.txt
		# 	echo "${subj} ZMAP_WITH_RC1 done."
		# fi

		# if [[ "${ZMAP_WITH_NORC1}" == "yes" ]]; then
		# 	echo "Working on ${subj} ZMAP_WITH_RC1."
		# 	cd ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}
		# 	rm -f ./EPI_DATA_LIST.txt
		# 	EPI_DATA_LIST=./EPI_DATA_LIST.txt
		# 	ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}/*NO_SEED*.nii | sed 's/$/,1/' >> ${EPI_DATA_LIST}
		# 	ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/rc1_334_corgzmap/rc1*.nii | sed 's/$/,1/' >> ${EPI_DATA_LIST}
		# 	# read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
		# 	ZMAPWITHRC1 ${EPI_DATA_LIST} ZMAP_FIN_${subj}${ROI} ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME} ${subj}_ZMAP_WITH_RC1 1
		# 	rm ./EPI_DATA_LIST.txt


		# 	echo "Working on ${subj} 2ZMAP_WITH_RC1."
		# 	cd ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME}
		# 	rm -f ./EPI_DATA_LIST.txt
		# 	EPI_DATA_LIST=./EPI_DATA_LIST.txt
		# 	ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME}/*NO_SEED*.nii | sed 's/$/,1/' >> ${EPI_DATA_LIST}
		# 	ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/rc1_334_corgzmap/rc1*.nii | sed 's/$/,1/' >> ${EPI_DATA_LIST}
		# 	# read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
		# 	ZMAPWITHRC1 ${EPI_DATA_LIST} ZMAP_FIN_${subj}${ROI} ${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME} ${subj}_ZMAP_WITH_RC1 1
		# 	rm ./EPI_DATA_LIST.txt
		# 	echo "${subj} ZMAP_WITH_RC1 done."
		# fi

		if [[ "${ZMAP_02min01}" == "yes" ]]; then
			echo "Working on ${subj} ZMAP_02min01."
			if [[ "${subj}" == "NTUSEC068" || "${subj}" == "NTUSEC135" || "${subj}" == "NTUSEC246" ]]; then
				echo "SKIPPPPPPPP：${subj}"
				continue  
			fi
			cd ${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}
			rm -f ./EPI_DATA_LIST.txt
			EPI_DATA_LIST=./EPI_DATA_LIST.txt
			ls -1 ${DERIVATIVES_DIR}/ZMAP/8mm/${ROI_NAME}/ses02/*${subj}*.nii | sed 's/$/,1/' >> ${EPI_DATA_LIST}
			ls -1 ${DERIVATIVES_DIR}/ZMAP/8mm/${ROI_NAME}/ses01/*${subj}*.nii | sed 's/$/,1/' >> ${EPI_DATA_LIST}
			# read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			ZMAP02min01 ${EPI_DATA_LIST} ZMAP_2min1_${subj} ${DERIVATIVES_DIR}/ZMAP/8mm/${ROI_NAME}/NEW_ses01min02 ${subj}_ZMAP_8mm_02min01 0
			#  read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
			rm ./EPI_DATA_LIST.txt


		fi




		echo "${subj} preprocessing done."
	
	done





	if [[ ${NORMALISE_EPI_SST_MNI} == "yes" ]]; then

		# Normalise EPI to SST then to MNI and smooth
		echo "Working on EPI to SSSSSSST to MNI normalisation and smoothing"
		rm -rf ${DERIVATIVES_DIR}/SST/FLOW_FIELD_LIST.txt
		rm -rf ${DERIVATIVES_DIR}/SST/IMAGE_FILE_LIST.txt

		for subj in "${DATA_ARR[@]}"; do
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/u_*.nii >> ${DERIVATIVES_DIR}/SST/FLOW_FIELD_LIST.txt
			IMAGE_FILES=(${DERIVATIVES_DIR}/${subj}/nii/ses01/roi/${ROI_NAME}/ZMAP_FIN*.nii)
			echo ${IMAGE_FILES[*]} >> ${DERIVATIVES_DIR}/SST/IMAGE_FILE_LIST.txt
			if [[ "${subj}" == "NTUSEC068" || "${subj}" == "NTUSEC135" || "${subj}" == "NTUSEC246" ]]; then
				echo "⏭️ 排除名單，跳過受試者：${subj}"
				continue  # 觸發跳過，下方的指令都不會執行
			fi
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/u_*.nii >> ${DERIVATIVES_DIR}/SST/FLOW_FIELD_LIST.txt
			IMAGE_FILES=(${DERIVATIVES_DIR}/${subj}/nii/ses02/roi/${ROI_NAME}/ZMAP_FIN*.nii)
			echo ${IMAGE_FILES[*]} >> ${DERIVATIVES_DIR}/SST/IMAGE_FILE_LIST.txt

		done
		read -p "22222..." < /dev/tty
		spm_normalise-sst-mni ${DERIVATIVES_DIR}/SST/Template_6.nii ${DERIVATIVES_DIR}/SST/FLOW_FIELD_LIST.txt ${DERIVATIVES_DIR}/SST/IMAGE_FILE_LIST.txt ${NORM_RESAMPLING} 8,8,8 ${DERIVATIVES_DIR}/SST/spm_normalise_epi_sst-mni 1

		rm -rf ${DERIVATIVES_DIR}/SST/FLOW_FIELD_LIST.txt ${DERIVATIVES_DIR}/SST/IMAGE_FILE_LIST.txt

		echo "EPI to SST to MNI normalisation and smoothing done"
		read -p "請確認上述路徑正確，按 Enter 開始掃描..." < /dev/tty
	fi

	if [[ ${NORMALISE_T1_SST_MNI} == "yes" ]]; then

		# Normalise T1 to SST then to MNI
		echo "Working on T1 to SST to MNI normalisation"
		rm -rf ${DERIVATIVES_DIR}/SST/FLOW_FIELD_LIST.txt
		rm -rf ${DERIVATIVES_DIR}/SST/T1_IMAGE_FILE_LIST.txt
		for subj in "${DATA_ARR[@]}"; do
			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/u_*.nii >> ${DERIVATIVES_DIR}/SST/FLOW_FIELD_LIST.txt
			ls ${DERIVATIVES_DIR}/${subj}/nii/ses01/T1/T1*.nii >> ${DERIVATIVES_DIR}/SST/T1_IMAGE_FILE_LIST.txt

			ls -1 ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/u_*.nii >> ${DERIVATIVES_DIR}/SST/FLOW_FIELD_LIST.txt
			ls ${DERIVATIVES_DIR}/${subj}/nii/ses02/T1/T1*.nii >> ${DERIVATIVES_DIR}/SST/T1_IMAGE_FILE_LIST.txt
		done
		# read -p "333333" < /dev/tty

		spm_normalise-sst-mni ${DERIVATIVES_DIR}/SST/Template_6.nii ${DERIVATIVES_DIR}/SST/FLOW_FIELD_LIST.txt ${DERIVATIVES_DIR}/SST/T1_IMAGE_FILE_LIST.txt NaN,NaN,NaN 0,0,0 ${DERIVATIVES_DIR}/SST/spm_normalise_T1_sst-mni 1
		# read -p "444444" < /dev/tty
		rm -rf ${DERIVATIVES_DIR}/SST/FLOW_FIELD_LIST.txt ${DERIVATIVES_DIR}/SST/T1_IMAGE_FILE_LIST.txt
		echo "T1 to SST to MNI normalisation done"
	fi




fi

cd ${CURR_DIR}
echo "Done!"

