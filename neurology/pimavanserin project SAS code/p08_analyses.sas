/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Tuesday, November 29, 2022     TIME: 6:42:22 PM
PROJECT: Project pimavanserin
PROJECT PATH: U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp
---------------------------------------- */

/* Unable to determine code to assign library PIMA on sasCCW */
/* Unable to determine code to assign library PIMA on sasCCW */
/* Unable to determine code to assign library PIMA on sasCCW */
/* Unable to determine code to assign library PIMA on sasCCW */
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

/*   START OF NODE: p08_analyses   */
%LET _CLIENTTASKLABEL='p08_analyses';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp';
%LET _CLIENTPROJECTPATHHOST='VDI-PS-L90350';
%LET _CLIENTPROJECTNAME='Project pimavanserin.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
options source;

/*********************************************************************
|	Analyses - 13
|	
|
|
|*********************************************************************/

/* Hospitalization - has a non-SNF record in medpar within 30/90/180/365 days from index_dt */
/* variable - SS_LS_SNF_IND_CD */

data hospitalization;
	set &lib.MEDPAR15_R9984 &lib.MEDPAR16_R9984 &lib.MEDPAR17_R9984 &lib.MEDPAR18_R9984;
	keep bene_id ADMSN_DT SS_LS_SNF_IND_CD;
	if SS_LS_SNF_IND_CD ne "N";
run;
proc sort data=hospitalization nodup; by _all_; run;

data pima.hospitalization;
	merge hospitalization pima.cohort_v10(in=in2 keep=bene_id); * restrict only bene_id for our need;
	by bene_id;
	if in2;
	keep bene_id ADMSN_DT;
run;
proc sort data=pima.hospitalization nodup; by _all_; run;

/****************************************************************/
/****************************************************************/
/* 30-day */
/****************************************************************/
/****************************************************************/

proc sql;
	create table hospitalization_30 as
	select a.*, b.bene_id, b.index_dt
	from pima.hospitalization as a, 
		 pima.cohort_v10 as b
	where a.bene_id = b.bene_id and	
		  b.index_dt < a.ADMSN_DT < b.index_dt+30;
quit;
proc sort data=hospitalization_30 nodup; by bene_id index_dt ADMSN_DT; run;

data hospitalization_30_1;
	set hospitalization_30;
	by bene_id index_dt;
	if first.bene_id or first.index_dt;
	rename ADMSN_DT = hosp_date_30;
run;

data pima.cohort_v11;
	merge pima.cohort_v10 hospitalization_30_1;
	by bene_id index_dt;

	/* create hospitalization time variable */
	hosp_DLS_30 = min(discontinuation_dt, hosp_date_30, study_end_dt, index_dt+30);
		if status=2 and pima_2=1 then
		hosp_DLS_30 = min(discontinuation_dt, hosp_date_30, study_end_dt, index_dt+30, pima_dt);
	hosp_surv_30 = hosp_DLS_30-index_dt;
	format hosp_DLS_30 mmddyy10.;

	/* create hospitalization flag variable */
	hosp_flag_30 = 0;
	if hosp_date_30 ne . and hosp_DLS_30=hosp_date_30 then hosp_flag_30 = 1;

run;
/* Unadjusted Hazard ratio model */
proc phreg data=pima.cohort_v11;
	class / param=ref ref=first;
	model hosp_surv_30*hosp_flag_30(0) = status_2 / ties=discrete eventcode=1 risklimits;
	strata rs;
run;

proc freq data=pima.cohort_v11;
	table hosp_flag_30*status/norow nopercent;
run;


/****************************************************************/
/****************************************************************/
/* 90-day */
/****************************************************************/
/****************************************************************/

proc sql;
	create table hospitalization_90 as
	select a.*, b.bene_id, b.index_dt
	from pima.hospitalization as a, 
		 pima.cohort_v11 as b
	where a.bene_id = b.bene_id and	
		  b.index_dt < a.ADMSN_DT < b.index_dt+90;
quit;
proc sort data=hospitalization_90 nodup; by bene_id index_dt ADMSN_DT; run;

data hospitalization_90_1;
	set hospitalization_90;
	by bene_id index_dt;
	if first.bene_id or first.index_dt;
	rename ADMSN_DT = hosp_date_90;
run;

