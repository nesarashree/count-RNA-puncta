# An open-source image analysis pipeline for single-cell mRNA puncta quantification and colocalization
This repository provides a reproducible, batch-analysis pipeline for quantifying mRNA puncta in confocal microscopy images, designed for experiments with excitatory (VGLUT) and inhibitory (GAD) neuron cell-type masks. The pipeline enables accurate detection, segmentation, and per-cell analysis of mRNA puncta, facilitating high-throughput analysis of RNAscope datasets.

**Features**
* **Classifier-based** puncta detection: Trained machine learning models identify and segment mRNA puncta across multiple genes, learning specific visual features for each, in RNAscope images.
* Designed for **batch analysis**: Process large datasets of images reproducibly and efficiently.
* **Quantification / colocalization metrics**: Creates count masks for puncta quantification (e.g. area, total count) and loads excitatory (VGLUT) and inhibitory (GAD) masks to compute colocalization metrics per cell (e.g. mean puncta per cell, # non-coloc puncta, density, etc.)
* **MATLAB GUI**: Features packaged into a user-friendly interface for visualizing results and exporting numeric data (CSV) for downstream analysis and graphing.
* Flexible application! Designed for adaptation to additional genes, cell types, or imaging modalities.

## WEKA Trainable Classifier Integration (FIJI)
The FIJI Trainable Weka Segmentation (TWS) plugin integrates the image-processing framework of FIJI with the machine learning algorithms of WEKA to enable supervised and unsupervised image segmentation. Using a limited set of user-provided pixel annotations, TWS extracts multiscale image features and trains a classifier that can be interactively refined to segment complex biological images.
