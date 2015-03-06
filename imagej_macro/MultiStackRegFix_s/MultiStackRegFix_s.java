/*====================================================================	
|  Version 22 Feb 2013, Dmytro S. Lituiev, University of Zurich
|  based on the "MultiStackRegFix " Version: April 27, 2008
\===================================================================*/

/** Usage:
 *** MultiStackRegFix is the same as MultiStackReg except it is designed to be used to do
 *** Rigid Body Stack Alignments where the transformation matrices is saved OR to align
 *** using a transformation matrix (presumably from the Rigid Body alignment).  To acheive
 *** these goals it has been altered to accept a string that starts with 1 to indicate Rigid
 *** body alignment & saving the transforms where default place for saving is passed in after
 *** the integer 1.  The second type of alignment is indicated by 4 to indicate that one wants
 *** to align using saved transforms and the default place to look for the transformation matrix
 *** is passed in after the integer 4.  In addition, a text file named xAlign.txt is written out
 *** so that the user can determine if the alignment ran to completion.  This file contains '1'
 *** if the alignment ran to completion or '0' if it did not.  In addition, the tranformation
 *** matrices file now contains the number of images in the stack and their dimensions as to allow
 *** a little error checking if users want to use the transformation file at a later period in time
 *** finally some of the IJ.error() messages have been replaced with IJ.log() so that if this
 *** plugin is used from the ImageJ macro facility such errors don't cancel the running of the ImageJ
 *** macro.  These changes were implemented by Jennifer Staab and Ping Fu using Brad Busse's MultiStackReg
 *** found at < http://www.stanford.edu/~bbusse/work/downloads.html > plugin as a base.  
 *** MultiStackReg is itself based on StackReg written by Philippe Thevenaz found at
 *** < http://bigwww.epfl.ch/thevenaz/stackreg/ >
 *
 *
 * MultiStackReg can align a stack to itself, as in regular StackReg, or one stack to another.
 *
 * To align one stack to another, place the reference stack in the first slot, and the stack to be 
 * aligned in the second.  MultiStackReg will align each slice of the second stack to the 
 * corresponding slice in the first stack.  Note that both stacks must be the same length.
 *
 * To align a single stack, place it in the first slot and nothing in the second.  Each slice will 
 * be aligned as in normal stackreg.
 *
 * The save checkbox can be used to save the transformation matrix alignment results in,
 * and the load dropdown will apply a previously saved matrix to the selected stack.
 */

/*====================================================================
| EPFL/STI/IOA/LIB
| Philippe Thevenaz
| Bldg. BM-Ecublens 4.137
| Station 17
| CH-1015 Lausanne VD
| Switzerland
|
| phone (CET): +41(21)693.51.61
| fax: +41(21)693.37.01
| RFC-822: philippe.thevenaz@epfl.ch
| X-400: /C=ch/A=400net/P=switch/O=epfl/S=thevenaz/G=philippe/
| URL: http://bigwww.epfl.ch/
\===================================================================*/

/*====================================================================
| This work is based on the following paper:
|
| P. Thevenaz, U.E. Ruttimann, M. Unser
| A Pyramid Approach to Subpixel Registration Based on Intensity
| IEEE Transactions on Image Processing
| vol. 7, no. 1, pp. 27-41, January 1998.
|
| This paper is available on-line at
| http://bigwww.epfl.ch/publications/thevenaz9801.html
|
| Other relevant on-line publications are available at
| http://bigwww.epfl.ch/publications/
\===================================================================*/

/*====================================================================
| Additional help available at http://bigwww.epfl.ch/thevenaz/stackreg/
| Ancillary TurboReg_ plugin available at: http://bigwww.epfl.ch/thevenaz/turboreg/
|
| You'll be free to use this software for research purposes, but you
| should not redistribute it without our consent. In addition, we expect
| you to include a citation or acknowledgment whenever you present or
| publish results that are based on it.
\===================================================================*/

/* A few small changes (loadTransform, appendTransform, multi stack support) to 
 * support load/save functionality and multiple stacks were added by Brad Busse 
 * (  bbusse@stanford.edu ) and released into the public domain, so go by
 * their ^^ guidelines for distribution, etc.
 */

// ImageJ
import ij.IJ;
import ij.Macro;
import ij.ImagePlus;
import ij.WindowManager;
import ij.gui.GUI;
import ij.gui.GenericDialog;
import ij.io.FileSaver;
import ij.plugin.PlugIn;
import ij.process.Blitter;
import ij.process.ByteProcessor;
import ij.process.ColorProcessor;
import ij.process.FloatProcessor;
import ij.process.ImageConverter;
import ij.process.ShortProcessor;

// Java 1.1
import java.awt.BorderLayout;
import java.awt.Button;
import java.awt.Choice;
import java.awt.Dialog;
import java.awt.FileDialog;
import java.awt.FlowLayout;
import java.awt.Frame;
import java.awt.GridLayout;
import java.awt.Insets;
import java.awt.Label;
import java.awt.Panel;
import java.awt.TextArea;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.image.IndexColorModel;
import java.io.FileReader;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.BufferedReader;
import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.Stack;
import java.util.Vector;
import java.util.*;
import java.io.StreamTokenizer;
import java.io.StringReader;

/*====================================================================
|	StackReg_
\===================================================================*/

/********************************************************************/
public class MultiStackRegFix_s
	implements
		PlugIn