data pima.cohort_v12;
	merge pima.cohort_v11 hospitalization_90_1;
	by bene_id index_dt;

	/* create hospitalization time variable */
	hosp_DLS_90 = min(discontinuation_dt, hosp_date_90, study_end_dt, index_dt+90);
		if status=2 and pima_2=1 then
		hosp_DLS_90 = min(discontinuation_dt, hosp_date_90, study_end_dt, index_dt+90, pima_dt);
	hosp_surv_90 = hosp_DLS_90-index_dt;
	format hosp_DLS_90 mmddyy10.;

	/* create hospitalization flag variable */
	hosp_flag_90 = 0;
	if hosp_date_90 ne . and hosp_DLS_90=hosp_date_90 then hosp_flag_90 = 1;

run;
/* Unadjusted Hazard ratio model */
proc phreg data=pima.cohort_v12;
	class / param=ref ref=first;
	model hosp_surv_90*hosp_flag_90(0) = status_2 / ties=discrete eventcode=1 risklimits;
	strata rs;
run;

proc freq data=pima.cohort_v12;
	table hosp_flag_90*status/norow nopercent;
run;

/****************************************************************/
/****************************************************************/
/* 180-day */
/****************************************************************/
/****************************************************************/

proc sql;
	create table hospitalization_180 as
	select a.*, b.bene_id, b.index_dt
	from pima.hospitalization as a, 
		 pima.cohort_v12 as b
	where a.bene_id = b.bene_id and	
		  b.index_dt < a.ADMSN_DT < b.index_dt+180;
quit;
proc sort data=hospitalization_180 nodup; by bene_id index_dt ADMSN_DT; run;

data hospitalization_180_1;
	set hospitalization_180;
	by bene_id index_dt;
	if first.bene_id or first.index_dt;
	rename ADMSN_DT = hosp_date_180;
run;

data pima.cohort_v13;
	merge pima.cohort_v12 hospitalization_180_1;
	by bene_id index_dt;

	/* create hospitalization time variable */
	hosp_DLS_180 = min(discontinuation_dt, hosp_date_180, study_end_dt, index_dt+180);
		if status=2 and pima_2=1 then
		hosp_DLS_180 = min(discontinuation_dt, hosp_date_180, study_end_dt, index_dt+180, pima_dt);
	hosp_surv_180 = hosp_DLS_180-index_dt;
	format hosp_DLS_180 mmddyy10.;

	/* create hospitalization flag variable */
	hosp_flag_180 = 0;
	if hosp_date_180 ne . and hosp_DLS_180=hosp_date_180 then hosp_flag_180 = 1;

run;
/* Unadjusted Hazard ratio model */
proc phreg data=pima.cohort_v13;
	class / param=ref ref=first;
	model hosp_surv_180*hosp_flag_180(0) = status_2 / ties=discrete eventcode=1 risklimits;
	strata rs;
run;

proc freq data=pima.cohort_v13;
	table hosp_flag_180*status/norow nopercent;
run;



/****************************************************************/
/****************************************************************/
/* 365-day */
/****************************************************************/
/****************************************************************/

proc sql;
	create table hospitalization_365 as
	select a.*, b.bene_id, b.index_dt
	from pima.hospitalization as a, 
		 pima.cohort_v13 as b
	where a.bene_id = b.bene_id and	
		  b.index_dt < a.ADMSN_DT < b.index_dt+365;
quit;
proc sort data=hospitalization_365 nodup; by bene_id index_dt ADMSN_DT; run;

data hospitalization_365_1;
	set hospitalization_365;
	by bene_id index_dt;
	if first.bene_id or first.index_dt;
	rename ADMSN_DT = hosp_date_365;
run;

data pima.cohort_v14;
	merge pima.cohort_v13 hospitalization_365_1;
	by bene_id index_dt;

	/* create hospitalization time variable */
	hosp_DLS_365 = min(discontinuation_dt, hosp_date_365, study_end_dt, index_dt+365);
		if status=2 and pima_2=1 then
		hosp_DLS_365 = min(discontinuation_dt, hosp_date_365, study_end_dt, index_dt+365, pima_dt);
	hosp_surv_365 = hosp_DLS_365-index_dt;
	format hosp_DLS_365 mmddyy10.;

	/* create hospitalization flag variable */
	hosp_flag_365 = 0;
	if hosp_date_365 ne . and hosp_DLS_365=hosp_date_365 then hosp_flag_365 = 1;

run;
/* Unadjusted Hazard ratio model */
proc phreg data=pima.cohort_v14;
	class / param=ref ref=first;
	model hosp_surv_365*hosp_flag_365(0) = status_2 / ties=discrete eventcode=1 risklimits;
	strata rs;
run;

proc freq data=pima.cohort_v14;
	table hosp_flag_365*status/norow nopercent;
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
