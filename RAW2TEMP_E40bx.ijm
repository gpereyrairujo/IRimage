/////////////////////////////////////////////////////////////////////////////////////////////////////////
// ImageJ macro for converting raw thermal png files from FLIR cameras to temperature values in degrees C
// Author: Gustavo Pereyra Irujo - pereyrairujo.gustavo@conicet.gov.ar
// Licensed under GNU GENERAL PUBLIC LICENSE Version 3
// https://github.com/gpereyrairujo/IR_image_analysis

// Ask for the directory of files to process

dir = getDirectory("Choose a Directory ");

// Ask for camera parameters

//// Default values for FLIR E40bx

Dialog.create("Parameters");
	Dialog.addNumber("Planck R1", 14748.045, 3, 12,"");
	Dialog.addNumber("Planck B", 1393.3,1,12,"");
	Dialog.addNumber("Planck F", 1,1,12,"");
	Dialog.addNumber("Planck O", -5790,1,12,"");
	Dialog.addNumber("Planck R2", 0.011027409,9,12,"");

	Dialog.addNumber("Alpha1", 0.006569,6,12,"");
	Dialog.addNumber("Alpha2", 0.01262,6,12,"");
	Dialog.addNumber("Beta1", -0.002276,6,12,"");
	Dialog.addNumber("Beta2", -0.006670,6,12,"");
	Dialog.addNumber("X", 1.9,6,12,"");

	Dialog.addNumber("refl_temp_c", -20,0,5,"C");
	Dialog.addNumber("emissivity", 0.99,2,5,"");
	Dialog.addNumber("atm_temp_c", 23,0,5,"C");
	Dialog.addNumber("humidity", 0.43,2,5,"");
	Dialog.addNumber("distance", 1,0,5,"m");

	Dialog.addCheckbox("Little-endian byte order", false);

	Dialog.show();

//// Default values for FLIR One - first generation
//
//Dialog.create("Parameters");
//	Dialog.addNumber("Planck R1", 17467.391, 3, 12,"");
//	Dialog.addNumber("Planck B", 1444.1,1,12,"");
//	Dialog.addNumber("Planck F", 1,1,12,"");
//	Dialog.addNumber("Planck O", -3094,1,12,"");
//	Dialog.addNumber("Planck R2", 0.013138425,9,12,"");
//
//	Dialog.addNumber("Alpha1", 0.006569,6,12,"");
//	Dialog.addNumber("Alpha2", 0.01262,6,12,"");
//	Dialog.addNumber("Beta1", -0.002276,6,12,"");
//	Dialog.addNumber("Beta2", -0.006670,6,12,"");
//	Dialog.addNumber("X", 1.9,6,12,"");
//
//	Dialog.addNumber("refl_temp_c", 20,0,5,"C");
//	Dialog.addNumber("emissivity", 0.95,2,5,"");
//	Dialog.addNumber("atm_temp_c", 20,0,5,"C");
//	Dialog.addNumber("humidity", 0.50,2,5,"");
//	Dialog.addNumber("distance", 1,0,5,"m");
//
//	Dialog.addCheckbox("Little-endian byte order", true);
//
//	Dialog.show();

// Get values from dialog box

PlanckR1=Dialog.getNumber();
PlanckB=Dialog.getNumber()
PlanckF=Dialog.getNumber();
PlanckO=Dialog.getNumber();
PlanckR2=Dialog.getNumber();

Alpha1=Dialog.getNumber();
Alpha2=Dialog.getNumber();
Beta1=Dialog.getNumber();
Beta2=Dialog.getNumber();
X=Dialog.getNumber();

refl_temp_c=Dialog.getNumber();
emissivity=Dialog.getNumber();
atm_temp_c=Dialog.getNumber();
humidity=Dialog.getNumber();
distance=Dialog.getNumber();

endian=Dialog.getCheckbox();

Refl_Temp=refl_temp_c+273.15;
Air_Temp=atm_temp_c+273.15;

h2o=humidity * exp(1.5587 + 0.06939 * atm_temp_c - 0.00027816 * pow(atm_temp_c,2) + 0.00000068455 *pow(atm_temp_c,3));
tau=X * exp(-pow(distance,0.5) * (Alpha1 + Beta1 * pow(h2o,0.5))) + (1-X) * exp(-pow(distance,0.5) * (Alpha2 + Beta2 * pow(h2o,0.5)));
RAW_Atm=PlanckR1/(PlanckR2*(exp(PlanckB/(Air_Temp))-PlanckF))-PlanckO;
RAW_refl=PlanckR1/(PlanckR2*(exp(PlanckB/(Refl_Temp))-PlanckF))-PlanckO;

// Process files

    list = getFileList(dir);
    run("Close All");
    setOption("display labels", true);
    setBatchMode(true);
    for (i=0; i<list.length; i++) {
        path = dir+list[i];
        showProgress(i, list.length);
        IJ.redirectErrorMessages();
        open(path);
        if (nImages>0) {

		run("32-bit");

		w = getWidth;
		h = getHeight;

		for (y=0; y<h; y++) {
			for (x=0; x<w; x++) {

				S = getPixel(x,y);

				if (endian==true) {
					S=(S-(S%256))/256+(S%256)*256;
					}

				RAW_obj=(S-RAW_Atm*(1-tau)-RAW_refl*(1-emissivity)*tau)/emissivity/tau;
				T=PlanckB/log(PlanckR1/(PlanckR2*(RAW_obj+PlanckO))+PlanckF)-273.15;

				setPixel(x,y,T);

				}
			}

		resetMinAndMax;


	}
	run("Set Measurements...", "  mean standard min median display redirect=None decimal=3");
	run("Measure");
	saveAs("tiff",path);
         run("Close All");
    }