{ /* begin class StackReg_ */

/*....................................................................
	Private global variables
....................................................................*/
private static final double TINY = (double)Float.intBitsToFloat((int)0x33FFFFFF);
private String loadPathAndFilename;
private String savePath;
private String saveFile;
private int transformNumber;
private int tSlice;
private boolean saveTransform;
private boolean twoStackAlign;
private boolean loadSingleMatrix;
private ImagePlus srcImg;
private ImagePlus tgtImg;	
private int n_Slices;
private int width_Slices;
private int height_Slices;
private String saveXPath;
private String xPathFile;
private boolean inputVals;
private int transformation;
/*....................................................................
	Public methods
....................................................................*/

/********************************************************************/
public void run (
	final String arg
) {
	inputVals=false;
	String options = Macro.getOptions();
	String myS="";
	if(options != null){
		myS=options;
  }
  //separate steps for use with macros/pluggin inputs
	if(!arg.equals("") || !myS.equals("")){
		 inputVals=true;
		 if(!arg.equals("")){
		 myS=arg;
		 }
	   transformation=(new Integer(myS.substring(0,1).trim())).intValue();
	   saveXPath=myS.substring(2,myS.length()).trim();
	   if(transformation==1){
		    saveTransform=true;
	   }
	   else{
		   saveTransform=false;
     }
	   //outputs file to check alignment
	   xPathFile=saveXPath+"xAlign.txt";
	   try{
		    FileWriter xfile= new FileWriter(xPathFile);
		    xfile.write("0");
		    xfile.close();
		 }catch(IOException e){}
	}
	
	loadPathAndFilename="";
	savePath="";
	transformNumber=0;
	Runtime.getRuntime().gc();
	
	final ImagePlus[] admissibleImageList = createAdmissibleImageList();
	final String[] sourceNames = new String[admissibleImageList.length];
	for (int k = 0; (k < admissibleImageList.length); k++) {
		sourceNames[k]=admissibleImageList[k].getTitle();
	}
	
	final String[] targetNames = new String[admissibleImageList.length];
	for (int k = 0; (k < admissibleImageList.length); k++) {
		targetNames[k]=admissibleImageList[k].getTitle();
	}
	
	
	ImagePlus imp = WindowManager.getCurrentImage();
	if (imp == null) {
		IJ.error("No image available");
		return;
	}
	else {
	   n_Slices = imp.getImageStackSize();
	   width_Slices = imp.getWidth();
	   height_Slices = imp.getHeight();
  }
	
	final String[] transformationItem = {
		"Translation",
		"Rigid Body",
		"Scaled Rotation",
		"Affine",
		"Load Transformation File"
	};
 //Runs GUI to get input info since information wasn't input using a Macro/Pluggin
  if(inputVals==false){
		GenericDialog gd = new GenericDialog("MultiStackReg");
                 	gd.addChoice("First Stack:", sourceNames, admissibleImageList[0].getTitle());
		gd.addChoice("Second Stack:", targetNames, admissibleImageList[0].getTitle());
		gd.addChoice("Transformation:", transformationItem, "Rigid Body");
		gd.addCheckbox("Align Second Stack To First", false);
		gd.addCheckbox("Save Transformation File", false);
		gd.addCheckbox("View Manual Instead", false);
		gd.addStringField("Load From/Save To:", "");

	  gd.showDialog();
	  if (gd.wasCanceled()) {
	    return;
   	}
	  srcImg = admissibleImageList[gd.getNextChoiceIndex()];
	  tgtImg = admissibleImageList[gd.getNextChoiceIndex()];
	  imp=srcImg;
	  transformation = gd.getNextChoiceIndex();
	  twoStackAlign = gd.getNextBoolean();

	  saveXPath=gd.getNextString();	

	  if (twoStackAlign){ //we want to do two-stack alignment, check that the stacks are compatible
	    if (srcImg.getImageStackSize() != tgtImg.getImageStackSize()){
	      IJ.error("Stack sizes must match.");
	      return;
	    }
	    if (srcImg.getHeight() != tgtImg.getHeight() || srcImg.getWidth() != tgtImg.getWidth()){
	      IJ.error("Stack dimensions must match.");
	      return;
	    }		
 	    if (srcImg.getType() != tgtImg.getType()){
	      IJ.error("Stack image types must match.");
	      return;
	    }
	  }
	  saveTransform = gd.getNextBoolean();
	  if (gd.getNextBoolean()) {
	    final multiStackRegCredits dialog = new multiStackRegCredits(IJ.getInstance());
	    GUI.center(dialog);
	    dialog.setVisible(true);
	    return;
	  }
	  //outputs file to check alignment
	  xPathFile=saveXPath+"xAlign.txt";
	  try{
	    FileWriter xfile= new FileWriter(xPathFile);
	    xfile.write("0");
	    xfile.close();
	   }catch(IOException e){}
 }
 //Sets required variables when GUI isn't run (for macros & pluggins(
 else{
	 srcImg = admissibleImageList[0];
	 tgtImg = admissibleImageList[0];
	 imp=srcImg;
	 twoStackAlign = false;
 }

	if(transformation==5){
		loadPathAndFilename=saveXPath;
		int tgt=loadTransform(0,null,null);
		transformation = loadTransform(1, null, null);
		if(transformation==-1){
		  return;
	 	 }
		imp.setSlice(tgt);
	}

	if (transformation==4) {
		final Frame t = new Frame();
		final FileDialog fl = new FileDialog( t, "Load transformation file", FileDialog.LOAD);
		fl.setDirectory(saveXPath);
		fl.setVisible(true);
		if (fl.getFile() == null){
			IJ.error("Action cancelled");
			return;
		}
		loadPathAndFilename = fl.getDirectory()+fl.getFile();
		int tgt = loadTransform(0, null, null);
		transformation = loadTransform(1, null, null);
		if(transformation==-1){
		  return;
	  }
		imp.setSlice(tgt);
	}
	final int width = imp.getWidth();
	final int height = imp.getHeight();
	final int targetSlice = imp.getCurrentSlice();
	tSlice=targetSlice;
	double[][] globalTransform = {
		{1.0, 0.0, 0.0},
		{0.0, 1.0, 0.0},
		{0.0, 0.0, 1.0}
	};
	double[][] anchorPoints = null;
	switch (transformation) {
		case 0: {
			anchorPoints = new double[1][3];
			anchorPoints[0][0] = (double)(width / 2);
			anchorPoints[0][1] = (double)(height / 2);
			anchorPoints[0][2] = 1.0;
			break;
		}
		case 1: {
			anchorPoints = new double[3][3];
			anchorPoints[0][0] = (double)(width / 2);
			anchorPoints[0][1] = (double)(height / 2);
			anchorPoints[0][2] = 1.0;
			anchorPoints[1][0] = (double)(width / 2);
			anchorPoints[1][1] = (double)(height / 4);
			anchorPoints[1][2] = 1.0;
			anchorPoints[2][0] = (double)(width / 2);
			anchorPoints[2][1] = (double)((3 * height) / 4);
			anchorPoints[2][2] = 1.0;
			break;
		}
		case 2: {
			anchorPoints = new double[2][3];
			anchorPoints[0][0] = (double)(width / 4);
			anchorPoints[0][1] = (double)(height / 2);
			anchorPoints[0][2] = 1.0;
			anchorPoints[1][0] = (double)((3 * width) / 4);
			anchorPoints[1][1] = (double)(height / 2);
			anchorPoints[1][2] = 1.0;
			break;
		}
		case 3: {
			anchorPoints = new double[3][3];
			anchorPoints[0][0] = (double)(width / 2);
			anchorPoints[0][1] = (double)(height / 4);
			anchorPoints[0][2] = 1.0;
			anchorPoints[1][0] = (double)(width / 4);
			anchorPoints[1][1] = (double)((3 * height) / 4);
			anchorPoints[1][2] = 1.0;
			anchorPoints[2][0] = (double)((3 * width) / 4);
			anchorPoints[2][1] = (double)((3 * height) / 4);
			anchorPoints[2][2] = 1.0;
			break;
		}
		default: {
			IJ.error("Unexpected transformation");
			return;
		}
	}
	ImagePlus source = null;
	ImagePlus target = null;
	double[] colorWeights = null;
	switch (imp.getType()) {
		case ImagePlus.COLOR_256:
		case ImagePlus.COLOR_RGB: {
			colorWeights = getColorWeightsFromPrincipalComponents(imp);
			imp.setSlice(targetSlice);
			target = getGray32("StackRegTarget", imp, colorWeights);
			break;
		}
		case ImagePlus.GRAY8: {
			target = new ImagePlus("StackRegTarget",
				new ByteProcessor(width, height, new byte[width * height],
				imp.getProcessor().getColorModel()));
			target.getProcessor().copyBits(imp.getProcessor(), 0, 0, Blitter.COPY);
			break;
		}
		case ImagePlus.GRAY16: {
			target = new ImagePlus("StackRegTarget",
				new ShortProcessor(width, height, new short[width * height],
				imp.getProcessor().getColorModel()));
			target.getProcessor().copyBits(imp.getProcessor(), 0, 0, Blitter.COPY);
			break;
		}
		case ImagePlus.GRAY32: {
			target = new ImagePlus("StackRegTarget",
				new FloatProcessor(width, height, new float[width * height],
				imp.getProcessor().getColorModel()));
			target.getProcessor().copyBits(imp.getProcessor(), 0, 0, Blitter.COPY);
			break;
		}
		default: {
			IJ.error("Unexpected image type");
			return;
		}
	}
	//we've specified a file to load.  Load it, process it
	String path="";
	if (loadPathAndFilename!=""){
	}else if (saveTransform){
	////////////////////////////////////////////
	if (options == null){
		final Frame f = new Frame();
		final FileDialog fd = new FileDialog( f, "Save transformations at", FileDialog.SAVE);
		fd.setDirectory(saveXPath);
		String filename = "TransformationMatrices.txt";
		fd.setFile(filename);
		fd.setVisible(true);
		path = fd.getDirectory()+fd.getFile();
		IJ.showMessage("the path is "+path);
		savePath=fd.getDirectory();		
		saveFile=fd.getFile();
		}
    else {
	savePath = saveXPath;
	saveFile = "TransformationMatrices.txt";
	path = savePath+saveFile;
	};
		try{
			FileWriter fw= new FileWriter(path);
			fw.write("MultiStackReg Transformation File\n");
			fw.write(n_Slices+" "+width_Slices+" "+height_Slices+" File Version 1.0\n");
			if (twoStackAlign)
				fw.write("1\n");
			else 
				fw.write("0\n");
			fw.close();
		}catch(IOException e){}
	}
	if (twoStackAlign){
		target = getSlice(imp,targetSlice);
		source = registerSlice(source, target, tgtImg, width, height,
			transformation, globalTransform, anchorPoints, colorWeights, targetSlice);
		if (source == null) {
			tgtImg.setSlice(targetSlice);
			return;
		}
	}
	if (loadSingleMatrix){
		source = registerSlice(source, target, imp, width, height,
			transformation, globalTransform, anchorPoints, colorWeights, targetSlice);
		if (source == null) {
			tgtImg.setSlice(targetSlice);
			return;
		}
	}
	for (int s = targetSlice - 1; (0 < s); s--) {
		if (twoStackAlign){ 
			globalTransform[0][0] = globalTransform[1][1] = globalTransform[2][2] = 1.0;
			globalTransform[0][1] = globalTransform[0][2] = globalTransform[1][0] = 0.0;
			globalTransform[1][2] = globalTransform[2][0] = globalTransform[2][1] = 0.0;
			target = getSlice(imp,s);
			source = registerSlice(source, target, tgtImg, width, height,
				transformation, globalTransform, anchorPoints, colorWeights, s);
			if (source == null) {
				tgtImg.setSlice(targetSlice);
				return;
			}
		}else{ 
			if (loadSingleMatrix){ //with one transformation only, we need to reset the global transform each time
				globalTransform[0][0] = globalTransform[1][1] = globalTransform[2][2] = 1.0;
				globalTransform[0][1] = globalTransform[0][2] = globalTransform[1][0] = 0.0;
				globalTransform[1][2] = globalTransform[2][0] = globalTransform[2][1] = 0.0;
			}
			source = registerSlice(source, target, imp, width, height,
				transformation, globalTransform, anchorPoints, colorWeights, s);
			if (source == null) {
				imp.setSlice(targetSlice);
				return;
			}
		}
	}
	if ((1 < targetSlice) && (targetSlice < imp.getStackSize())) {
		globalTransform[0][0] = 1.0;
		globalTransform[0][1] = 0.0;
		globalTransform[0][2] = 0.0;
		globalTransform[1][0] = 0.0;
		globalTransform[1][1] = 1.0;
		globalTransform[1][2] = 0.0;
		globalTransform[2][0] = 0.0;
		globalTransform[2][1] = 0.0;
		globalTransform[2][2] = 1.0;
		imp.setSlice(targetSlice);
		switch (imp.getType()) {
			case ImagePlus.COLOR_256:
			case ImagePlus.COLOR_RGB: {
				target = getGray32("StackRegTarget", imp, colorWeights);
				break;
			}
			case ImagePlus.GRAY8:
			case ImagePlus.GRAY16:
			case ImagePlus.GRAY32: {
				target.getProcessor().copyBits(imp.getProcessor(), 0, 0, Blitter.COPY);
				break;
			}
			default: {
				IJ.log("Unexpected image type");
				return;
			}
		}
	}
	for (int s = targetSlice + 1; (s <= imp.getStackSize()); s++) {
		if (twoStackAlign){ 
			globalTransform[0][0] = globalTransform[1][1] = globalTransform[2][2] = 1.0;
			globalTransform[0][1] = globalTransform[0][2] = globalTransform[1][0] = 0.0;
			globalTransform[1][2] = globalTransform[2][0] = globalTransform[2][1] = 0.0;
			target = getSlice(imp,s);
			source = registerSlice(source, target, tgtImg, width, height,
				transformation, globalTransform, anchorPoints, colorWeights, s);
			if (source == null) {
				tgtImg.setSlice(targetSlice);
				return;
			}
		}else{
			if (loadSingleMatrix){ //with one transformation only, we need to reset the global transform each time
				globalTransform[0][0] = globalTransform[1][1] = globalTransform[2][2] = 1.0;
				globalTransform[0][1] = globalTransform[0][2] = globalTransform[1][0] = 0.0;
				globalTransform[1][2] = globalTransform[2][0] = globalTransform[2][1] = 0.0;
			}
			source = registerSlice(source, target, imp, width, height,
				transformation, globalTransform, anchorPoints, colorWeights, s);
			if (source == null) {
				imp.setSlice(targetSlice);
				return;
			}
		}
	}
	imp.setSlice(targetSlice);
	imp.updateAndDraw();
	
  // outputs file to indicate completion of alignment program
  try{
		   FileWriter xfile2= new FileWriter(xPathFile);
		   xfile2.write("1");
	    xfile2.close();
	}catch(IOException e){}
} /* end run */

/*....................................................................
	Private methods
....................................................................*/

private ImagePlus getSlice(ImagePlus imp, int index){
	final int width = imp.getWidth();
	final int height = imp.getHeight();
	ImagePlus out = new ImagePlus("StackRegTarget",
				new ByteProcessor(width, height, new byte[width * height],
				imp.getProcessor().getColorModel()));
	imp.setSlice(index);
	double[] colorWeights = null;
	switch (imp.getType()) {
		case ImagePlus.COLOR_256:
		case ImagePlus.COLOR_RGB: {
			out = getGray32("StackRegTarget", imp, colorWeights);
			break;
		}
		case ImagePlus.GRAY8:
		case ImagePlus.GRAY16:
		case ImagePlus.GRAY32: {
			out.getProcessor().copyBits(imp.getProcessor(), 0, 0, Blitter.COPY);
			break;
		}
		default: {
			IJ.log("Unexpected image type");
			out = null;
		}
	}
	return out;
}

/*------------------------------------------------------------------*/
//This is kind of an overloaded function.
//'Sgot three different actions it can do,
//and some of these vary depending on the file loaded.
//
private int loadTransform(int action, double[][] src, double[][] tgt){
	try{
	final FileReader fr=new FileReader(loadPathAndFilename);
	BufferedReader br = new BufferedReader(fr);
	String record;
	int separatorIndex;
	String[] fields=new String[3];
	//src=new double[2][3];
	//tgt=new double[2][3];
	
		switch (action){
			case 0:{ //return the index of the former target image, or detect if the 
				//selected file contains only one transformation matrix and start from the 1st
				record = br.readLine();	
				record = record.trim();
				if (record.equals("Transformation")) 
				{
					loadSingleMatrix = true;
					fr.close();
					return 1;
				}else{
					loadSingleMatrix = false;
				}
				record = br.readLine();
				record = br.readLine();
				record = br.readLine();				
				record = br.readLine();
				record = record.trim();
				separatorIndex = record.indexOf("Target img: ");			
				fields[0] = record.substring(separatorIndex+11).trim();
				fr.close();
				return (new Integer(fields[0])).intValue();
			}
			case 1:{ //return the transform used and set twoStack boolean if needed
				int transformation=3;
				if (loadSingleMatrix){
					record = br.readLine();
					record = br.readLine();
					record = record.trim();
					if (record.equals("TRANSLATION")) {
						transformation = 0;
					}
					else if (record.equals("RIGID_BODY")) {
						transformation = 1;
					}
					else if (record.equals("SCALED_ROTATION")) {
						transformation = 2;
					}
					else if (record.equals("AFFINE")) {
						transformation = 3;
					}
					twoStackAlign=false;
					fr.close();
				}else{
					record = br.readLine();
					if(record.length()!=33){
				     IJ.log("Warning: Not a valid Transform File.\n**Expect Tranform File for  # Slices: "+n_Slices+"  Width: "+width_Slices+"  Height: "+height_Slices);
             return -1;
				  }
					record = br.readLine();
					if(record.length()<22){
				     IJ.log("Warning: Not a valid Transform File.\n**Expect Tranform File for  # Slices: "+n_Slices+"  Width: "+width_Slices+"  Height: "+height_Slices);
             return -1;
				  }
					
					//CHECK reads in # slices width and height dimensions of Transforms to check for match
					String xRec = record.substring(0,1);
					if(xRec.equals("1") || xRec.equals("2") || xRec.equals("3") || xRec.equals("4") || xRec.equals("5") || xRec.equals("6") || xRec.equals("7") || xRec.equals("8") || xRec.equals("9")){
						 int xn_Slices=-1;
						 int xwidth_Slices=-1;
						 int xheight_Slices=-1;
					   int separatorIndex0 = record.indexOf(" ");			
					   try{ xn_Slices=(new Integer(record.substring(0, separatorIndex0).trim())).intValue();
					   	}catch(NumberFormatException e){} 
					   int separatorIndex2=record.substring(0,separatorIndex0).length()+1;
					   int separatorIndex3=record.substring(separatorIndex2,record.length()).indexOf(" ") + separatorIndex2;
					   try{ xwidth_Slices=(new Integer(record.substring(separatorIndex2,separatorIndex3).trim())).intValue();
					   	}catch(NumberFormatException e){} 
					   int separatorIndex4=record.substring(separatorIndex3+1,record.length()).indexOf(" ") + 1 + separatorIndex3;					
					   try{ xheight_Slices=(new Integer(record.substring(separatorIndex3+1,separatorIndex4).trim())).intValue();
					   	}catch(NumberFormatException e){}
					   //CHECKS that numbers were read in as expected => if not then NOT valid tranform file
             if(xn_Slices==-1 || xwidth_Slices==-1 || xheight_Slices==-1){
				          //IJ.showMessage("Warning: Cannot Align Images!","Error Not a valid Transform File.\n**Expect Tranform File for  # Slices: "+n_Slices+"  Width: "+width_Slices+"  Height: "+height_Slices);
						  IJ.log("Warning: Not a valid Transform File.\n**Expect Tranform File for  # Slices: "+n_Slices+"  Width: "+width_Slices+"  Height: "+height_Slices);
                  return -1;
             }					   
             //CHECKS that current & tranform slices match on # and dimensions
					   else{
					   	   if(xn_Slices!=n_Slices || xwidth_Slices!=width_Slices || xheight_Slices!=height_Slices){
				            // IJ.showMessage("Warning: Cannot Align Images!","Error Current Stack not same as Transformed Stack:\n  Current Stack:            Transformed Stack:\n# Slices: "+n_Slices+"                     # Slices: "+xn_Slices+"\n Width: "+width_Slices+"                       Width: "+xwidth_Slices+"\n Height: "+height_Slices+"                      Height: "+xheight_Slices);
							IJ.log("Warning: Current Stack not same as Transformed Stack:\n  Current Stack:            Transformed Stack:\n# Slices: "+n_Slices+"                     # Slices: "+xn_Slices+"\n Width: "+width_Slices+"                       Width: "+xwidth_Slices+"\n Height: "+height_Slices+"                      Height: "+xheight_Slices);
                    return -1;						
					       }
					   }
					}
					//CHECKS throws error because not a valid tranform file
					else{
				     // IJ.showMessage("Warning: Cannot Align Images!","Error Not a valid Transform File.\n**Expect Tranform File for  # Slices: "+n_Slices+"  Width: "+width_Slices+"  Height: "+height_Slices);
					 IJ.log("Warning: Not a valid Transform File.\n**Expect Tranform File for  # Slices: "+n_Slices+"  Width: "+width_Slices+"  Height: "+height_Slices);
             return -1;						
				  }
					record = br.readLine();
					int discardGlobal=(new Integer(record.trim())).intValue();
					if (discardGlobal==1) 
						twoStackAlign=true;
					else 
						twoStackAlign=false;
					record = br.readLine();				
					record = record.trim();
					if (record.equals("TRANSLATION")) {
						transformation = 0;
					}
					else if (record.equals("RIGID_BODY")) {
						transformation = 1;
					}
					else if (record.equals("SCALED_ROTATION")) {
						transformation = 2;
					}
					else if (record.equals("AFFINE")) {
						transformation = 3;
					}
					fr.close();
				}
				return transformation;
			}
			case 2:{ //return the next transformation in src and tgt, the next src index as return value
				int rtnvalue = -1;
				if (loadSingleMatrix){
					for (int j=0;j<10;j++)
						record = br.readLine();	
					for (int i=0;i<3;i++){
						record = br.readLine();		
						record = record.trim();
						separatorIndex = record.indexOf('\t');			
						fields[0] = record.substring(0, separatorIndex);
						fields[1] = record.substring(separatorIndex);
						fields[0] = fields[0].trim();
						fields[1] = fields[1].trim();
						src[i][0]=(new Double(fields[0])).doubleValue();
						src[i][1]=(new Double(fields[1])).doubleValue();
					}
					record = br.readLine();	
					record = br.readLine();	
					for (int i=0;i<3;i++){
						record = br.readLine();		
						record = record.trim();
						separatorIndex = record.indexOf('\t');
						
						fields[0] = record.substring(0, separatorIndex);
						fields[1] = record.substring(separatorIndex);
						fields[0] = fields[0].trim();
						fields[1] = fields[1].trim();
						tgt[i][0]=(new Double(fields[0])).doubleValue();
						tgt[i][1]=(new Double(fields[1])).doubleValue();
					}
					
				}else{
					record = br.readLine();	
					record = br.readLine();	
					record = br.readLine();	
					for (int i=0;i<transformNumber;i++){
						for (int j=0;j<10;j++)
							record = br.readLine();	
					}
					//read the target and source index
					record = br.readLine();		
					record = br.readLine();		
					record = record.trim();
					separatorIndex = record.indexOf("Target img: ");			
					fields[0] = record.substring(11,separatorIndex).trim();
					rtnvalue = (new Integer(fields[0])).intValue();
					
					for (int i=0;i<3;i++){
						record = br.readLine();		
						record = record.trim();
						separatorIndex = record.indexOf('\t');			
						fields[0] = record.substring(0, separatorIndex);
						fields[1] = record.substring(separatorIndex);
						fields[0] = fields[0].trim();
						fields[1] = fields[1].trim();
						src[i][0]=(new Double(fields[0])).doubleValue();
						src[i][1]=(new Double(fields[1])).doubleValue();
					}
					record = br.readLine();	
					for (int i=0;i<3;i++){
						record = br.readLine();		
						record = record.trim();
						separatorIndex = record.indexOf('\t');
						
						fields[0] = record.substring(0, separatorIndex);
						fields[1] = record.substring(separatorIndex);
						fields[0] = fields[0].trim();
						fields[1] = fields[1].trim();
						tgt[i][0]=(new Double(fields[0])).doubleValue();
						tgt[i][1]=(new Double(fields[1])).doubleValue();
					}
				}
				fr.close();
				return rtnvalue;
			}
			
		}
	}catch(FileNotFoundException e){
		IJ.log("Could not find proper transformation matrix.");
	}catch (IOException e) {
		IJ.log("Error reading from file.");
	}
	return 0;
}

/*------------------------------------------------------------------*/
private void appendTransform(String path, int sourceID, int targetID,double[][] src,double[][] tgt,int transform){
	String Transform="RIGID_BODY";
	switch(transform){
		case 0:{
			Transform="TRANSLATION";
			break;
		}
		case 1:{
			Transform="RIGID_BODY";
			break;
		}
		case 2:{
			Transform="SCALED_ROTATION";
			break;
		}
		case 3:{
			Transform="AFFINE";
			break;
		}
	}
	try {
		final FileWriter fw = new FileWriter(path,true);
		fw.append(Transform+"\n");
		fw.append("Source img: "+sourceID+" Target img: "+targetID+"\n"); 
		fw.append(src[0][0] +"\t"+src[0][1]+"\n");
		fw.append(src[1][0] +"\t"+src[1][1]+"\n");
		fw.append(src[2][0] +"\t"+src[2][1]+"\n");
		fw.append("\n");
		fw.append(tgt[0][0] +"\t"+tgt[0][1]+"\n");
		fw.append(tgt[1][0] +"\t"+tgt[1][1]+"\n");
		fw.append(tgt[2][0] +"\t"+tgt[2][1]+"\n");
		fw.append("\n");
		fw.close();
	}catch (IOException e) {
		IJ.log("Error writing to file.");
	}
}/*appendTransform*/

/*------------------------------------------------------------------*/
private void computeStatistics (
	final ImagePlus imp,
	final double[] average,
	final double[][] scatterMatrix
) {
	int length = imp.getWidth() * imp.getHeight();
	double r;
	double g;
	double b;
	if (imp.getProcessor().getPixels() instanceof byte[]) {
		final IndexColorModel icm = (IndexColorModel)imp.getProcessor().getColorModel();
		final int mapSize = icm.getMapSize();
		final byte[] reds = new byte[mapSize];
		final byte[] greens = new byte[mapSize];
		final byte[] blues = new byte[mapSize];	
		icm.getReds(reds); 
		icm.getGreens(greens); 
		icm.getBlues(blues);
		final double[] histogram = new double[mapSize];
		for (int k = 0; (k < mapSize); k++) {
			histogram[k] = 0.0;
		}
		for (int s = 1; (s <= imp.getStackSize()); s++) {
			imp.setSlice(s);
			final byte[] pixels = (byte[])imp.getProcessor().getPixels();
			for (int k = 0; (k < length); k++) {
				histogram[pixels[k] & 0xFF]++;
			}
		}
		for (int k = 0; (k < mapSize); k++) {
			r = (double)(reds[k] & 0xFF);
			g = (double)(greens[k] & 0xFF);
			b = (double)(blues[k] & 0xFF);
			average[0] += histogram[k] * r;
			average[1] += histogram[k] * g;
			average[2] += histogram[k] * b;
			scatterMatrix[0][0] += histogram[k] * r * r;
			scatterMatrix[0][1] += histogram[k] * r * g;
			scatterMatrix[0][2] += histogram[k] * r * b;
			scatterMatrix[1][1] += histogram[k] * g * g;
			scatterMatrix[1][2] += histogram[k] * g * b;
			scatterMatrix[2][2] += histogram[k] * b * b;
		}
	}
	else if (imp.getProcessor().getPixels() instanceof int[]) {
		for (int s = 1; (s <= imp.getStackSize()); s++) {
			imp.setSlice(s);
			final int[] pixels = (int[])imp.getProcessor().getPixels();
			for (int k = 0; (k < length); k++) {
				r = (double)((pixels[k] & 0x00FF0000) >>> 16);
				g = (double)((pixels[k] & 0x0000FF00) >>> 8);
				b = (double)(pixels[k] & 0x000000FF);
				average[0] += r;
				average[1] += g;
				average[2] += b;
				scatterMatrix[0][0] += r * r;
				scatterMatrix[0][1] += r * g;
				scatterMatrix[0][2] += r * b;
				scatterMatrix[1][1] += g * g;
				scatterMatrix[1][2] += g * b;
				scatterMatrix[2][2] += b * b;
			}
		}
	}
	else {
		IJ.log("Internal type mismatch");
	}
	length *= imp.getStackSize();
	average[0] /= (double)length;
	average[1] /= (double)length;
	average[2] /= (double)length;
	scatterMatrix[0][0] /= (double)length;
	scatterMatrix[0][1] /= (double)length;
	scatterMatrix[0][2] /= (double)length;
	scatterMatrix[1][1] /= (double)length;
	scatterMatrix[1][2] /= (double)length;
	scatterMatrix[2][2] /= (double)length;
	scatterMatrix[0][0] -= average[0] * average[0];
	scatterMatrix[0][1] -= average[0] * average[1];
	scatterMatrix[0][2] -= average[0] * average[2];
	scatterMatrix[1][1] -= average[1] * average[1];
	scatterMatrix[1][2] -= average[1] * average[2];
	scatterMatrix[2][2] -= average[2] * average[2];
	scatterMatrix[2][1] = scatterMatrix[1][2];
	scatterMatrix[2][0] = scatterMatrix[0][2];
	scatterMatrix[1][0] = scatterMatrix[0][1];
} /* computeStatistics */

/*------------------------------------------------------------------*/
private double[] getColorWeightsFromPrincipalComponents (
	final ImagePlus imp
) {
	final double[] average = {0.0, 0.0, 0.0};
	final double[][] scatterMatrix = {{0.0, 0.0, 0.0}, {0.0, 0.0, 0.0}, {0.0, 0.0, 0.0}};
	computeStatistics(imp, average, scatterMatrix);
	double[] eigenvalue = getEigenvalues(scatterMatrix);
	if ((eigenvalue[0] * eigenvalue[0] + eigenvalue[1] * eigenvalue[1]
		+ eigenvalue[2] * eigenvalue[2]) <= TINY) {
		return(getLuminanceFromCCIR601());
	}
	double bestEigenvalue = getLargestAbsoluteEigenvalue(eigenvalue);
	double eigenvector[] = getEigenvector(scatterMatrix, bestEigenvalue);
	final double weight = eigenvector[0] + eigenvector[1] + eigenvector[2];
	if (TINY < Math.abs(weight)) {
		eigenvector[0] /= weight;
		eigenvector[1] /= weight;
		eigenvector[2] /= weight;
	}
	return(eigenvector);
} /* getColorWeightsFromPrincipalComponents */

/*------------------------------------------------------------------*/
private double[] getEigenvalues (
	final double[][] scatterMatrix
) {
	final double[] a = {
		scatterMatrix[0][0] * scatterMatrix[1][1] * scatterMatrix[2][2]
			+ 2.0 * scatterMatrix[0][1] * scatterMatrix[1][2] * scatterMatrix[2][0]
			- scatterMatrix[0][1] * scatterMatrix[0][1] * scatterMatrix[2][2]
			- scatterMatrix[1][2] * scatterMatrix[1][2] * scatterMatrix[0][0]
			- scatterMatrix[2][0] * scatterMatrix[2][0] * scatterMatrix[1][1],
		scatterMatrix[0][1] * scatterMatrix[0][1]
			+ scatterMatrix[1][2] * scatterMatrix[1][2]
			+ scatterMatrix[2][0] * scatterMatrix[2][0]
			- scatterMatrix[0][0] * scatterMatrix[1][1]
			- scatterMatrix[1][1] * scatterMatrix[2][2]
			- scatterMatrix[2][2] * scatterMatrix[0][0],
		scatterMatrix[0][0] + scatterMatrix[1][1] + scatterMatrix[2][2],
		-1.0
	};
	double[] RealRoot = new double[3];
	double Q = (3.0 * a[1] - a[2] * a[2] / a[3]) / (9.0 * a[3]);
	double R = (a[1] * a[2] - 3.0 * a[0] * a[3] - (2.0 / 9.0) * a[2] * a[2] * a[2] / a[3])
		/ (6.0 * a[3] * a[3]);
	double Det = Q * Q * Q + R * R;
	if (Det < 0.0) {
		Det = 2.0 * Math.sqrt(-Q);
		R /= Math.sqrt(-Q * Q * Q);
		R = (1.0 / 3.0) * Math.acos(R);
		Q = (1.0 / 3.0) * a[2] / a[3];
		RealRoot[0] = Det * Math.cos(R) - Q;
		RealRoot[1] = Det * Math.cos(R + (2.0 / 3.0) * Math.PI) - Q;
		RealRoot[2] = Det * Math.cos(R + (4.0 / 3.0) * Math.PI) - Q;
		if (RealRoot[0] < RealRoot[1]) {
			if (RealRoot[2] < RealRoot[1]) {
				double Swap = RealRoot[1];
				RealRoot[1] = RealRoot[2];
				RealRoot[2] = Swap;
				if (RealRoot[1] < RealRoot[0]) {
					Swap = RealRoot[0];
					RealRoot[0] = RealRoot[1];
					RealRoot[1] = Swap;
				}
			}
		}
		else {
			double Swap = RealRoot[0];
			RealRoot[0] = RealRoot[1];
			RealRoot[1] = Swap;
			if (RealRoot[2] < RealRoot[1]) {
				Swap = RealRoot[1];
				RealRoot[1] = RealRoot[2];
				RealRoot[2] = Swap;
				if (RealRoot[1] < RealRoot[0]) {
					Swap = RealRoot[0];
					RealRoot[0] = RealRoot[1];
					RealRoot[1] = Swap;
				}
			}
		}
	}
	else if (Det == 0.0) {
		final double P = 2.0 * ((R < 0.0) ? (Math.pow(-R, 1.0 / 3.0)) : (Math.pow(R, 1.0 / 3.0)));
		Q = (1.0 / 3.0) * a[2] / a[3];
		if (P < 0) {
			RealRoot[0] = P - Q;
			RealRoot[1] = -0.5 * P - Q;
			RealRoot[2] = RealRoot[1];
		}
		else {
			RealRoot[0] = -0.5 * P - Q;
			RealRoot[1] = RealRoot[0];
			RealRoot[2] = P - Q;
		}
	}
	else {
		IJ.showMessage("Warning: complex eigenvalue found; ignoring imaginary part.");
		Det = Math.sqrt(Det);
		Q = ((R + Det) < 0.0) ? (-Math.exp((1.0 / 3.0) * Math.log(-R - Det)))
			: (Math.exp((1.0 / 3.0) * Math.log(R + Det)));
		R = Q + ((R < Det) ? (-Math.exp((1.0 / 3.0) * Math.log(Det - R)))
			: (Math.exp((1.0 / 3.0) * Math.log(R - Det))));
		Q = (-1.0 / 3.0) * a[2] / a[3];
		Det = Q + R;
		RealRoot[0] = Q - R / 2.0;
		RealRoot[1] = RealRoot[0];
		RealRoot[2] = RealRoot[1];
		if (Det < RealRoot[0]) {
			RealRoot[0] = Det;
		}
		else {
			RealRoot[2] = Det;
		}
	}
	return(RealRoot);
} /* end getEigenvalues */

/*------------------------------------------------------------------*/
private double[] getEigenvector (
	final double[][] scatterMatrix,
	final double eigenvalue
) {
	final int n = scatterMatrix.length;
	final double[][] matrix = new double[n][n];
	for (int i = 0; (i < n); i++) {
		System.arraycopy(scatterMatrix[i], 0, matrix[i], 0, n);
		matrix[i][i] -= eigenvalue;
	}
	final double[] eigenvector = new double[n];
	double absMax;
	double max;
	double norm;
	for (int i = 0; (i < n); i++) {
		norm = 0.0;
		for (int j = 0; (j < n); j++) {
			norm += matrix[i][j] * matrix[i][j];
		}
		norm = Math.sqrt(norm);
		if (TINY < norm) {
			for (int j = 0; (j < n); j++) {
				matrix[i][j] /= norm;
			}
		}
	}
	for (int j = 0; (j < n); j++) {
		max = matrix[j][j];
		absMax = Math.abs(max);
		int k = j;
		for (int i = j + 1; (i < n); i++) {
			if (absMax < Math.abs(matrix[i][j])) {
				max = matrix[i][j];
				absMax = Math.abs(max);
				k = i;
			}
		}
		if (k != j) {
			final double[] partialLine = new double[n - j];
			System.arraycopy(matrix[j], j, partialLine, 0, n - j);
			System.arraycopy(matrix[k], j, matrix[j], j, n - j);
			System.arraycopy(partialLine, 0, matrix[k], j, n - j);
		}
		if (TINY < absMax) {
			for (k = 0; (k < n); k++) {
				matrix[j][k] /= max;
			}
		}
		for (int i = j + 1; (i < n); i++) {
			max = matrix[i][j];
			for (k = 0; (k < n); k++) {
				matrix[i][k] -= max * matrix[j][k];
			}
		}
	}
	final boolean[] ignore = new boolean[n];
	int valid = n;
	for (int i = 0; (i < n); i++) {
		ignore[i] = false;
		if (Math.abs(matrix[i][i]) < TINY) {
			ignore[i] = true;
			valid--;
			eigenvector[i] = 1.0;
			continue;
		}
		if (TINY < Math.abs(matrix[i][i] - 1.0)) {
			IJ.log("Insufficient accuracy.");
			eigenvector[0] = 0.212671;
			eigenvector[1] = 0.71516;
			eigenvector[2] = 0.072169;
			return(eigenvector);
		}
		norm = 0.0;
		for (int j = 0; (j < i); j++) {
			norm += matrix[i][j] * matrix[i][j];
		}
		for (int j = i + 1; (j < n); j++) {
			norm += matrix[i][j] * matrix[i][j];
		}
		if (Math.sqrt(norm) < TINY) {
			ignore[i] = true;
			valid--;
			eigenvector[i] = 0.0;
			continue;
		}
	}
	if (0 < valid) {
		double[][] reducedMatrix = new double[valid][valid];
		for (int i = 0, u = 0; (i < n); i++) {
			if (!ignore[i]) {
				for (int j = 0, v = 0; (j < n); j++) {
					if (!ignore[j]) {
						reducedMatrix[u][v] = matrix[i][j];
						v++;
					}
				}
				u++;
			}
		}
		double[] reducedEigenvector = new double[valid];
		for (int i = 0, u = 0; (i < n); i++) {
			if (!ignore[i]) {
				for (int j = 0; (j < n); j++) {
					if (ignore[j]) {
						reducedEigenvector[u] -= matrix[i][j] * eigenvector[j];
					}
				}
				u++;
			}
		}
		reducedEigenvector = linearLeastSquares(reducedMatrix, reducedEigenvector);
		for (int i = 0, u = 0; (i < n); i++) {
			if (!ignore[i]) {
				eigenvector[i] = reducedEigenvector[u];
				u++;
			}
		}
	}
	norm = 0.0;
	for (int i = 0; (i < n); i++) {
		norm += eigenvector[i] * eigenvector[i];
	}
	norm = Math.sqrt(norm);
	if (Math.sqrt(norm) < TINY) {
		IJ.log("Insufficient accuracy.");
		eigenvector[0] = 0.212671;
		eigenvector[1] = 0.71516;
		eigenvector[2] = 0.072169;
		return(eigenvector);
	}
	absMax = Math.abs(eigenvector[0]);
	valid = 0;
	for (int i = 1; (i < n); i++) {
		max = Math.abs(eigenvector[i]);
		if (absMax < max) {
			absMax = max;
			valid = i;
		}
	}
	norm = (eigenvector[valid] < 0.0) ? (-norm) : (norm);
	for (int i = 0; (i < n); i++) {
		eigenvector[i] /= norm;
	}
	return(eigenvector);
} /* getEigenvector */

/*------------------------------------------------------------------*/
private ImagePlus getGray32 (
	final String title,
	final ImagePlus imp,
	final double[] colorWeights
) {
	final int length = imp.getWidth() * imp.getHeight();
	final ImagePlus gray32 = new ImagePlus(title,
		new FloatProcessor(imp.getWidth(), imp.getHeight()));
	final float[] gray = (float[])gray32.getProcessor().getPixels();
	double r;
	double g;
	double b;
	if (imp.getProcessor().getPixels() instanceof byte[]) {
		final byte[] pixels = (byte[])imp.getProcessor().getPixels();
		final IndexColorModel icm = (IndexColorModel)imp.getProcessor().getColorModel();
		final int mapSize = icm.getMapSize();
		final byte[] reds = new byte[mapSize];
		final byte[] greens = new byte[mapSize];
		final byte[] blues = new byte[mapSize];	
		icm.getReds(reds); 
		icm.getGreens(greens); 
		icm.getBlues(blues);
		int index;
		for (int k = 0; (k < length); k++) {
			index = (int)(pixels[k] & 0xFF);
			r = (double)(reds[index] & 0xFF);
			g = (double)(greens[index] & 0xFF);
			b = (double)(blues[index] & 0xFF);
			gray[k] = (float)(colorWeights[0] * r + colorWeights[1] * g + colorWeights[2] * b);
		}
	}
	else if (imp.getProcessor().getPixels() instanceof int[]) {
		final int[] pixels = (int[])imp.getProcessor().getPixels();
		for (int k = 0; (k < length); k++) {
			r = (double)((pixels[k] & 0x00FF0000) >>> 16);
			g = (double)((pixels[k] & 0x0000FF00) >>> 8);
			b = (double)(pixels[k] & 0x000000FF);
			gray[k] = (float)(colorWeights[0] * r + colorWeights[1] * g + colorWeights[2] * b);
		}
	}
	return(gray32);
} /* getGray32 */

/*------------------------------------------------------------------*/
private double getLargestAbsoluteEigenvalue (
	final double[] eigenvalue
) {
	double best = eigenvalue[0];
	for (int k = 1; (k < eigenvalue.length); k++) {
		if (Math.abs(best) < Math.abs(eigenvalue[k])) {
			best = eigenvalue[k];
		}
		if (Math.abs(best) == Math.abs(eigenvalue[k])) {
			if (best < eigenvalue[k]) {
				best = eigenvalue[k];
			}
		}
	}
	return(best);
} /* getLargestAbsoluteEigenvalue */

/*------------------------------------------------------------------*/
private double[] getLuminanceFromCCIR601 (
) {
	double[] weights = {0.299, 0.587, 0.114};
	return(weights);
} /* getLuminanceFromCCIR601 */

/*------------------------------------------------------------------*/
private double[][] getTransformationMatrix (
	final double[][] fromCoord,
	final double[][] toCoord,
	final int transformation
) {
	double[][] matrix = new double[3][3];
	switch (transformation) {
		case 0: {
			matrix[0][0] = 1.0;
			matrix[0][1] = 0.0;
			matrix[0][2] = toCoord[0][0] - fromCoord[0][0];
			matrix[1][0] = 0.0;
			matrix[1][1] = 1.0;
			matrix[1][2] = toCoord[0][1] - fromCoord[0][1];
			break;
		}
		case 1: {
			final double angle = Math.atan2(fromCoord[2][0] - fromCoord[1][0],
				fromCoord[2][1] - fromCoord[1][1]) - Math.atan2(toCoord[2][0] - toCoord[1][0],
				toCoord[2][1] - toCoord[1][1]);
			final double c = Math.cos(angle);
			final double s = Math.sin(angle);
			matrix[0][0] = c;
			matrix[0][1] = -s;
			matrix[0][2] = toCoord[0][0] - c * fromCoord[0][0] + s * fromCoord[0][1];
			matrix[1][0] = s;
			matrix[1][1] = c;
			matrix[1][2] = toCoord[0][1] - s * fromCoord[0][0] - c * fromCoord[0][1];
			break;
		}
		case 2: {
			double[][] a = new double[3][3];
			double[] v = new double[3];
			a[0][0] = fromCoord[0][0];
			a[0][1] = fromCoord[0][1];
			a[0][2] = 1.0;
			a[1][0] = fromCoord[1][0];
			a[1][1] = fromCoord[1][1];
			a[1][2] = 1.0;
			a[2][0] = fromCoord[0][1] - fromCoord[1][1] + fromCoord[1][0];
			a[2][1] = fromCoord[1][0] + fromCoord[1][1] - fromCoord[0][0];
			a[2][2] = 1.0;
			invertGauss(a);
			v[0] = toCoord[0][0];
			v[1] = toCoord[1][0];
			v[2] = toCoord[0][1] - toCoord[1][1] + toCoord[1][0];
			for (int i = 0; (i < 3); i++) {
				matrix[0][i] = 0.0;
				for (int j = 0; (j < 3); j++) {
					matrix[0][i] += a[i][j] * v[j];
				}
			}
			v[0] = toCoord[0][1];
			v[1] = toCoord[1][1];
			v[2] = toCoord[1][0] + toCoord[1][1] - toCoord[0][0];
			for (int i = 0; (i < 3); i++) {
				matrix[1][i] = 0.0;
				for (int j = 0; (j < 3); j++) {
					matrix[1][i] += a[i][j] * v[j];
				}
			}
			break;
		}
		case 3: {
			double[][] a = new double[3][3];
			double[] v = new double[3];
			a[0][0] = fromCoord[0][0];
			a[0][1] = fromCoord[0][1];
			a[0][2] = 1.0;
			a[1][0] = fromCoord[1][0];
			a[1][1] = fromCoord[1][1];
			a[1][2] = 1.0;
			a[2][0] = fromCoord[2][0];
			a[2][1] = fromCoord[2][1];
			a[2][2] = 1.0;
			invertGauss(a);
			v[0] = toCoord[0][0];
			v[1] = toCoord[1][0];
			v[2] = toCoord[2][0];
			for (int i = 0; (i < 3); i++) {
				matrix[0][i] = 0.0;
				for (int j = 0; (j < 3); j++) {
					matrix[0][i] += a[i][j] * v[j];
				}
			}
			v[0] = toCoord[0][1];
			v[1] = toCoord[1][1];
			v[2] = toCoord[2][1];
			for (int i = 0; (i < 3); i++) {
				matrix[1][i] = 0.0;
				for (int j = 0; (j < 3); j++) {
					matrix[1][i] += a[i][j] * v[j];
				}
			}
			break;
		}
		default: {
			IJ.log("Unexpected transformation");
		}
	}
	matrix[2][0] = 0.0;
	matrix[2][1] = 0.0;
	matrix[2][2] = 1.0;
	return(matrix);
} /* end getTransformationMatrix */

/*------------------------------------------------------------------*/
private void invertGauss (
	final double[][] matrix
) {
	final int n = matrix.length;
	final double[][] inverse = new double[n][n];
	for (int i = 0; (i < n); i++) {
		double max = matrix[i][0];
		double absMax = Math.abs(max);
		for (int j = 0; (j < n); j++) {
			inverse[i][j] = 0.0;
			if (absMax < Math.abs(matrix[i][j])) {
				max = matrix[i][j];
				absMax = Math.abs(max);
			}
		}
		inverse[i][i] = 1.0 / max;
		for (int j = 0; (j < n); j++) {
			matrix[i][j] /= max;
		}
	}
	for (int j = 0; (j < n); j++) {
		double max = matrix[j][j];
		double absMax = Math.abs(max);
		int k = j;
		for (int i = j + 1; (i < n); i++) {
			if (absMax < Math.abs(matrix[i][j])) {
				max = matrix[i][j];
				absMax = Math.abs(max);
				k = i;
			}
		}
		if (k != j) {
			final double[] partialLine = new double[n - j];
			final double[] fullLine = new double[n];
			System.arraycopy(matrix[j], j, partialLine, 0, n - j);
			System.arraycopy(matrix[k], j, matrix[j], j, n - j);
			System.arraycopy(partialLine, 0, matrix[k], j, n - j);
			System.arraycopy(inverse[j], 0, fullLine, 0, n);
			System.arraycopy(inverse[k], 0, inverse[j], 0, n);
			System.arraycopy(fullLine, 0, inverse[k], 0, n);
		}
		for (k = 0; (k <= j); k++) {
			inverse[j][k] /= max;
		}
		for (k = j + 1; (k < n); k++) {
			matrix[j][k] /= max;
			inverse[j][k] /= max;
		}
		for (int i = j + 1; (i < n); i++) {
			for (k = 0; (k <= j); k++) {
				inverse[i][k] -= matrix[i][j] * inverse[j][k];
			}
			for (k = j + 1; (k < n); k++) {
				matrix[i][k] -= matrix[i][j] * matrix[j][k];
				inverse[i][k] -= matrix[i][j] * inverse[j][k];
			}
		}
	}
	for (int j = n - 1; (1 <= j); j--) {
		for (int i = j - 1; (0 <= i); i--) {
			for (int k = 0; (k <= j); k++) {
				inverse[i][k] -= matrix[i][j] * inverse[j][k];
			}
			for (int k = j + 1; (k < n); k++) {
				matrix[i][k] -= matrix[i][j] * matrix[j][k];
				inverse[i][k] -= matrix[i][j] * inverse[j][k];
			}
		}
	}
	for (int i = 0; (i < n); i++) {
		System.arraycopy(inverse[i], 0, matrix[i], 0, n);
	}
} /* end invertGauss */

/*------------------------------------------------------------------*/
private double[] linearLeastSquares (
	final double[][] A,
	final double[] b
) {
	final int lines = A.length;
	final int columns = A[0].length;
	final double[][] Q = new double[lines][columns];
	final double[][] R = new double[columns][columns];
	final double[] x = new double[columns];
	double s;
	for (int i = 0; (i < lines); i++) {
		for (int j = 0; (j < columns); j++) {
			Q[i][j] = A[i][j];
		}
	}
	QRdecomposition(Q, R);
	for (int i = 0; (i < columns); i++) {
		s = 0.0;
		for (int j = 0; (j < lines); j++) {
			s += Q[j][i] * b[j];
		}
		x[i] = s;
	}
	for (int i = columns - 1; (0 <= i); i--) {
		s = R[i][i];
		if ((s * s) == 0.0) {
			x[i] = 0.0;
		}
		else {
			x[i] /= s;
		}
		for (int j = i - 1; (0 <= j); j--) {
			x[j] -= R[j][i] * x[i];
		}
	}
	return(x);
} /* end linearLeastSquares */

/*------------------------------------------------------------------*/
private void QRdecomposition (
	final double[][] Q,
	final double[][] R
) {
	final int lines = Q.length;
	final int columns = Q[0].length;
	final double[][] A = new double[lines][columns];
	double s;
	for (int j = 0; (j < columns); j++) {
		for (int i = 0; (i < lines); i++) {
			A[i][j] = Q[i][j];
		}
		for (int k = 0; (k < j); k++) {
			s = 0.0;
			for (int i = 0; (i < lines); i++) {
				s += A[i][j] * Q[i][k];
			}
			for (int i = 0; (i < lines); i++) {
				Q[i][j] -= s * Q[i][k];
			}
		}
		s = 0.0;
		for (int i = 0; (i < lines); i++) {
			s += Q[i][j] * Q[i][j];
		}
		if ((s * s) == 0.0) {
			s = 0.0;
		}
		else {
			s = 1.0 / Math.sqrt(s);
		}
		for (int i = 0; (i < lines); i++) {
			Q[i][j] *= s;
		}
	}
	for (int i = 0; (i < columns); i++) {
		for (int j = 0; (j < i); j++) {
			R[i][j] = 0.0;
		}
		for (int j = i; (j < columns); j++) {
			R[i][j] = 0.0;
			for (int k = 0; (k < lines); k++) {
				R[i][j] += Q[k][i] * A[k][j];
			}
		}
	}
} /* end QRdecomposition */

/*------------------------------------------------------------------*/
private ImagePlus registerSlice (
	ImagePlus source,
	final ImagePlus target,
	final ImagePlus imp,
	final int width,
	final int height,
	final int transformation,
	final double[][] globalTransform,
	final double[][] anchorPoints,
	final double[] colorWeights,
	final int s
) {
	imp.setSlice(s);
	try {
		Object turboReg = null;
		Method method = null;
		double[][] sourcePoints = null;
		double[][] targetPoints = null;
		double[][] localTransform = null;
		switch (imp.getType()) {
			case ImagePlus.COLOR_256:
			case ImagePlus.COLOR_RGB: {
				source = getGray32("StackRegSource", imp, colorWeights);
				break;
			}
			case ImagePlus.GRAY8: {
				source = new ImagePlus("StackRegSource", new ByteProcessor(
					width, height, (byte[])imp.getProcessor().getPixels(),
					imp.getProcessor().getColorModel()));
				break;
			}
			case ImagePlus.GRAY16: {
				source = new ImagePlus("StackRegSource", new ShortProcessor(
					width, height, (short[])imp.getProcessor().getPixels(),
					imp.getProcessor().getColorModel()));
				break;
			}
			case ImagePlus.GRAY32: {
				source = new ImagePlus("StackRegSource", new FloatProcessor(
					width, height, (float[])imp.getProcessor().getPixels(),
					imp.getProcessor().getColorModel()));
				break;
			}
			default: {
				IJ.log("Unexpected image type");
				return(null);
			}
		}
		final FileSaver sourceFile = new FileSaver(source);
		final String sourcePathAndFileName = IJ.getDirectory("temp") + source.getTitle();
		sourceFile.saveAsTiff(sourcePathAndFileName);
		final FileSaver targetFile = new FileSaver(target);
		final String targetPathAndFileName = IJ.getDirectory("temp") + target.getTitle();
		targetFile.saveAsTiff(targetPathAndFileName);
		if (loadPathAndFilename==""){//if we've specified a transformation to load, we needen't bother with aligning them again
			switch (transformation) {
				case 0: {
					turboReg = IJ.runPlugIn("TurboReg_", "-align"
						+ " -file " + sourcePathAndFileName
						+ " 0 0 " + (width - 1) + " " + (height - 1)
						+ " -file " + targetPathAndFileName
						+ " 0 0 " + (width - 1) + " " + (height - 1)
						+ " -translation"
						+ " " + (width / 2) + " " + (height / 2)
						+ " " + (width / 2) + " " + (height / 2)
						+ " -hideOutput"
					);
					break;
				}
				case 1: {
					turboReg = IJ.runPlugIn("TurboReg_", "-align"
						+ " -file " + sourcePathAndFileName
						+ " 0 0 " + (width - 1) + " " + (height - 1)
						+ " -file " + targetPathAndFileName
						+ " 0 0 " + (width - 1) + " " + (height - 1)
						+ " -rigidBody"
						+ " " + (width / 2) + " " + (height / 2)
						+ " " + (width / 2) + " " + (height / 2)
						+ " " + (width / 2) + " " + (height / 4)
						+ " " + (width / 2) + " " + (height / 4)
						+ " " + (width / 2) + " " + ((3 * height) / 4)
						+ " " + (width / 2) + " " + ((3 * height) / 4)
						+ " -hideOutput"
					);
					break;
				}
				case 2: {
					turboReg = IJ.runPlugIn("TurboReg_", "-align"
						+ " -file " + sourcePathAndFileName
						+ " 0 0 " + (width - 1) + " " + (height - 1)
						+ " -file " + targetPathAndFileName
						+ " 0 0 " + (width - 1) + " " + (height - 1)
						+ " -scaledRotation"
						+ " " + (width / 4) + " " + (height / 2)
						+ " " + (width / 4) + " " + (height / 2)
						+ " " + ((3 * width) / 4) + " " + (height / 2)
						+ " " + ((3 * width) / 4) + " " + (height / 2)
						+ " -hideOutput"
					);
					break;
				}
				case 3: {
					turboReg = IJ.runPlugIn("TurboReg_", "-align"
						+ " -file " + sourcePathAndFileName
						+ " 0 0 " + (width - 1) + " " + (height - 1)
						+ " -file " + targetPathAndFileName
						+ " 0 0 " + (width - 1) + " " + (height - 1)
						+ " -affine"
						+ " " + (width / 2) + " " + (height / 4)
						+ " " + (width / 2) + " " + (height / 4)
						+ " " + (width / 4) + " " + ((3 * height) / 4)
						+ " " + (width / 4) + " " + ((3 * height) / 4)
						+ " " + ((3 * width) / 4) + " " + ((3 * height) / 4)
						+ " " + ((3 * width) / 4) + " " + ((3 * height) / 4)
						+ " -hideOutput"
					);
					break;
				}
				default: {
					IJ.log("Unexpected transformation");
					return(null);
				}
			}
			if (turboReg == null) {
				throw(new ClassNotFoundException());
			}
			target.setProcessor(null, source.getProcessor());
			method = turboReg.getClass().getMethod("getSourcePoints", null);
			sourcePoints = ((double[][])method.invoke(turboReg, null));
			method = turboReg.getClass().getMethod("getTargetPoints", null);
			targetPoints = ((double[][])method.invoke(turboReg, null));
			if (saveTransform) appendTransform(savePath+saveFile, s, tSlice,sourcePoints,targetPoints, transformation);
		}else{
			sourcePoints=new double[3][2];
			targetPoints=new double[3][2];
			int test= loadTransform(2, sourcePoints, targetPoints);
			if (test != -1 && test != s){
				IJ.log("The current transformation file index ("+test+") and image index ("+s+") don't line up, so we're quitting.  Is the stack size the same?");
				return(null);
			}
			transformNumber++;
		}
		localTransform = getTransformationMatrix(targetPoints, sourcePoints,
			transformation);
		double[][] rescued = {
			{globalTransform[0][0], globalTransform[0][1], globalTransform[0][2]},
			{globalTransform[1][0], globalTransform[1][1], globalTransform[1][2]},
			{globalTransform[2][0], globalTransform[2][1], globalTransform[2][2]}
		};
		for (int i = 0; (i < 3); i++) {
			for (int j = 0; (j < 3); j++) {
				globalTransform[i][j] = 0.0;
				for (int k = 0; (k < 3); k++) {
					globalTransform[i][j] += localTransform[i][k] * rescued[k][j];
				}
			}
		}
		switch (imp.getType()) {
			case ImagePlus.COLOR_256: {
				source = new ImagePlus("StackRegSource", new ByteProcessor(
					width, height, (byte[])imp.getProcessor().getPixels(),
					imp.getProcessor().getColorModel()));
				ImageConverter converter = new ImageConverter(source);
				converter.convertToRGB();
				Object turboRegR = null;
				Object turboRegG = null;
				Object turboRegB = null;
				byte[] r = new byte[width * height];
				byte[] g = new byte[width * height];
				byte[] b = new byte[width * height];
				((ColorProcessor)source.getProcessor()).getRGB(r, g, b);
				final ImagePlus sourceR = new ImagePlus("StackRegSourceR",
					new ByteProcessor(width, height));
				final ImagePlus sourceG = new ImagePlus("StackRegSourceG",
					new ByteProcessor(width, height));
				final ImagePlus sourceB = new ImagePlus("StackRegSourceB",
					new ByteProcessor(width, height));
				sourceR.getProcessor().setPixels(r);
				sourceG.getProcessor().setPixels(g);
				sourceB.getProcessor().setPixels(b);
				ImagePlus transformedSourceR = null;
				ImagePlus transformedSourceG = null;
				ImagePlus transformedSourceB = null;
				final FileSaver sourceFileR = new FileSaver(sourceR);
				final String sourcePathAndFileNameR = IJ.getDirectory("temp") + sourceR.getTitle();
				sourceFileR.saveAsTiff(sourcePathAndFileNameR);
				final FileSaver sourceFileG = new FileSaver(sourceG);
				final String sourcePathAndFileNameG = IJ.getDirectory("temp") + sourceG.getTitle();
				sourceFileG.saveAsTiff(sourcePathAndFileNameG);
				final FileSaver sourceFileB = new FileSaver(sourceB);
				final String sourcePathAndFileNameB = IJ.getDirectory("temp") + sourceB.getTitle();
				sourceFileB.saveAsTiff(sourcePathAndFileNameB);
				switch (transformation) {
					case 0: {
						sourcePoints = new double[1][3];
						for (int i = 0; (i < 3); i++) {
							sourcePoints[0][i] = 0.0;
							for (int j = 0; (j < 3); j++) {
								sourcePoints[0][i] += globalTransform[i][j]
									* anchorPoints[0][j];
							}
						}
						turboRegR = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileNameR
							+ " " + width + " " + height
							+ " -translation"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 2) + " " + (height / 2)
							+ " -hideOutput"
						);
						if (turboRegR == null) {
							throw(new ClassNotFoundException());
						}
						turboRegG = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileNameG
							+ " " + width + " " + height
							+ " -translation"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 2) + " " + (height / 2)
							+ " -hideOutput"
						);
						turboRegB = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileNameB
							+ " " + width + " " + height
							+ " -translation"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 2) + " " + (height / 2)
							+ " -hideOutput"
						);
						break;
					}
					case 1: {
						sourcePoints = new double[3][3];
						for (int i = 0; (i < 3); i++) {
							sourcePoints[0][i] = 0.0;
							sourcePoints[1][i] = 0.0;
							sourcePoints[2][i] = 0.0;
							for (int j = 0; (j < 3); j++) {
								sourcePoints[0][i] += globalTransform[i][j]
									* anchorPoints[0][j];
								sourcePoints[1][i] += globalTransform[i][j]
									* anchorPoints[1][j];
								sourcePoints[2][i] += globalTransform[i][j]
									* anchorPoints[2][j];
							}
						}
						turboRegR = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileNameR
							+ " " + width + " " + height
							+ " -rigidBody"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 2) + " " + (height / 2)
							+ " " + sourcePoints[1][0] + " " + sourcePoints[1][1]
							+ " " + (width / 2) + " " + (height / 4)
							+ " " + sourcePoints[2][0] + " " + sourcePoints[2][1]
							+ " " + (width / 2) + " " + ((3 * height) / 4)
							+ " -hideOutput"
						);
						if (turboRegR == null) {
							throw(new ClassNotFoundException());
						}
						turboRegG = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileNameG
							+ " " + width + " " + height
							+ " -rigidBody"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 2) + " " + (height / 2)
							+ " " + sourcePoints[1][0] + " " + sourcePoints[1][1]
							+ " " + (width / 2) + " " + (height / 4)
							+ " " + sourcePoints[2][0] + " " + sourcePoints[2][1]
							+ " " + (width / 2) + " " + ((3 * height) / 4)
							+ " -hideOutput"
						);
						turboRegB = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileNameB
							+ " " + width + " " + height
							+ " -rigidBody"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 2) + " " + (height / 2)
							+ " " + sourcePoints[1][0] + " " + sourcePoints[1][1]
							+ " " + (width / 2) + " " + (height / 4)
							+ " " + sourcePoints[2][0] + " " + sourcePoints[2][1]
							+ " " + (width / 2) + " " + ((3 * height) / 4)
							+ " -hideOutput"
						);
						break;
					}
					case 2: {
						sourcePoints = new double[2][3];
						for (int i = 0; (i < 3); i++) {
							sourcePoints[0][i] = 0.0;
							sourcePoints[1][i] = 0.0;
							for (int j = 0; (j < 3); j++) {
								sourcePoints[0][i] += globalTransform[i][j]
									* anchorPoints[0][j];
								sourcePoints[1][i] += globalTransform[i][j]
									* anchorPoints[1][j];
							}
						}
						turboRegR = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileNameR
							+ " " + width + " " + height
							+ " -scaledRotation"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 4) + " " + (height / 2)
							+ " " + sourcePoints[1][0] + " " + sourcePoints[1][1]
							+ " " + ((3 * width) / 4) + " " + (height / 2)
							+ " -hideOutput"
						);
						if (turboRegR == null) {
							throw(new ClassNotFoundException());
						}
						turboRegG = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileNameG
							+ " " + width + " " + height
							+ " -scaledRotation"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 4) + " " + (height / 2)
							+ " " + sourcePoints[1][0] + " " + sourcePoints[1][1]
							+ " " + ((3 * width) / 4) + " " + (height / 2)
							+ " -hideOutput"
						);
						turboRegB = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileNameB
							+ " " + width + " " + height
							+ " -scaledRotation"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 4) + " " + (height / 2)
							+ " " + sourcePoints[1][0] + " " + sourcePoints[1][1]
							+ " " + ((3 * width) / 4) + " " + (height / 2)
							+ " -hideOutput"
						);
						break;
					}
					case 3: {
						sourcePoints = new double[3][3];
						for (int i = 0; (i < 3); i++) {
							sourcePoints[0][i] = 0.0;
							sourcePoints[1][i] = 0.0;
							sourcePoints[2][i] = 0.0;
							for (int j = 0; (j < 3); j++) {
								sourcePoints[0][i] += globalTransform[i][j]
									* anchorPoints[0][j];
								sourcePoints[1][i] += globalTransform[i][j]
									* anchorPoints[1][j];
								sourcePoints[2][i] += globalTransform[i][j]
									* anchorPoints[2][j];
							}
						}
						turboRegR = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileNameR
							+ " " + width + " " + height
							+ " -affine"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 2) + " " + (height / 4)
							+ " " + sourcePoints[1][0] + " " + sourcePoints[1][1]
							+ " " + (width / 4) + " " + ((3 * height) / 4)
							+ " " + sourcePoints[2][0] + " " + sourcePoints[2][1]
							+ " " + ((3 * width) / 4) + " " + ((3 * height) / 4)
							+ " -hideOutput"
						);
						if (turboRegR == null) {
							throw(new ClassNotFoundException());
						}
						turboRegG = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileNameG
							+ " " + width + " " + height
							+ " -affine"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 2) + " " + (height / 4)
							+ " " + sourcePoints[1][0] + " " + sourcePoints[1][1]
							+ " " + (width / 4) + " " + ((3 * height) / 4)
							+ " " + sourcePoints[2][0] + " " + sourcePoints[2][1]
							+ " " + ((3 * width) / 4) + " " + ((3 * height) / 4)
							+ " -hideOutput"
						);
						turboRegB = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileNameB
							+ " " + width + " " + height
							+ " -affine"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 2) + " " + (height / 4)
							+ " " + sourcePoints[1][0] + " " + sourcePoints[1][1]
							+ " " + (width / 4) + " " + ((3 * height) / 4)
							+ " " + sourcePoints[2][0] + " " + sourcePoints[2][1]
							+ " " + ((3 * width) / 4) + " " + ((3 * height) / 4)
							+ " -hideOutput"
						);
						break;
					}
					default: {
						IJ.log("Unexpected transformation");
						return(null);
					}
				}
				method = turboRegR.getClass().getMethod("getTransformedImage", null);
				transformedSourceR = (ImagePlus)method.invoke(turboRegR, null);
				method = turboRegG.getClass().getMethod("getTransformedImage", null);
				transformedSourceG = (ImagePlus)method.invoke(turboRegG, null);
				method = turboRegB.getClass().getMethod("getTransformedImage", null);
				transformedSourceB = (ImagePlus)method.invoke(turboRegB, null);
				transformedSourceR.getStack().deleteLastSlice();
				transformedSourceG.getStack().deleteLastSlice();
				transformedSourceB.getStack().deleteLastSlice();
				transformedSourceR.getProcessor().setMinAndMax(0.0, 255.0);
				transformedSourceG.getProcessor().setMinAndMax(0.0, 255.0);
				transformedSourceB.getProcessor().setMinAndMax(0.0, 255.0);
				ImageConverter converterR = new ImageConverter(transformedSourceR);
				ImageConverter converterG = new ImageConverter(transformedSourceG);
				ImageConverter converterB = new ImageConverter(transformedSourceB);
				converterR.convertToGray8();
				converterG.convertToGray8();
				converterB.convertToGray8();
				final IndexColorModel icm = (IndexColorModel)imp.getProcessor().getColorModel();
				final byte[] pixels = (byte[])imp.getProcessor().getPixels();
				r = (byte[])transformedSourceR.getProcessor().getPixels();
				g = (byte[])transformedSourceG.getProcessor().getPixels();
				b = (byte[])transformedSourceB.getProcessor().getPixels();
				final int[] color = new int[4];
				color[3] = 255;
				for (int k = 0; (k < pixels.length); k++) {
					color[0] = (int)(r[k] & 0xFF);
					color[1] = (int)(g[k] & 0xFF);
					color[2] = (int)(b[k] & 0xFF);
					pixels[k] = (byte)icm.getDataElement(color, 0);
				}
				break;
			}
			case ImagePlus.COLOR_RGB: {
				Object turboRegR = null;
				Object turboRegG = null;
				Object turboRegB = null;
				final byte[] r = new byte[width * height];
				final byte[] g = new byte[width * height];
				final byte[] b = new byte[width * height];
				((ColorProcessor)imp.getProcessor()).getRGB(r, g, b);
				final ImagePlus sourceR = new ImagePlus("StackRegSourceR",
					new ByteProcessor(width, height));
				final ImagePlus sourceG = new ImagePlus("StackRegSourceG",
					new ByteProcessor(width, height));
				final ImagePlus sourceB = new ImagePlus("StackRegSourceB",
					new ByteProcessor(width, height));
				sourceR.getProcessor().setPixels(r);
				sourceG.getProcessor().setPixels(g);
				sourceB.getProcessor().setPixels(b);
				ImagePlus transformedSourceR = null;
				ImagePlus transformedSourceG = null;
				ImagePlus transformedSourceB = null;
				final FileSaver sourceFileR = new FileSaver(sourceR);
				final String sourcePathAndFileNameR = IJ.getDirectory("temp") + sourceR.getTitle();
				sourceFileR.saveAsTiff(sourcePathAndFileNameR);
				final FileSaver sourceFileG = new FileSaver(sourceG);
				final String sourcePathAndFileNameG = IJ.getDirectory("temp") + sourceG.getTitle();
				sourceFileG.saveAsTiff(sourcePathAndFileNameG);
				final FileSaver sourceFileB = new FileSaver(sourceB);
				final String sourcePathAndFileNameB = IJ.getDirectory("temp") + sourceB.getTitle();
				sourceFileB.saveAsTiff(sourcePathAndFileNameB);
				switch (transformation) {
					case 0: {
						sourcePoints = new double[1][3];
						for (int i = 0; (i < 3); i++) {
							sourcePoints[0][i] = 0.0;
							for (int j = 0; (j < 3); j++) {
								sourcePoints[0][i] += globalTransform[i][j]
									* anchorPoints[0][j];
							}
						}
						turboRegR = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileNameR
							+ " " + width + " " + height
							+ " -translation"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 2) + " " + (height / 2)
							+ " -hideOutput"
						);
						if (turboRegR == null) {
							throw(new ClassNotFoundException());
						}
						turboRegG = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileNameG
							+ " " + width + " " + height
							+ " -translation"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 2) + " " + (height / 2)
							+ " -hideOutput"
						);
						turboRegB = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileNameB
							+ " " + width + " " + height
							+ " -translation"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 2) + " " + (height / 2)
							+ " -hideOutput"
						);
						break;
					}
					case 1: {
						sourcePoints = new double[3][3];
						for (int i = 0; (i < 3); i++) {
							sourcePoints[0][i] = 0.0;
							sourcePoints[1][i] = 0.0;
							sourcePoints[2][i] = 0.0;
							for (int j = 0; (j < 3); j++) {
								sourcePoints[0][i] += globalTransform[i][j]
									* anchorPoints[0][j];
								sourcePoints[1][i] += globalTransform[i][j]
									* anchorPoints[1][j];
								sourcePoints[2][i] += globalTransform[i][j]
									* anchorPoints[2][j];
							}
						}
						turboRegR = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileNameR
							+ " " + width + " " + height
							+ " -rigidBody"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 2) + " " + (height / 2)
							+ " " + sourcePoints[1][0] + " " + sourcePoints[1][1]
							+ " " + (width / 2) + " " + (height / 4)
							+ " " + sourcePoints[2][0] + " " + sourcePoints[2][1]
							+ " " + (width / 2) + " " + ((3 * height) / 4)
							+ " -hideOutput"
						);
						if (turboRegR == null) {
							throw(new ClassNotFoundException());
						}
						turboRegG = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileNameG
							+ " " + width + " " + height
							+ " -rigidBody"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 2) + " " + (height / 2)
							+ " " + sourcePoints[1][0] + " " + sourcePoints[1][1]
							+ " " + (width / 2) + " " + (height / 4)
							+ " " + sourcePoints[2][0] + " " + sourcePoints[2][1]
							+ " " + (width / 2) + " " + ((3 * height) / 4)
							+ " -hideOutput"
						);
						turboRegB = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileNameB
							+ " " + width + " " + height
							+ " -rigidBody"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 2) + " " + (height / 2)
							+ " " + sourcePoints[1][0] + " " + sourcePoints[1][1]
							+ " " + (width / 2) + " " + (height / 4)
							+ " " + sourcePoints[2][0] + " " + sourcePoints[2][1]
							+ " " + (width / 2) + " " + ((3 * height) / 4)
							+ " -hideOutput"
						);
						break;
					}
					case 2: {
						sourcePoints = new double[2][3];
						for (int i = 0; (i < 3); i++) {
							sourcePoints[0][i] = 0.0;
							sourcePoints[1][i] = 0.0;
							for (int j = 0; (j < 3); j++) {
								sourcePoints[0][i] += globalTransform[i][j]
									* anchorPoints[0][j];
								sourcePoints[1][i] += globalTransform[i][j]
									* anchorPoints[1][j];
							}
						}
						turboRegR = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileNameR
							+ " " + width + " " + height
							+ " -scaledRotation"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 4) + " " + (height / 2)
							+ " " + sourcePoints[1][0] + " " + sourcePoints[1][1]
							+ " " + ((3 * width) / 4) + " " + (height / 2)
							+ " -hideOutput"
						);
						if (turboRegR == null) {
							throw(new ClassNotFoundException());
						}
						turboRegG = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileNameG
							+ " " + width + " " + height
							+ " -scaledRotation"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 4) + " " + (height / 2)
							+ " " + sourcePoints[1][0] + " " + sourcePoints[1][1]
							+ " " + ((3 * width) / 4) + " " + (height / 2)
							+ " -hideOutput"
						);
						turboRegB = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileNameB
							+ " " + width + " " + height
							+ " -scaledRotation"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 4) + " " + (height / 2)
							+ " " + sourcePoints[1][0] + " " + sourcePoints[1][1]
							+ " " + ((3 * width) / 4) + " " + (height / 2)
							+ " -hideOutput"
						);
						break;
					}
					case 3: {
						sourcePoints = new double[3][3];
						for (int i = 0; (i < 3); i++) {
							sourcePoints[0][i] = 0.0;
							sourcePoints[1][i] = 0.0;
							sourcePoints[2][i] = 0.0;
							for (int j = 0; (j < 3); j++) {
								sourcePoints[0][i] += globalTransform[i][j]
									* anchorPoints[0][j];
								sourcePoints[1][i] += globalTransform[i][j]
									* anchorPoints[1][j];
								sourcePoints[2][i] += globalTransform[i][j]
									* anchorPoints[2][j];
							}
						}
						turboRegR = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileNameR
							+ " " + width + " " + height
							+ " -affine"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 2) + " " + (height / 4)
							+ " " + sourcePoints[1][0] + " " + sourcePoints[1][1]
							+ " " + (width / 4) + " " + ((3 * height) / 4)
							+ " " + sourcePoints[2][0] + " " + sourcePoints[2][1]
							+ " " + ((3 * width) / 4) + " " + ((3 * height) / 4)
							+ " -hideOutput"
						);
						if (turboRegR == null) {
							throw(new ClassNotFoundException());
						}
						turboRegG = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileNameG
							+ " " + width + " " + height
							+ " -affine"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 2) + " " + (height / 4)
							+ " " + sourcePoints[1][0] + " " + sourcePoints[1][1]
							+ " " + (width / 4) + " " + ((3 * height) / 4)
							+ " " + sourcePoints[2][0] + " " + sourcePoints[2][1]
							+ " " + ((3 * width) / 4) + " " + ((3 * height) / 4)
							+ " -hideOutput"
						);
						turboRegB = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileNameB
							+ " " + width + " " + height
							+ " -affine"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 2) + " " + (height / 4)
							+ " " + sourcePoints[1][0] + " " + sourcePoints[1][1]
							+ " " + (width / 4) + " " + ((3 * height) / 4)
							+ " " + sourcePoints[2][0] + " " + sourcePoints[2][1]
							+ " " + ((3 * width) / 4) + " " + ((3 * height) / 4)
							+ " -hideOutput"
						);
						break;
					}
					default: {
						IJ.log("Unexpected transformation");
						return(null);
					}
				}
				method = turboRegR.getClass().getMethod("getTransformedImage", null);
				transformedSourceR = (ImagePlus)method.invoke(turboRegR, null);
				method = turboRegG.getClass().getMethod("getTransformedImage", null);
				transformedSourceG = (ImagePlus)method.invoke(turboRegG, null);
				method = turboRegB.getClass().getMethod("getTransformedImage", null);
				transformedSourceB = (ImagePlus)method.invoke(turboRegB, null);
				transformedSourceR.getStack().deleteLastSlice();
				transformedSourceG.getStack().deleteLastSlice();
				transformedSourceB.getStack().deleteLastSlice();
				transformedSourceR.getProcessor().setMinAndMax(0.0, 255.0);
				transformedSourceG.getProcessor().setMinAndMax(0.0, 255.0);
				transformedSourceB.getProcessor().setMinAndMax(0.0, 255.0);
				ImageConverter converterR = new ImageConverter(transformedSourceR);
				ImageConverter converterG = new ImageConverter(transformedSourceG);
				ImageConverter converterB = new ImageConverter(transformedSourceB);
				converterR.convertToGray8();
				converterG.convertToGray8();
				converterB.convertToGray8();
				((ColorProcessor)imp.getProcessor()).setRGB(
					(byte[])transformedSourceR.getProcessor().getPixels(),
					(byte[])transformedSourceG.getProcessor().getPixels(),
					(byte[])transformedSourceB.getProcessor().getPixels());
				break;
			}
			case ImagePlus.GRAY8:
			case ImagePlus.GRAY16:
			case ImagePlus.GRAY32: {
				switch (transformation) {
					case 0: {
						sourcePoints = new double[1][3];
						for (int i = 0; (i < 3); i++) {
							sourcePoints[0][i] = 0.0;
							for (int j = 0; (j < 3); j++) {
								sourcePoints[0][i] += globalTransform[i][j]
									* anchorPoints[0][j];
							}
						}
						turboReg = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileName
							+ " " + width + " " + height
							+ " -translation"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 2) + " " + (height / 2)
							+ " -hideOutput"
						);
						break;
					}
					case 1: {
						sourcePoints = new double[3][3];
						for (int i = 0; (i < 3); i++) {
							sourcePoints[0][i] = 0.0;
							sourcePoints[1][i] = 0.0;
							sourcePoints[2][i] = 0.0;
							for (int j = 0; (j < 3); j++) {
								sourcePoints[0][i] += globalTransform[i][j]
									* anchorPoints[0][j];
								sourcePoints[1][i] += globalTransform[i][j]
									* anchorPoints[1][j];
								sourcePoints[2][i] += globalTransform[i][j]
									* anchorPoints[2][j];
							}
						}
						turboReg = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileName
							+ " " + width + " " + height
							+ " -rigidBody"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 2) + " " + (height / 2)
							+ " " + sourcePoints[1][0] + " " + sourcePoints[1][1]
							+ " " + (width / 2) + " " + (height / 4)
							+ " " + sourcePoints[2][0] + " " + sourcePoints[2][1]
							+ " " + (width / 2) + " " + ((3 * height) / 4)
							+ " -hideOutput"
						);
						break;
					}
					case 2: {
						sourcePoints = new double[2][3];
						for (int i = 0; (i < 3); i++) {
							sourcePoints[0][i] = 0.0;
							sourcePoints[1][i] = 0.0;
							for (int j = 0; (j < 3); j++) {
								sourcePoints[0][i] += globalTransform[i][j]
									* anchorPoints[0][j];
								sourcePoints[1][i] += globalTransform[i][j]
									* anchorPoints[1][j];
							}
						}
						turboReg = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileName
							+ " " + width + " " + height
							+ " -scaledRotation"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 4) + " " + (height / 2)
							+ " " + sourcePoints[1][0] + " " + sourcePoints[1][1]
							+ " " + ((3 * width) / 4) + " " + (height / 2)
							+ " -hideOutput"
						);
						break;
					}
					case 3: {
						sourcePoints = new double[3][3];
						for (int i = 0; (i < 3); i++) {
							sourcePoints[0][i] = 0.0;
							sourcePoints[1][i] = 0.0;
							sourcePoints[2][i] = 0.0;
							for (int j = 0; (j < 3); j++) {
								sourcePoints[0][i] += globalTransform[i][j]
									* anchorPoints[0][j];
								sourcePoints[1][i] += globalTransform[i][j]
									* anchorPoints[1][j];
								sourcePoints[2][i] += globalTransform[i][j]
									* anchorPoints[2][j];
							}
						}
						turboReg = IJ.runPlugIn("TurboReg_", "-transform"
							+ " -file " + sourcePathAndFileName
							+ " " + width + " " + height
							+ " -affine"
							+ " " + sourcePoints[0][0] + " " + sourcePoints[0][1]
							+ " " + (width / 2) + " " + (height / 4)
							+ " " + sourcePoints[1][0] + " " + sourcePoints[1][1]
							+ " " + (width / 4) + " " + ((3 * height) / 4)
							+ " " + sourcePoints[2][0] + " " + sourcePoints[2][1]
							+ " " + ((3 * width) / 4) + " " + ((3 * height) / 4)
							+ " -hideOutput"
						);
						break;
					}
					default: {
						IJ.log("Unexpected transformation");
						return(null);
					}
				}
				if (turboReg == null) {
					throw(new ClassNotFoundException());
				}
				method = turboReg.getClass().getMethod("getTransformedImage", null);
				ImagePlus transformedSource = (ImagePlus)method.invoke(turboReg, null);
				transformedSource.getStack().deleteLastSlice();
				switch (imp.getType()) {
					case ImagePlus.GRAY8: {
						transformedSource.getProcessor().setMinAndMax(0.0, 255.0);
						final ImageConverter converter = new ImageConverter(transformedSource);
						converter.convertToGray8();
						break;
					}
					case ImagePlus.GRAY16: {
						transformedSource.getProcessor().setMinAndMax(0.0, 65535.0);
						final ImageConverter converter = new ImageConverter(transformedSource);
						converter.convertToGray16();
						break;
					}
					case ImagePlus.GRAY32: {
						break;
					}
					default: {
						IJ.log("Unexpected image type");
						return(null);
					}
				}
				imp.setProcessor(null, transformedSource.getProcessor());
				break;
			}
			default: {
				IJ.log("Unexpected image type");
				return(null);
			}
		}
	} catch (NoSuchMethodException e) {
		IJ.log("Unexpected NoSuchMethodException " + e);
		return(null);
	} catch (IllegalAccessException e) {
		IJ.log("Unexpected IllegalAccessException " + e);
		return(null);
	} catch (InvocationTargetException e) {
		IJ.log("Unexpected InvocationTargetException " + e);
		return(null);
	} catch (ClassNotFoundException e) {
		IJ.log("Please download TurboReg_ from\nhttp://bigwww.epfl.ch/thevenaz/turboreg/");
		return(null);
	}
    	return(source);
} /* end registerSlice */

