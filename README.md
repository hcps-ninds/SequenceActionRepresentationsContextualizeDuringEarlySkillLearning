# SequenceActionRepresentationsContextualizeDuringEarlySkillLearning
This repository includes code from the article, "Sequence action representations contextualize during early skill learning", published in eLife. (https://doi.org/10.7554/eLife.102475.3)

## List of Codes

do_MEG_preprocessing: Preprocessing of MEG data including ICA, notch and bandpass filtering

do_HeadnSourceModel: Prepares Head model, source model, and transfer matrix

get_source_data: Extracts voxel data from MEG sensor space

get_parcel_data: Parcellation of voxel data  

get_behav_data: Extracts keypress indices and labels

get_kp_MEG_data(_post): Extracts epochs of keypress MEG data (sensor/parcel/voxel/hybrid) and corresponding labels

get_op_MEG_data: Extracts epochs of keypress MEG data based on ordinal positions and labels

get_MEG_feat: Extracts features from MEG signals

do_KP_decoding_sensor_post: Sensor space keypress decoding

do_KP_decoding_parcel_post: Parcel space keypress decoding

do_KP_decoding_voxel_post: Voxel space keypress decoding

do_KP_decoding_ROI_post: ROI space keypress decoding

do_KP_decoding_hybrid_ROI_post: Hybrid space (Parcel + Top ROI voxels) keypress decoding

do_KP_decoding_hybrid_ROI_post_forward: Hybrid space keypress decoding with iterative additions of best performing ROIs

do_KP_decoding_hybrid_ROI_post_forward_FS: Hybrid space forward selection of ROI based keypress decoding with feature selection

do_contextuaization: Estimates contextualization of MEG features, performs tsne visualization, and OP1 vs OP5 decoding

do_gaze_analysis: keypress decoding based on gaze

do_rank_estimation: Estimation of rank for different spatial MEG data

getcm: helper function to calculate confusion matrix

import_coil: helper function to read text file generated from brainsight to get MRI coordinates

sourcePlot: helper function to plot topographical MEG plots 