/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Tuesday, November 29, 2022     TIME: 6:42:57 PM
PROJECT: Project pimavanserin
PROJECT PATH: U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp
---------------------------------------- */

/* Unable to determine code to assign library PIMA on sasCCW */

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

/*   START OF NODE: p12_covariate   */
%LET _CLIENTTASKLABEL='p12_covariate';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp';
%LET _CLIENTPROJECTPATHHOST='VDI-PS-L90350';
%LET _CLIENTPROJECTNAME='Project pimavanserin.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
options source;

/*********************************************************************
|	11 - Covariates
|	Comorbidities
|
|
|*********************************************************************/


/**************************************************************************
	Identify comorbidities -- Medpar	
**************************************************************************/
%macro medpar (yr = );
	Data como_m_&yr;
	set &lib.MEDPAR&yr._R9984 (keep = bene_id dgns_1_cd--dgns_25_cd admsn_dt dschrg_dt los_day_cnt);

	Depr = 0; *Depression;
	Sch = 0; *Schizophrenia;
	BD = 0; *Bipolar disorder;
	Fall = 0; *Falls;
	Pneumonia = 0; *Pneumonia;
	UTI = 0; *Urinary tract infection;

	array diag dgns_1_cd--dgns_25_cd;
	do i = 1 to dim(diag);
		if diag(i) in: ("F32","F33") then Depr = 1;
		if diag(i) in: ("F20","F25") then Sch = 1;
		if diag(i) in: ("F30","F31") then BD = 1;
		if diag(i) in: ("W00","W01","W02","W03","W04","W05","W06","W07","W08","W09","W10","W11","W12","W13","W14","W15","W16","W17","W18","W19") then Fall = 1;
		if diag(i) in: ("J12","J13","J14","J15","J16","J17","J18") then Pneumonia = 1;
		if diag(i) in: ("N10","N300","N390") then UTI = 1;
	end;
	run;

%mend medpar;
%medpar (yr = 15);
%medpar (yr = 16);
%medpar (yr = 17);
%medpar (yr = 18);

data como_m;
	set como_m_15-como_m_18;
	keep bene_id admsn_dt Depr Sch BD Fall Pneumonia UTI;
run;
proc sort data=como_m out=como_m nodupkey;    
	by _all_;
run;

/**************************************************************************
	Identify comorbidities -- OUTSAF	
**************************************************************************/
%macro outsaf (yr = );
	Data como_o_&yr;
	set &lib.OTPTCLMSK&yr._R9984 (keep = bene_id icd_dgns_cd1--icd_dgns_cd25 clm_thru_dt);
		
	Depr = 0; *Depression;
	Sch = 0; *Schizophrenia;
	BD = 0; *Bipolar disorder;
	Fall = 0; *Falls;
	Pneumonia = 0; *Pneumonia;
	UTI = 0; *Urinary tract infection;

	array diag icd_dgns_cd1--icd_dgns_cd25;
	do i = 1 to dim(diag);
		if diag(i) in: ("F32","F33") then Depr = 1;
		if diag(i) in: ("F20","F25") then Sch = 1;
		if diag(i) in: ("F30","F31") then BD = 1;
		if diag(i) in: ("W00","W01","W02","W03","W04","W05","W06","W07","W08","W09","W10","W11","W12","W13","W14","W15","W16","W17","W18","W19") then Fall = 1;
		if diag(i) in: ("J12","J13","J14","J15","J16","J17","J18") then Pneumonia = 1;
		if diag(i) in: ("N10","N300","N390") then UTI = 1;
	end;
	run;

%mend outsaf;
%outsaf (yr = 15);
%outsaf (yr = 16);
%outsaf (yr = 17);
%outsaf (yr = 18);

data como_o;
	set como_o_15-como_o_18;
	keep bene_id clm_thru_dt Depr Sch BD Fall Pneumonia UTI;
run;
proc sort data=como_o out=como_o nodupkey;    
	by _all_;
run;

/**************************************************************************
	Identify comorbidities -- CARRIER	
**************************************************************************/
%macro carrier (yr = );
	Data como_c_&yr;
	set &lib.BCARCLMSK&yr._R9984 (keep = bene_id icd_dgns_cd1-icd_dgns_cd12 clm_thru_dt);
	
	Depr = 0; *Depression;
	Sch = 0; *Schizophrenia;
	BD = 0; *Bipolar disorder;
	Fall = 0; *Falls;
	Pneumonia = 0; *Pneumonia;
	UTI = 0; *Urinary tract infection;

	array diag icd_dgns_cd1-icd_dgns_cd12;
	do i = 1 to dim(diag);
		if diag(i) in: ("F32","F33") then Depr = 1;
		if diag(i) in: ("F20","F25") then Sch = 1;
		if diag(i) in: ("F30","F31") then BD = 1;
		if diag(i) in: ("W00","W01","W02","W03","W04","W05","W06","W07","W08","W09","W10","W11","W12","W13","W14","W15","W16","W17","W18","W19") then Fall = 1;
		if diag(i) in: ("J12","J13","J14","J15","J16","J17","J18") then Pneumonia = 1;
		if diag(i) in: ("N10","N300","N390") then UTI = 1;
	end;
	run;

%mend carrier;
%carrier (yr = 15);
%carrier (yr = 16);
%carrier (yr = 17);
%carrier (yr = 18);

data como_c;
	set como_c_15-como_c_18;
	keep bene_id clm_thru_dt Depr Sch BD Fall Pneumonia UTI;
run;
proc sort data=como_c out=como_c nodupkey;    
	by _all_;
run;




/* combine the three */
data pima.com;
	set como_c como_o como_m(rename=(admsn_dt=clm_thru_dt));
run;
proc sort data=pima.com out=pima.com nodupkey;				
	by _all_;
run;


/* filter for diagnosis six months prior the index_date */
data pima.covariate_v08;
	set pima.covariate_v08;

	six_mon_prior = intnx('month',index_dt,-6,"sameday");
	format six_mon_prior mmddyy10.;
run;

proc sql;
	create table com_2 as
	select a.*, b.bene_id, b.index_dt, b.six_mon_prior
	from pima.com as a, pima.covariate_v08 as b
	where a.bene_id=b.bene_id and six_mon_prior < clm_thru_dt < index_dt;
quit;

     
proc sql;				
	create table pima.com_summarized as				
	select bene_id, index_dt, max(Depr) as Depr, max(Sch) as Sch, max(BD) as BD, max(Fall) as Fall, max(Pneumonia) as Pneumonia, max(UTI) as UTI
	from com_2
	group by bene_id, index_dt;
quit;



/* Final step - merge to cohort */
data pima.covariate_v09;
	merge pima.covariate_v08(in=in1) pima.com_summarized;
	by bene_id index_dt;
	if in1;
run;

proc freq data=pima.covariate_v09;
	table Depr Sch BD Fall Pneumonia UTI/missing;
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