/*------------------------------------------------------------------*/
private ImagePlus[] createAdmissibleImageList (
) {
	final int[] windowList = WindowManager.getIDList();
	final Stack stack = new Stack();
	for (int k = 0; ((windowList != null) && (k < windowList.length)); k++) {
		final ImagePlus imp = WindowManager.getImage(windowList[k]);
		if ((imp != null) && ((imp.getType() == imp.GRAY16)
			|| (imp.getType() == imp.GRAY32)||(imp.getType()==imp.COLOR_RGB)||(imp.getType()==imp.COLOR_256)
			|| ((imp.getType() == imp.GRAY8) && !imp.getStack().isHSB()))) {
			stack.push(imp);
		}
	}
	final ImagePlus[] admissibleImageList = new ImagePlus[stack.size()];
	int k = 0;
	while (!stack.isEmpty()) {
		admissibleImageList[k++] = (ImagePlus)stack.pop();
	}
	return(admissibleImageList);
} /* end createAdmissibleImageList */

} /* end class StackReg_ */

/*====================================================================
|	stackRegCredits
\===================================================================*/

/********************************************************************/
class multiStackRegCredits
	extends
		Dialog

{ /* begin class multiStackRegCredits */

/*....................................................................
	Public methods
....................................................................*/

/********************************************************************/
public Insets getInsets (
) {
	return(new Insets(0, 20, 20, 20));
} /* end getInsets */

/********************************************************************/
public multiStackRegCredits (
	final Frame parentWindow
) {
	super(parentWindow, "StackReg", true);
	setLayout(new BorderLayout(0, 20));
	final Label separation = new Label("");
	final Panel buttonPanel = new Panel();
	buttonPanel.setLayout(new FlowLayout(FlowLayout.CENTER));
	final Button doneButton = new Button("Done");
	doneButton.addActionListener(
		new ActionListener (
		) {
			public void actionPerformed (
				final ActionEvent ae
			) {
				if (ae.getActionCommand().equals("Done")) {
					dispose();
				}
			}
		}
	);
	buttonPanel.add(doneButton);
	final TextArea text = new TextArea(25, 56);
	text.setEditable(false);
	text.append("\n");
	text.append("Welcome to MultiStackReg v1.1!\n");
	text.append("\n");
	text.append("This plugin has three modes of use:\n");
	text.append("1) Align a single stack of images\n");
	text.append("2) Align a stack to another stack\n");
	text.append("3) Load a previously created transformation file\n");
		
	text.append("\n");
	text.append("\n");
	text.append("To align a single stack:\n");
	text.append("\n");
	text.append("Choose the image to be aligned in the Stack 1 dropdown box.\n");
	text.append("Leave 'Align Second Stack to First' unchecked.\n");
	text.append("\n");
	text.append("\n");
	text.append("To align two stacks:\n");
	text.append("\n");
	text.append("Place the reference stack in Stack 1's box, and the stack to be\n");
	text.append("aligned in Stack 2's box.  Check the 'Align Second Stack to First'\n");
	text.append("option.\n");
	text.append("\n");
	text.append("\n");
	text.append("To load a transformation file:\n");
	text.append("\n");
	text.append("Place the stack to be aligned in Stack 1, choose 'Load Transformation\n");
	text.append("File' in the transformation dropdown box.\n");
	text.append("\n");
	text.append("\n");
	text.append("\n");
	text.append("Credits:\n");
	text.append("\n");
	text.append("\n");
	text.append(" This work is based on the following paper:\n");
	text.append("\n");
	text.append(" P. Th" + (char)233 + "venaz, U.E. Ruttimann, M. Unser\n");
	text.append(" A Pyramid Approach to Subpixel Registration Based on Intensity\n");
	text.append(" IEEE Transactions on Image Processing\n");
	text.append(" vol. 7, no. 1, pp. 27-41, January 1998.\n");
	text.append("\n");
	text.append(" This paper is available on-line at\n");
	text.append(" http://bigwww.epfl.ch/publications/thevenaz9801.html\n");
	text.append("\n");
	text.append(" Other relevant on-line publications are available at\n");
	text.append(" http://bigwww.epfl.ch/publications/\n");
	text.append("\n");
	text.append(" Additional help available at\n");
	text.append(" http://bigwww.epfl.ch/thevenaz/stackreg/\n");
	text.append("\n");
	text.append(" Ancillary TurboReg_ plugin available at\n");
	text.append(" http://bigwww.epfl.ch/thevenaz/turboreg/\n");
	text.append("\n");
	text.append(" You'll be free to use this software for research purposes, but\n");
	text.append(" you should not redistribute it without our consent. In addition,\n");
	text.append(" we expect you to include a citation or acknowledgment whenever\n");
	text.append(" you present or publish results that are based on it.\n");
	text.append("\n\n");
	text.append("A few changes (loadTransform, appendTransform, multi stack support)\n");
  text.append("to support load/save functionality and multiple stacks were\n");
  text.append("added by Brad Busse ( bbusse@stanford.edu ) and released into\n ");
	text.append("the public domain, so go by their ^^ guidelines for distribution, etc.\n");
	add("North", separation);
	add("Center", text);
	add("South", buttonPanel);
	pack();
} /* end stackRegCredits */

} /* end class stackRegCredits */
