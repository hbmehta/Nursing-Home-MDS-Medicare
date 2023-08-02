/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Tuesday, November 29, 2022     TIME: 6:41:34 PM
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

/*   START OF NODE: p04_cohort derivation   */
%LET _CLIENTTASKLABEL='p04_cohort derivation';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp';
%LET _CLIENTPROJECTPATHHOST='VDI-PS-L90350';
%LET _CLIENTPROJECTNAME='Project pimavanserin.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
options source;

/*********************************************************************
|	Cohort derivation - 03 						* 
|	Match pimavanserin users to non-users using risk-set sampling (1:10 match) (assign index date to non-users)
|
|
|*********************************************************************/
data rss; 		
	set pima.cohort_v04;
	end_fu = min(bene_death_dt, "31DEC2018"D, index_dt);

	*End of follow-up date;
	format end_fu mmddyy10.;
	survt = end_fu-park_date_v2;

	if survt >= 0;
	keep bene_id pimavanserin survt;
run;

proc freq data=rss;
	table pimavanserin;
run;

* Risk set sampling macro, ~5hrs for 1:1;
%nCCsampling (in_data= rss, n_controls= 10, outcome_var= pimavanserin, ptime_var= survt,
	id_var= bene_id, score_match='no', additional_matching_var=0, 
	variable_ratio_match='no',
	out_data= example_matched);


proc sort data=example_matched1 out=pima.matched;
	by bene_id;
run;

data pima.cohort_v05;			*104,027 patients;
	merge pima.matched(keep=bene_id pimavanserin survt time_rs rs status in=in1) pima.cohort_v04(in=in2);
	by bene_id;

	if in1;

	if pima_dt ne . then pima_2=1;else pima_2=0;

	study_end_dt = '31DEC2018'd;
	index_dt = park_date_v2+time_rs;
	format index_dt park_date_v2 pima_dt bene_death_dt study_end_dt mmddyy10.;

run;
/**************************************************************************
	Filter for non-users before May1 2016    * 100,899 patients
**************************************************************************/
data pima.cohort_v06;
	set pima.cohort_v05;
	if '01May2016'd <= index_dt <= '31Dec2018'd;
run;


proc freq data=pima.cohort_v06;
	table status;
run;



/*********************************************************************
Continuous enrollment in Medicare part A, B and D and no HMO for 6 months prior to the index date
*********************************************************************/


%macro enroll (yr = );
	Data enroll_&yr;
		merge &lib.MBSF_ABCD&yr._R9984(keep=bene_id mdcr_entlmt_buyin_ind_01-mdcr_entlmt_buyin_ind_12 ptd_cntrct_id_01-ptd_cntrct_id_12 hmo_ind_01-hmo_ind_12) 
			  pima.cohort_v06(in=in2 keep=bene_id); 
		by bene_id;
		rename mdcr_entlmt_buyin_ind_01-mdcr_entlmt_buyin_ind_12 = mdcr_entlmt_buyin_ind_&yr._01-mdcr_entlmt_buyin_ind_&yr._12
			   ptd_cntrct_id_01-ptd_cntrct_id_12 = ptd_cntrct_id_&yr._01-ptd_cntrct_id_&yr._12
			   hmo_ind_01-hmo_ind_12 = hmo_ind_&yr._01-hmo_ind_&yr._12;
		if in2;
	run;

%mend enroll;
%enroll (yr = 15);
%enroll (yr = 16);
%enroll (yr = 17);
%enroll (yr = 18);
proc sort data=enroll_15 out=enroll_nodup_15 nodup; by bene_id; run;
proc sort data=enroll_16 out=enroll_nodup_16 nodup; by bene_id; run;
proc sort data=enroll_17 out=enroll_nodup_17 nodup; by bene_id; run;
proc sort data=enroll_18 out=enroll_nodup_18 nodup; by bene_id; run;

/*proc freq data=enroll_nodup_16;*/
/*table hmo_ind_16_01-hmo_ind_16_12 mdcr_entlmt_buyin_ind_16_01;*/
/*run;*/

proc sql;	
	create table enroll as 
	select a.*, b.*, c.*, d.*
	from enroll_nodup_15 as a , enroll_nodup_16 as b, enroll_nodup_17 as c , enroll_nodup_18 as d
	where a.bene_id = b.bene_id = c.bene_id = d.bene_id 
	order by bene_id;
quit;

data enroll_pt;
	merge pima.cohort_v06 enroll;
	by bene_id;
run;


**Part A B D and no HMO enrollment;
data pima.cohort_v07;				* 57,093;
	set enroll_pt;

	Diag_index = (year(index_dt)-2015)*12 + month(index_dt);
	start_mon= Diag_index-6;

	* Part AB;
	ARRAY AB{48} $ mdcr_entlmt_buyin_ind_15_01 - mdcr_entlmt_buyin_ind_15_12
				   mdcr_entlmt_buyin_ind_16_01 - mdcr_entlmt_buyin_ind_16_12
				   mdcr_entlmt_buyin_ind_17_01 - mdcr_entlmt_buyin_ind_17_12
				   mdcr_entlmt_buyin_ind_18_01 - mdcr_entlmt_buyin_ind_18_12;

	ABflag = 0;
	DO  i = start_mon TO Diag_index;
		IF AB{i} in ('3','C') THEN ABflag=ABflag+1; 
		END;
	if ABflag=7; 

	* Part D;
	ARRAY cd{48} $ ptd_cntrct_id_15_01 - ptd_cntrct_id_15_12
				   ptd_cntrct_id_16_01 - ptd_cntrct_id_16_12
				   ptd_cntrct_id_17_01 - ptd_cntrct_id_17_12
				   ptd_cntrct_id_18_01 - ptd_cntrct_id_18_12;

	Dflag = 0;
	DO  i = start_mon TO Diag_index;
		IF (substr(cd(i),1,1) in ('H','R','S','E') or substr(cd(i),1,2)='X0') THEN Dflag=Dflag+1; 
	END;

	if Dflag=7;

	* no HMO;
	ARRAY hmo{48} $ hmo_ind_15_01-hmo_ind_15_12
				    hmo_ind_16_01-hmo_ind_16_12
				    hmo_ind_17_01-hmo_ind_17_12
				    hmo_ind_18_01-hmo_ind_18_12;

	hmoflag = 0;
	DO  i = start_mon TO Diag_index;
		IF hmo{i} in ('0') THEN hmoflag=hmoflag+1;  
	END;

	if hmoflag=7;

	drop mdcr_entlmt_buyin_ind_15_01 - mdcr_entlmt_buyin_ind_15_12
		 mdcr_entlmt_buyin_ind_16_01 - mdcr_entlmt_buyin_ind_16_12
		 mdcr_entlmt_buyin_ind_17_01 - mdcr_entlmt_buyin_ind_17_12
		 mdcr_entlmt_buyin_ind_18_01 - mdcr_entlmt_buyin_ind_18_12
		 ptd_cntrct_id_15_01 - ptd_cntrct_id_15_12
		 ptd_cntrct_id_16_01 - ptd_cntrct_id_16_12
		 ptd_cntrct_id_17_01 - ptd_cntrct_id_17_12
	 	 ptd_cntrct_id_18_01 - ptd_cntrct_id_18_12
		 hmo_ind_15_01-hmo_ind_15_12
		 hmo_ind_16_01-hmo_ind_16_12
		 hmo_ind_17_01-hmo_ind_17_12
		 hmo_ind_18_01-hmo_ind_18_12
		 Diag_index start_mon ABflag Dflag hmoflag i;
run;

proc freq data=pima.cohort_v07;
	table status;
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
