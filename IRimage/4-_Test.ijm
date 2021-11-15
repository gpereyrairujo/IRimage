////////////////////////////////////////////////////////////////////////////////////////////////////////
// IRimage
//
// ImageJ code for processing thermal images from FLIR cameras
// - Converts radiometric JPG files to temperature values in degrees C
// - Generates false color images from previously converted thermal images
// - Compares temperature values from thermal images exported with FLIR Tools or exported with IRimage
//
// Author: Gustavo Pereyra Irujo - pereyrairujo.gustavo@conicet.gov.ar
// Licensed under GNU AFFERO GENERAL PUBLIC LICENSE Version 3
// https://github.com/gpereyrairujo/IRimage
//


////////////////////////////////////////////////////////////////////////////////////////////////////////
// Function for comparing temperature values exported with IRimage with those from other software
// -----------------------------------------------------------------------------------------------------
// 1. Ask for the directory of files to process
// 2. File processing
//   2.1. Open CSV file (FLIR Tools data)
//   2.2. Open corresponding TXT file (IRimage data)
//   2.3. Read temperature values
// 3. Outputs
//   3.1. Print temperature difference statistics
//   3.2. Save results text file
//   3.3. Plot values
//   3.4. Save plot image
// 4. Close images
// -----------------------------------------------------------------------------------------------------

macro "IR-image-test" {

// 1. Ask for the directory of files to process
	dir = getDirectory("Select the thermal images folder");
	dirTEXT = dir+"text"+File.separator;
	dirCSV = dir+"csv"+File.separator;
	dirRESULTS = dir+"results"+File.separator;

	
// 2. File processing
    list = getFileList(dirCSV);
    for (f=0; f<list.length; f++) {
		showProgress(f, list.length);
		setBatchMode(true);

// 2.1. Open CSV file (FLIR Tools data)
		iscsv=false;
		do {
			imageName=list[f];
			if( endsWith(imageName,"csv") ) iscsv=true;
			if( endsWith(imageName,"CSV") ) iscsv=true;
			if(iscsv==false) f++;
			if(f>=list.length) exit;
		} while (iscsv==false);
		path1 = dirCSV+imageName;
	    run("Text Image... ", "open=["+path1+"]");
	    file1=File.name;

// 2.2. Open corresponding TXT file (IRimage data)
		path2 = dirTEXT + substring(imageName, 0, lastIndexOf(imageName, ".")) + ".txt";		// open corresponding IRimage TXT file
	    run("Text Image... ", "open=["+path2+"]");
	    file2=File.name;

// 2.3. Read temperature values
		selectWindow(file1);
		w = getWidth;
		h = getHeight;

		i = 0;
		data1 = newArray(w*h);
		data2 = newArray(w*h);
		diffAboveThreshold=0;
		diffSum=0;
		diffCount=0;

		for (y=0; y<h; y++) {
			for (x=0; x<w; x++) {
				selectWindow(file1);
				data1[i] = getPixel(x,y);		// get temperature value in image 1
				selectWindow(file2);
				data2[i] = getPixel(x,y);		// get temperature value in image 2

				difference = abs(data2[i]-data1[i]);
				if (data1[i]>=-40) {		// exclude values below -40C
					if (difference > 0.01) diffAboveThreshold++;	// count temperature differences below 0.005 C
					diffSum=diffSum+difference;
					diffCount++;	// count total temperature differences analyzed
				}

				i++;
			}
		}


// 3. Outputs

// 3.1. Print temperature difference statistics
		print("\\Clear");
		print(file1,"vs.",file2);
		print("Excluded pixels with temperature below -40 C:", (1-(diffCount/(w*h)))*100,"%");
		print("Average temperature difference:", diffSum/diffCount," C");
		print("Temperature differences above 0.01 C:", diffAboveThreshold/diffCount*100,"%");

// 3.2. Save results text file
		logpath = dirRESULTS + "test_" + substring(imageName, 0, lastIndexOf(imageName, ".")) + ".txt";
		selectWindow("Log");
		saveAs("Text", logpath);

// 3.3. Plot values
		Plot.create("Plot", "X-axis Label", "Y-axis Label");
		Plot.setFrameSize(280, 280);
		Plot.setFontSize(20, "options");
		Plot.setLimits(-100, 200, -100, 200);
		Plot.setXYLabels("Temperature, C (Reference)", "Temperature, C (IRimage)");
		Plot.drawLine(-100, -100, 200, 200);
		Plot.setColor("blue");
		Plot.setLineWidth(3);
		Plot.add("circle", data1, data2);
		Plot.show();

// 3.4. Save plot image
		selectWindow("Plot");
		plotpath = dirRESULTS + "test_plot_" + substring(imageName, 0, lastIndexOf(imageName, ".")) + ".png";
		saveAs("png", plotpath);


// 4. Close images
		run("Close All");
		setBatchMode(false);
    }
}


