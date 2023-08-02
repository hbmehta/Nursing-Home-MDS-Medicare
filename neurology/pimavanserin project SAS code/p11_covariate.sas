/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Tuesday, November 29, 2022     TIME: 6:42:44 PM
PROJECT: Project pimavanserin
PROJECT PATH: U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp
---------------------------------------- */

/* ---------------------------------- */
/* MACRO: enterpriseguide             */
/* PURPOSE: define a macro variable   */
/*   that contains the file system    */
/*   path of the WORK library on the  */
/*   server.  Note that different     */
/*   logic is needed depending on the */
/*   server type.                     */
/* ---------------------------------- */
%macro enterpriseguide;
%global sasworklocation;
%local tempdsn unique_dsn path;

%if &sysscp=OS %then %do; /* MVS Server */
	%if %sysfunc(getoption(filesystem))=MVS %then %do;
        /* By default, physical file name will be considered a classic MVS data set. */
	    /* Construct dsn that will be unique for each concurrent session under a particular account: */
		filename egtemp '&egtemp' disp=(new,delete); /* create a temporary data set */
 		%let tempdsn=%sysfunc(pathname(egtemp)); /* get dsn */
		filename egtemp clear; /* get rid of data set - we only wanted its name */
		%let unique_dsn=".EGTEMP.%substr(&tempdsn, 1, 16).PDSE"; 
		filename egtmpdir &unique_dsn
			disp=(new,delete,delete) space=(cyl,(5,5,50))
			dsorg=po dsntype=library recfm=vb
			lrecl=8000 blksize=8004 ;
		options fileext=ignore ;
	%end; 
 	%else %do; 
        /* 
		By default, physical file name will be considered an HFS 
		(hierarchical file system) file. 
		*/
		%if "%sysfunc(getoption(filetempdir))"="" %then %do;
			filename egtmpdir '/tmp';
		%end;
		%else %do;
			filename egtmpdir "%sysfunc(getoption(filetempdir))";
		%end;
	%end; 
	%let path=%sysfunc(pathname(egtmpdir));
    %let sasworklocation=%sysfunc(quote(&path));  
%end; /* MVS Server */
%else %do;
	%let sasworklocation = "%sysfunc(getoption(work))/";
%end;
%if &sysscp=VMS_AXP %then %do; /* Alpha VMS server */
	%let sasworklocation = "%sysfunc(getoption(work))";                         
%end;
%if &sysscp=CMS %then %do; 
	%let path = %sysfunc(getoption(work));                         
	%let sasworklocation = "%substr(&path, %index(&path,%str( )))";
%end;
%mend enterpriseguide;

%enterpriseguide


