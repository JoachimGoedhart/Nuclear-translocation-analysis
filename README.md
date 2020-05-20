# Nuclear translocation analysis: Quantifying the cytoplasmic to nuclear ratio from timelapse experiments
##### Authors: Sergei Chavez-Abiega and Joachim Goedhart (University of Amsterdam)

Step-by-step instruction to quantify the cytoplasmic to nuclear fluorescence ratio (C/N ratio) from confocal timelapse imaging experiments. The main purpose is to analyze data from translocation reporters that shuttle between the cytoplasm and nucleus. 
This procedure assumes that there is a single fluorescence channel that is used for nuclear segmentation and at least one other channel that is used to measure a reporter. In this example, two reporters are present.
The end-result is a plot that shows the nuclear to cytoplasmic ratio for individual cells over time.


## Preparations

#### Software installation

* Install CellProfiler (https://cellprofiler.org/)
* Install ImageJ (https://imagej.net/) and the Bio-Formats Importer (https://imagej.net/Bio-Formats)
* Install R&RStudio (https://rstudio.com/)


#### Data preparation
 
* In this example, we start from three TIF stacks (see below for a description of the data). These will be split in individual images using ImageJ and saved with specific names that are recognized by CellProfiler.
* To follow the tutorial with your own data, it is recommended to convert your data to (TIF) stacks in ImageJ before you start.


## Data description

Here, we have data from three channels, a red, green and cyan channel. The red channel displays nuclear mScarlet-I, which is used for nuclear segmentation. The green and cyan channels display images of two different biosensors, which is the data that needs to be analyzed. The raw datafiles are in /Images/raw or [click here](https://github.com/JoachimGoedhart/Nuclear-translocation-analysis/tree/master/Images/raw):

* KTR_Red-channel.TIF
* KTR_Green-channel.TIF
* KTR_Cyan-channel.TIF


## Image processing - ImageJ

The purpose of the image processing is to prepare the images, by performing background subtraction, thresholding and saving the data with the right name. The processing steps are specific for this dataset and probably need adjustment when the data is acquired in another way (different cell line, different sensor, different microscope). It is necessary to stick to the filenames as these wil be used later on to identify the data by CellProfiler. The result of this step is stored in the folder [/Images/processed/](https://github.com/JoachimGoedhart/Nuclear-translocation-analysis/tree/master/Images/processed)

#### Image processing for nuclear segmentation

To facilitate segmentation of the nuclei and determine the individual ROIs, it is necessary to process the images so only the nuclei are visible, and there is no background or counts outside the nuclei. Therefore, a background subtraction is performed.

* Open the TIF stack of the red (nuclear) channel in ImageJ
* Use _File > Open..._ and select KTR_Red-Channel.tif
* Subtract a background value to eliminate any cytoplasmic fluorescence, here we subtract 300 counts: _Process > Math > Subtract_ and enter 300
* Save the result as individual images in a new folder (‘processed’), _File > Save as > Image Sequence_ (start at 1) and use the name ‘KTR_nucleus_’
* The result is 27 sequentially numbered TIF images, starting at KTR_nucleus_0001.tif

#### Noise reduction and cell segmentation

To determine the ROIs for the cell body, we use the data from the green channel, because whole cells can be clearly distinguished from the background.

* Open the data for the green channel (KTR_Green-Channel.tif)
* Apply a Gaussian blur with sigma 2 to smoothen the borders and irregularities by: _Process > Filters > Gaussian Blur..._
* Apply a manual threshold from 300 to 65535: _Image > Adjust > Threshold > Set_ (type 300 for the lower threshold level). Then click "Apply", and deselect "Calculate threshold for each image".
* Finally, save the processed nuclear images with the name "KTR_cellmask_" to start at 1, in order to distinguish them from the original images from the folder.
* The result is 27 sequentially numbered TIF images, starting at KTR_cellmask_0001.tif


#### Background Subtraction of Cyan images

Before we use the imaging data to quantify the nuclear to cytoplasmic ratio, we need to apply the ImageJ built-in function Background Subtraction (which applies a Rolling Ball correction) to the cyan channel.

* Open the data for the cyan channel (KTR_Cyan-Channel.tif)
* Apply the background correction (enter 70 pixels): _Process -> Subtract Background_
* Save the result as individual images in a new folder (‘processed’), _File > Save as > Image Sequence_ (start at 1)
* The result is 27 sequentially numbered TIF images, starting at KTR_Cyan-Channel_0001.tif


#### Preparing the Green Images

For this specific dataset, it is not necessary to background correct the green channel. But we still need to prepare the data in such a way that it can be handled by CellProfiler. To this end, we split the stack and save the individual images.

* Open the data for the green channel (KTR_Green-Channel.tif)
* Save the result as individual images in a new folder (‘processed’), _File > Save as > Image Sequence_ (start at 1)
* The result is 27 sequentially numbered TIF images, starting at KTR_Green-Channel_0001.tif


## Image analysis - CellProfiler

The purpose of the CellProfiler pipeline is to identify the nuclei in the red channel and create a mask, segment the cell bodies in the green channel en to prepare a mask for the cytoplasm (by 'subtracting' the mask of the nuclei from the mask of the cell body). The intensity of each object is be quantified and the ratio of cytoplasm over nucleus is determined for each object (cell) over time. The result is a large list of quantified parameters in CSV format. The result of this step is stored in the folder [/CP_output/](https://github.com/JoachimGoedhart/Nuclear-translocation-analysis/tree/master/CP_Output)

* Open CellProfiler, and import the pipeline: _File > Import > Pipeline from file_ and select the file 'KTR-analysis.cppipe' (located in the folder CP_output)
* Go to the step "Images", and add all the images from the folder /Images/processed/ by drag-and-drop.
* Change the location where the files will be saved to the folder of choice, in Sub-folder, both in the last two steps "SaveImages" and "ExportToSpreadsheet".
* By default, CellProfiler rescales the intensity values per pixel between 0 to 1, with 1 corresponding to the maximum given the bit depth. Our unprocessed images have a depth of 12-bit (0-4096), but ImageJ does not support 12-bit, so it converts them to 16-bit (0-65536).
* Click "Analyze Images" and wait until the analysis is done (a couple of minutes for the example dataset).

## Filtering the data with R

The CellProfiler pipeline generates multiple files, among which "Nuclei.csv" and "Cytoplasm.csv". These CSV files are large (35-40 MB) due to the high number of cells and the information contained in the multiple features, most of which are not necessary for our analysis. But these files do include the calculated fluorescence cytoplasmic to nuclear ratios (CN), which is the read-out we are interested in. Selection of the relevant features/measurements can be done in CellProfiler, but here we use an R-script to clean the data. The R-script will load the CSV files, filter the data and store the result as new CSV file. The result of this step is stored in the folder [/R_output/](https://github.com/JoachimGoedhart/Nuclear-translocation-analysis/tree/master/R_Output)

* The R-script ‘CP_data_filter.R’ can be saved in a folder ‘R_output’.
* Open the R-script in RStudio and set the working directory: _Session > Set Working Directory > To Source File Location_
* Comments in the R-script explain each steps. Briefly, the CSV files are loaded, and only objects (cells) are selected that have reasonable size and intensity and can be found in all frames are selected.
* Running the R-script will yield two CSV files in the working directory: "Nuclei_filtered.csv" and "Cytoplasm_filtered.csv".

## Data visualization with PlotTwist

* The cleaned data can be visualized with the open source tool PlotTwist.
* First, use "Upload" to open one of the csv files generated by the R script. Here, we use ‘Cytoplasm_filtered.csv’.
* Check "These data are Tidy", and select "Time_in_min" for x-axis, "ObjectLabel" as identifier of samples, and "Math_RatioGreen"  for showing the nuclear/cytoplasmic ratios of the KTR in the green channel.
* After clicking the ‘Plot’ tab, you  will see the following figure:


[alt text](https://github.com/JoachimGoedhart/Nuclear-translocation-analysis/blob/master/PlotTwist_Output/PlotTwist_1.png)

* Finally, it is possible to adjust the plot to help clear visualization of the data. It is also suggested to normalize the data to the baseline (first 5 images in this case) in the tab Data upload. The following link includes pre-selected settings to visualize the data from the ERK traces, and the figure shows the result. First you need to copy and paste the link in the web explorer, and then repeat the steps of uploading the data and selecting the x/y-axes and the sample identifier.




https://huygens.science.uva.nl:/PlotTwist/?data=3;TRUE;TRUE;diff;1,5;&vis=dataasline;0.15;TRUE;TRUE;1;;&layout= ;;TRUE;;-0.15,1.5;TRUE;;6;X;480;600&color=none&label=;;TRUE;time (min);change in C/N ratio;;24;24;18;8;;;&stim=TRUE;bar;25,120;Stimulation;&



[![alt text](https://github.com/JoachimGoedhart/Nuclear-translocation-analysis/blob/master/PlotTwist_Output/PlotTwist_2.png)]


[![alt text](https://github.com/JoachimGoedhart/Nuclear-translocation-analysis/blob/master/PlotTwist_Output/PlotTwist_3.png)]


#### Possible improvements
If there is crossexcitation and bleedthrough between the imaged fluorescent proteins, the individual signals need to be unmixed. This can be done using an unmixing matrix with values calculated from imaging the individual FPs under the same imaging conditions than the experimental sample. In our case, the percentages of bleedthrough under our imaging conditions were very low and their impact on the results are negligible.

#### Issues/feedback
In case of feedback or questions you can:
* contact the authors on twitter: [@joachimgoedhart](https://twitter.com/joachimgoedhart) or [@SAbiega](https://twitter.com/SAbiega)
* Open an [issue on Github](https://github.com/JoachimGoedhart/Nuclear-translocation-analysis/issues)

#### This guide has been tested with the following version:
* CellProfiler 3.1.9
* FIJI/ ImageJ 2.0.0-rc-69/1.52v (https://imagej.net/Welcome)
* RStudio Version 1.1.463 (https://rstudio.com/) & R 3.6.1







