# Chen_project
This is William Chen's brainhack school project repo.
During this semester's BrainHack School, I explored an alternative approach to analyzing data from our laboratory's ICT project.
In my thesis research, I employed a **seed-to-voxel resting-state functional connectivity** approach. In contrast, for this BrainHack School project, I adopted the **ROI-to-ROI functional connectivity** method introduced in the course. In addition, I incorporated my own modification by using a **subject-specific AAL atlas** to achieve more precise and individualized analyses.


## Notes

As these data originate from an ongoing research project, I apologize that I am unable to publicly share the raw data at this time. However, all preprocessing and analysis pipelines used in this project are provided here.
The pipeline integrates **SPM**, **MATLAB scripts**, and **Python scripts**, orchestrated through **Bash scripts** to facilitate large-scale bash processing.
I am currently considering writing a more detailed user guide for the pipeline XD.
* The main pipeline is located in: `.../Pipeline`
* The shell scripts stored in the `/bin` directory should be placed under `~/bin`


## About My Project: 
# Functional Connectivity Changes Induced by LEGO Robot Inference Training in Aging Brain (For BrainHack school)
Abstract:

  In 2024, older adults accounted for 19.2% of Taiwan’s total population. Even more strikingly, this proportion is projected to reach 20.1% in 2025[1], officially making Taiwan into a super-aged society. Population aging is an on-going and unstoppable process. Undoubtedly, the cognitive decline associated with aging has long been regarded as one of the major challenges faced by modern societies. Taking action against cognitive decline in elders is both important and urgent. Our lab collaborate with NTSEC(National Taiwan Science Education Center). The ICT project (Inference Clinical Trial project) explores the use of non-invasive interventions to improve cognitive and inference abilities in older adults, such as handicraft DIY activities, forest exercise, board games, and the LEGO robot training program investigated in the present project.	In the LEGO robot and coding training, elder participants were randomly assigned to either the Active or Passive Inference group under a double-blind design. During the course, participants performed various tasks — for example, programming the robot to move its arms and play music. They were required to actively form strategies and hypotheses, control the LEGO robot through coding, and adjust their control strategies in real time based on the feedback provided by the robot. Through this systematic training program, it aimed to enhance cognitive and active Inference abilities in older adults.
  
  Inference is a higher-order cognitive function that depends on the coordinated engagement of multiple brain regions. As such, understanding inference requires not only the examination of regional brain activity but also the investigation of functional interactions among distributed neural networks. Based on our previous findings, this project will focus on the functional connectivity of brain regions that demonstrated sensitivity to the LEGO intervention, including the right hippocampus and left para-hippocampal gyrus. Using resting-state functional connectivity analysis and a ROI-ROI approach, we aim to characterize intervention-related changes in functional connectivity and identify the neural networks associated with improvements in inference performance. This project will provide insight into the cross-brain-area neural mechanisms that support inference and its enhancement through cognitive training. To sum up, this finding is expected not only to provide a stronger theoretical foundation for the ICT project, but also advance our understanding of the neural mechanisms underlying inference.

## Processing Method
**Using Chen_project/pipelines/VER2_PREPROC_WILLIAM_FC_pipeline.sh**
1. Motion correction
2. Slice-time correction
3. Coregister T2-T1-EPI
4. SEGMENT_T1
5. TAPAS PHYSIO denoise
6. Fslmerge (detrend and bendpass)
7. MERGE_RESIDUALS
8. DETREND_BANDPASS_RESIDUALS

**Now we have corrected, agrassive denoised resting-state fMRI signal**

//////////////////////////////////////////////////////////////////

For analysis(For BHS: ROI-ROI FC analysis)

**Using Chen_project/pipelines/FOR_BHS.sh**
1. SST Template
2. Segment SST (For deformation field)
3. ATLAS(MNI) to ATLAS(SST)
4. ATLAS(SST) to ATLAS(subject space)
5. Subject specific ATLAS
6. ROI - ROI Functional connectivity analysis using python

**Now we have ROI-ROI Functional connectivity array ready for second level analysis**  

## How to use my repo?  
**Before using my/josh's shell**
- Download /Chen_project/bin intp your /home/YOUR_USERNAME/bin
- Download /Chen_project/PYTHON intp your .../project/code
- Install MATLAB 
- Install SPM(12 or 25 both fine) 
- Add SPM into MATLAB path.
- Install FSL 
- Install AFNI  

**Repo introduction**  
JOSH_SPMpipeline: original josh's perprocess pipeline  
PYTHON: .py and .inbpy file for .sh to call  
USEFUL_CODE: .mat/.py/.sh for all kinds of function(EX: REALIGN_CHECK, VOLUME_CUT_END.....)  
pipelines: Main charactor!   
  VER2_PREPROC_WILLIAM_FC_pipeline.sh: For PREPROC
  FOR_BHS.sh: For ROI-ROI analysis
    
**UPDATE!!!　We now have Chen_project/pipelines/FINAL_FOR_BHS.sh for preprocess and analysis in a single pipeline**


# About me
I’m William Chen. I’m currently a first-year master’s student at GIBMS, and my main research focuses on functional connectivity and cognitive training interventions.
This semester, I’m both a student in Brain Hack School and also serving as a TA.

<img src="./element/9B901720-B35E-4157-8574-CDB008667D8D.jpg" width="300" alt="Nice to meet you<3">

I’m really looking forward to learning with all of you—nice to meet you!

# Expertise and research topic
- neural science
- functional connectivity
- computer science