/* Conditionally delete set of tables or views, if they exists          */
/* If the member does not exist, then no action is performed   */
%macro _eg_conditional_dropds /parmbuff;
	
   	%local num;
   	%local stepneeded;
   	%local stepstarted;
   	%local dsname;
	%local name;

   	%let num=1;
	/* flags to determine whether a PROC SQL step is needed */
	/* or even started yet                                  */
	%let stepneeded=0;
	%let stepstarted=0;
   	%let dsname= %qscan(&syspbuff,&num,',()');
	%do %while(&dsname ne);	
		%let name = %sysfunc(left(&dsname));
		%if %qsysfunc(exist(&name)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;

			%end;
				drop table &name;
		%end;

		%if %sysfunc(exist(&name,view)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;
			%end;
				drop view &name;
		%end;
		%let num=%eval(&num+1);
      	%let dsname=%qscan(&syspbuff,&num,',()');
	%end;
	%if &stepstarted %then %do;
		quit;
	%end;
%mend _eg_conditional_dropds;


/* save the current settings of XPIXELS and YPIXELS */
/* so that they can be restored later               */
%macro _sas_pushchartsize(new_xsize, new_ysize);
	%global _savedxpixels _savedypixels;
	options nonotes;
	proc sql noprint;
	select setting into :_savedxpixels
	from sashelp.vgopt
	where optname eq "XPIXELS";
	select setting into :_savedypixels
	from sashelp.vgopt
	where optname eq "YPIXELS";
	quit;
	options notes;
	GOPTIONS XPIXELS=&new_xsize YPIXELS=&new_ysize;
%mend _sas_pushchartsize;

/* restore the previous values for XPIXELS and YPIXELS */
%macro _sas_popchartsize;
	%if %symexist(_savedxpixels) %then %do;
		GOPTIONS XPIXELS=&_savedxpixels YPIXELS=&_savedypixels;
		%symdel _savedxpixels / nowarn;
		%symdel _savedypixels / nowarn;
	%end;
%mend _sas_popchartsize;


ODS PROCTITLE;
OPTIONS DEV=ACTIVEX;
GOPTIONS XPIXELS=0 YPIXELS=0;
FILENAME EGSRX TEMP;
ODS tagsets.sasreport13(ID=EGSRX) FILE=EGSRX
    STYLE=HTMLBlue
    STYLESHEET=(URL="file:///C:/Program%20Files/SASHome/SASEnterpriseGuide/7.1/Styles/HTMLBlue.css")
    NOGTITLE
    NOGFOOTNOTE
    GPATH=&sasworklocation
    ENCODING=UTF8
    options(rolap="on")
;

/*   START OF NODE: p11_covariate   */
%LET _CLIENTTASKLABEL='p11_covariate';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp';
%LET _CLIENTPROJECTPATHHOST='VDI-PS-L90350';
%LET _CLIENTPROJECTNAME='Project pimavanserin.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
options source;

/*********************************************************************
|	10 - Covariates
|	Charlson comorobidities
|
|
|*********************************************************************/

/*******************************************/
/*  First prepare nch outsaf medpar data   */
/*******************************************/

/*NCH*/
%macro nch (out_file, in_file);
	data &out_file;
		merge &lib.&in_file(in=in1 keep=bene_id CLM_FROM_DT LINE_ICD_DGNS_CD PRNCPAL_DGNS_CD ICD_DGNS_CD1-ICD_DGNS_CD12)
			  pima.cohort_v10(in=in2 keep=bene_id);		
		by bene_id;
		if in1 and in2;
		from_dtm = month(CLM_FROM_DT);
		from_dtd = day(CLM_FROM_DT);
		from_dty = year(CLM_FROM_DT);

		keep bene_id from_dtm from_dtd from_dty LINE_ICD_DGNS_CD PRNCPAL_DGNS_CD ICD_DGNS_CD1-ICD_DGNS_CD12;
		rename bene_id=patient_id LINE_ICD_DGNS_CD=dgn_cd13 PRNCPAL_DGNS_CD=dgn_cd14 ICD_DGNS_CD1-ICD_DGNS_CD12=dgn_cd1-dgn_cd12;
	run;
%mend nch;

%nch (nch_15, BCARCLMSK15_R9984);
%nch (nch_16, BCARCLMSK16_R9984);
%nch (nch_17, BCARCLMSK17_R9984);
%nch (nch_18, BCARCLMSK18_R9984);

data nch; set nch_15-nch_18; run;


/*OUTPATIENT*/
%macro outsaf (out_file, in_file);
	data &out_file;
		merge &lib.&in_file(in=in1 keep=bene_id CLM_FROM_DT ICD_DGNS_CD1-ICD_DGNS_CD25 ICD_PRCDR_CD1-ICD_PRCDR_CD25)
			  pima.cohort_v10(in=in2 keep=bene_id);		
		by bene_id;
		if in1 and in2;
		from_dtm = month(CLM_FROM_DT);
		from_dtd = day(CLM_FROM_DT);
		from_dty = year(CLM_FROM_DT);

		keep bene_id from_dtm from_dtd from_dty ICD_DGNS_CD1-ICD_DGNS_CD25 ICD_PRCDR_CD1-ICD_PRCDR_CD25;
		rename bene_id=patient_id ICD_DGNS_CD1-ICD_DGNS_CD25=dgn_cd1-dgn_cd25;
	run;
%mend outsaf;

%outsaf (outsaf_15, OTPTCLMSK15_R9984);
%outsaf (outsaf_16, OTPTCLMSK16_R9984);
%outsaf (outsaf_17, OTPTCLMSK17_R9984);
%outsaf (outsaf_18, OTPTCLMSK18_R9984);

data outsaf; set outsaf_15-outsaf_18; run;


/*MEDPAR*/
%macro medpar (out_file, in_file);
	data &out_file;
		merge &lib.&in_file(in=in1 keep=bene_id ADMSN_DT DGNS_1_CD DGNS_2_CD DGNS_3_CD DGNS_4_CD DGNS_5_CD
										DGNS_6_CD DGNS_7_CD DGNS_8_CD DGNS_9_CD DGNS_10_CD DGNS_11_CD DGNS_12_CD
										DGNS_13_CD DGNS_14_CD DGNS_15_CD DGNS_16_CD DGNS_17_CD DGNS_18_CD DGNS_19_CD
										DGNS_20_CD DGNS_21_CD DGNS_22_CD DGNS_23_CD DGNS_24_CD DGNS_25_CD
										LOS_DAY_CNT ADMTG_DGNS_CD
										SRGCL_PRCDR_1_CD SRGCL_PRCDR_2_CD SRGCL_PRCDR_3_CD SRGCL_PRCDR_4_CD SRGCL_PRCDR_5_CD
										SRGCL_PRCDR_6_CD SRGCL_PRCDR_7_CD SRGCL_PRCDR_8_CD SRGCL_PRCDR_9_CD SRGCL_PRCDR_10_CD
										SRGCL_PRCDR_11_CD SRGCL_PRCDR_12_CD SRGCL_PRCDR_13_CD SRGCL_PRCDR_14_CD SRGCL_PRCDR_15_CD
										SRGCL_PRCDR_16_CD SRGCL_PRCDR_17_CD SRGCL_PRCDR_18_CD SRGCL_PRCDR_19_CD SRGCL_PRCDR_20_CD
										SRGCL_PRCDR_21_CD SRGCL_PRCDR_22_CD SRGCL_PRCDR_23_CD SRGCL_PRCDR_24_CD SRGCL_PRCDR_25_CD)
			  pima.cohort_v10(in=in2 keep=bene_id);		
		by bene_id;
		if in1 and in2;
		from_dtm = month(ADMSN_DT);
		from_dtd = day(ADMSN_DT);
		from_dty = year(ADMSN_DT);

		drop ADMSN_DT;
		rename bene_id=patient_id LOS_DAY_CNT=los ADMTG_DGNS_CD=admdxcde
				DGNS_1_CD=dgn_cd1 DGNS_2_CD=dgn_cd2 DGNS_3_CD=dgn_cd3 DGNS_4_CD=dgn_cd4 DGNS_5_CD=dgn_cd5
				DGNS_6_CD=dgn_cd6 DGNS_7_CD=dgn_cd7 DGNS_8_CD=dgn_cd8 DGNS_9_CD=dgn_cd9 DGNS_10_CD=dgn_cd10
				DGNS_11_CD=dgn_cd11 DGNS_12_CD=dgn_cd12 DGNS_13_CD=dgn_cd13 DGNS_14_CD=dgn_cd14 DGNS_15_CD=dgn_cd15
				DGNS_16_CD=dgn_cd16 DGNS_17_CD=dgn_cd17 DGNS_18_CD=dgn_cd18 DGNS_19_CD=dgn_cd19 DGNS_20_CD=dgn_cd20
				DGNS_21_CD=dgn_cd21 DGNS_22_CD=dgn_cd22 DGNS_23_CD=dgn_cd23 DGNS_24_CD=dgn_cd24 DGNS_25_CD=dgn_cd25
				SRGCL_PRCDR_1_CD=srgcde1 SRGCL_PRCDR_2_CD=srgcde2 SRGCL_PRCDR_3_CD=srgcde3 SRGCL_PRCDR_4_CD=srgcde4 SRGCL_PRCDR_5_CD=srgcde5
				SRGCL_PRCDR_6_CD=srgcde6 SRGCL_PRCDR_7_CD=srgcde7 SRGCL_PRCDR_8_CD=srgcde8 SRGCL_PRCDR_9_CD=srgcde9 SRGCL_PRCDR_10_CD=srgcde10
				SRGCL_PRCDR_11_CD=srgcde11 SRGCL_PRCDR_12_CD=srgcde12 SRGCL_PRCDR_13_CD=srgcde13 SRGCL_PRCDR_14_CD=srgcde14 SRGCL_PRCDR_15_CD=srgcde15
				SRGCL_PRCDR_16_CD=srgcde16 SRGCL_PRCDR_17_CD=srgcde17 SRGCL_PRCDR_18_CD=srgcde18 SRGCL_PRCDR_19_CD=srgcde19 SRGCL_PRCDR_20_CD=srgcde20
				SRGCL_PRCDR_21_CD=srgcde21 SRGCL_PRCDR_22_CD=srgcde22 SRGCL_PRCDR_23_CD=srgcde23 SRGCL_PRCDR_24_CD=srgcde24 SRGCL_PRCDR_25_CD=srgcde25;
	run;
%mend medpar;

%medpar (medpar_15, MEDPAR15_R9984);
%medpar (medpar_16, MEDPAR16_R9984);
%medpar (medpar_17, MEDPAR17_R9984);
%medpar (medpar_18, MEDPAR18_R9984);

data medpar; set medpar_15-medpar_18; run;



/**********************************************************************************************************************/
/*  comorbidity.input.file.example.sas                                                                                */
/*  Last updated: 3/9/2017                                                                                            */
/**********************************************************************************************************************/
/*  This SAS program is one example of how to build an input file for the comorobidity macro.                         */
/*  It can be used as a template for your program, depending on which files and variables you have.                   */
/*  SAS date variables are created for the diagnosis date, start & end of the comorbidity window, and the claim date. */
/*  Diagnosis and surgical procedure variables are renamed so that they are mostly the same across claims files.      */
/*  All unnecessary variables are dropped, for better efficiency, and the claims files are "set" together.            */
/*  Then, only the claims within the window (+/- 30 days) are selected out of all claims for the patients in PEDSF.   */
/**********************************************************************************************************************/
data pima.cci_PEDSF;
  set pima.covariate_v07(keep=bene_id park_date_v2);
  dx_date    = mdy(month(park_date_v2),1,year(park_date_v2));
  start_date = mdy(month(park_date_v2),1,year(park_date_v2)-1); /* first day of the month a year before diagnosis */
  end_date   = mdy(month(park_date_v2),1,year(park_date_v2))-1; /* last day of the month before diagnosis */
  format dx_date start_date end_date mmddyy10.;
  label 
    dx_date    = 'Date of diagnosis'
    start_date = 'One year before date of diagnosis'
    end_date   = 'Last day before month of diagnosis'
    ;
	rename bene_id=pt_id;
run;

data pima.Claims_pre;
  length dgn_cd1-dgn_cd25 $7. srgcde1-srgcde25 $4.;
  set 
    MEDPAR(in=M)
    OUTSAF(in=O)
    NCH(in=N)
    ;
  if M then filetype = "M";
  else if O then filetype = "O";
  else if N then filetype = "N";
  claim_date = mdy(from_dtm,from_dtd,from_dty); 
  drop from_dtm from_dtd from_dty;
  format claim_date mmddyy10.;
  label claim_date = 'Date of claim';
run;

proc sql; 						* 996000;
  create table Claims as  
  select * 
  from
    pima.Claims_pre as c,
    pima.cci_PEDSF as p
  where (c.patient_id=p.pt_id) and ( (p.start_date-30)<=c.claim_date<=(p.end_date+30) )
  order by c.patient_id, c.claim_date;
quit;

/*need to copy claims file to work library*/
%COMORB(Claims,patient_id,start_date,end_date,claim_date,filetype,los,admdxcde dgn_cd1-dgn_cd25,srgcde1-srgcde25,R,pima.Comorb); *24135;

data pima.covariate_v08;
	merge pima.covariate_v07(in=in1) pima.comorb(keep=patient_id Charlson acute_mi history_mi chf pvd
													  cvd copd dementia paralysis diabetes diabetes_comp
													  renal_disease any_malignancy solid_tumor mild_liver_disease
													  liver_disease ulcers rheum_disease aids
												 rename=(patient_id=bene_id));
	by bene_id;
	if in1;

	if Charlson = "." then Charlson = 0;
run;

proc freq data=pima.covariate_v08;
	table acute_mi history_mi chf pvd cvd copd dementia paralysis diabetes diabetes_comp
		renal_disease any_malignancy solid_tumor mild_liver_disease liver_disease ulcers rheum_disease aids;
run;

options nosource;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
