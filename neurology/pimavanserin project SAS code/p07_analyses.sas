/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Tuesday, November 29, 2022     TIME: 6:42:16 PM
PROJECT: Project pimavanserin
PROJECT PATH: U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp
---------------------------------------- */

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

/*   START OF NODE: p07_analyses   */
%LET _CLIENTTASKLABEL='p07_analyses';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp';
%LET _CLIENTPROJECTPATHHOST='VDI-PS-L90350';
%LET _CLIENTPROJECTNAME='Project pimavanserin.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
options source;

/*********************************************************************
|	Analyses - 07
|	
|
|
|*********************************************************************/

* Analysis;

/*New censor criteria - Discontinuation of pimavanserin */
proc sort data=pima.pima_clm; by bene_id pima_dt; run;
data cohort_with_pima;
	merge pima.cohort_v09_1(in=in1 keep=bene_id) pima.pima_clm(in=in2 keep=bene_id pima_dt days_suply_num);
	by bene_id;
	if in1 and in2;
	pima_end_dt = pima_dt+days_suply_num;
	lag_pima_end_dt = lag(pima_end_dt);
	format pima_end_dt lag_pima_end_dt mmddyy10.;
	if first.bene_id then lag_pima_end_dt = .;
	disconuation_days_count = pima_dt-lag_pima_end_dt;
	if disconuation_days_count > 30 or last.bene_id then discontinuation_flag = 1; else discontinuation_flag=0;
	if last.bene_id and pima_end_dt+30>'31DEC2018'd then discontinuation_flag=0;
run;

data cohort_discon_censor;
	set cohort_with_pima;
	if discontinuation_flag=1;
run;

data pima.cohort_discon_censor;
	set cohort_discon_censor;
	by bene_id;
	if last.bene_id;
	if disconuation_days_count>30 then discontinuation_dt = lag_pima_end_dt; 
		else discontinuation_dt = pima_end_dt;
	format discontinuation_dt mmddyy10.;
run;


/********************************************************************/
data pima.cohort_v10;
	merge pima.cohort_v09_1 pima.cohort_discon_censor(keep=bene_id discontinuation_dt);
	by bene_id;

	*Date of last seen (Dead or censored);
	DLS_30 = min(bene_death_dt, study_end_dt, index_dt+30, discontinuation_dt);
	if status=2 and pima_2=1 then
		DLS_30 = min(bene_death_dt, study_end_dt, index_dt+30, discontinuation_dt, pima_dt);

	DLS_90 = min(bene_death_dt, study_end_dt, index_dt+90, discontinuation_dt);
	if status=2 and pima_2=1 then
		DLS_90 = min(bene_death_dt, study_end_dt, index_dt+90, discontinuation_dt, pima_dt);

	DLS_180 = min(bene_death_dt, study_end_dt, index_dt+180, discontinuation_dt);
	if status=2 and pima_2=1 then
		DLS_180 = min(bene_death_dt, study_end_dt, index_dt+180, discontinuation_dt, pima_dt);

	DLS_365 = min(bene_death_dt, study_end_dt, index_dt+365, discontinuation_dt);
	if status=2 and pima_2=1 then
		DLS_365 = min(bene_death_dt, study_end_dt, index_dt+365, discontinuation_dt, pima_dt);
	format DLS_180 DLS_365 mmddyy10.;

	*DLS-DOA(diagnosis date);
	surv_30 = DLS_30-index_dt;
	surv_90 = DLS_90-index_dt;
	surv_180 = DLS_180-index_dt;
	surv_365 = DLS_365-index_dt;

	*Death flag;
	death=0;

	if bene_death_dt ne . then
		death=1;
	time_index_death = bene_death_dt-index_dt;
	
	death30 = 0;
	if death = 1 and 0<= time_index_death <=30 then
		death30 = 1;

	death90 = 0;
	if death = 1 and 0<= time_index_death <=90 then
		death90 = 1;

	death180 = 0;
	if death = 1 and 0<= time_index_death <=180 then
		death180 = 1;

	death365 = 0;
	if death = 1 and 0<= time_index_death <=365 then
		death365 = 1;

	status_2 = status;
	if status = 2 then status_2 = 0;
run;

proc freq data=pima.cohort_v10;
	table pimavanserin status status_2;
run;

/* Unadjusted Hazard ratio model */
proc phreg data=pima.cohort_v10;
	class / param=ref ref=first;
	model surv_30*death30(0) = status_2 / ties=discrete eventcode=1 risklimits;
	strata rs;
run;

proc phreg data=pima.cohort_v10;
	class / param=ref ref=first;
	model surv_90*death90(0) = status_2 / ties=discrete eventcode=1 risklimits;
	strata rs;
run;

proc phreg data=pima.cohort_v10;
	class / param=ref ref=first;
	model surv_180*death180(0) = status_2 / ties=discrete eventcode=1 risklimits;
	strata rs;
run;

proc phreg data=pima.cohort_v10;
	class / param=ref ref=first;
	model surv_365*death365(0) = status_2 / ties=discrete eventcode=1 risklimits;
	strata rs;
run;

/*qc*/
proc freq data=pima.cohort_v10;
	table status status*pima_2 status*pimavanserin/norow nocol nopercent;
run;


proc freq data=pima.cohort_v10;
	tables death30*status death90*status death180*status death365*status/norow nopercent;
run;
proc means data=pima.cohort_v10 mean stddev;var age; class status; run;



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
