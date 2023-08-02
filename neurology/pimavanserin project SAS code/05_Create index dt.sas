/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Tuesday, November 29, 2022     TIME: 6:41:00 PM
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

/*   START OF NODE: 05_Create index dt   */
%LET _CLIENTTASKLABEL='05_Create index dt';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp';
%LET _CLIENTPROJECTPATHHOST='VDI-PS-L90350';
%LET _CLIENTPROJECTNAME='Project pimavanserin.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
options source;

data rss;
	set cohort_v04;
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
%nCCsampling (in_data= rss, n_controls= 20, outcome_var= pimavanserin, ptime_var= survt,
	id_var= bene_id, score_match='no', additional_matching_var=0, 
	variable_ratio_match='no',
	out_data= example_matched3);

/**********************************************************************************************************************************************************/
* Descriptive checks;
*1. count unique patients in 1:10 matched;
proc sql;
	select count(bene_id) as unique_count
		from (select distinct bene_id from EXAMPLE_MATCHED2);
quit;

* 9421 cases, 9421*11 = 103631 total, 92250-9421~82000 unique controls among 94210 controls;
*2. count unique number of cases matched as controls;
data controls;
	set example_matched2;

	if pimavanserin = 0;
run;

proc sql;
	select count(bene_id) as unique_count
		from (select distinct bene_id from controls)
			where bene_id in (select bene_id from cases);
quit;

* 982 cases were matched as controls;
/**********************************************************************************************************************************************************/
* Analysis;
proc sort data=example_matched2 out=matched;
	by bene_id;
run;

data cohort_v05;
	merge matched(keep=bene_id pimavanserin survt time_rs rs status in=in1) cohort_v04(keep=bene_id park_date_v2 pima_dt bene_death_dt in=in2);
	by bene_id;

	if in1;

	if pima_dt ne . then pima_2=1;else pima_2=0;

	study_end_dt = '31DEC2018'd;
	index_dt = park_date_v2+time_rs;
	format index_dt park_date_v2 pima_dt bene_death_dt study_end_dt mmddyy10.;

	*Date of last seen (Dead or censored);
	DLS_180 = min(bene_death_dt, study_end_dt, index_dt+180);
	if status=2 and pima_2=1 then
		DLS_180 = min(bene_death_dt, study_end_dt, index_dt+180, pima_dt);

	DLS_365 = min(bene_death_dt, study_end_dt, index_dt+365);
	if status=2 and pima_2=1 then
		DLS_365 = min(bene_death_dt, study_end_dt, index_dt+365, pima_dt);
	format DLS_180 DLS_365 mmddyy10.;

	*DLS-DOA(diagnosis date);
	surv_180 = DLS_180-index_dt;
	surv_365 = DLS_365-index_dt;

	*Death flag;
	death=0;

	if bene_death_dt ne . then
		death=1;
	time_index_death = bene_death_dt-index_dt;

	death180 = 0;
	if death = 1 and 0<= time_index_death <=180 then
		death180 = 1;

	death365 = 0;
	if death = 1 and 0<= time_index_death <=365 then
		death365 = 1;
run;

/* Unadjusted Hazard ratio model */

proc phreg data=cohort_v05;
	class / param=ref ref=first;
	model surv_180*death180(0) = pimavanserin / ties=discrete eventcode=1 risklimits;
	strata rs;
run;

proc phreg data=cohort_v05;
	class / param=ref ref=first;
	model surv_365*death365(0) = pimavanserin / ties=discrete eventcode=1 risklimits;
	strata rs;
run;

/*qc*/
proc freq data=cohort_v05;
	table status status*pima_2 status*pimavanserin/norow nocol nopercent;
run;


data test;
set cohort_v05;

	death30 = 0;
	if death = 1 and 0<= time_index_death <=30 then
		death30 = 1;

	death60 = 0;
	if death = 1 and 0<= time_index_death <=60 then
		death60 = 1;

	death90 = 0;
	if death = 1 and 0<= time_index_death <=90 then
		death90 = 1;

		
		DLS_180 = min(bene_death_dt, study_end_dt, index_dt+180, pima_dt);

	if DLS_180=bene_death_dt then censor_type = "death							";
	if DLS_180=study_end_dt then censor_type = "end of study				";
	if DLS_180=index_dt+180 then censor_type = "end of 180					";
	if DLS_180=pima_dt then censor_type = "event						";
run;

proc freq data=test;
	tables death30 death60 death90 death180 death365;
run;

proc logistic data=cohort_v05;
  class pimavanserin / param=ref ;
  model death180 = pimavanserin;
run;

proc logistic data=cohort_v05;
  class pimavanserin / param=ref ;
  model death365 = pimavanserin;
run;

proc freq data=test;
	tables censor_type censor_type*death180;
run;

proc means data=test mean stddev;
	class censor_type; var surv_180 surv_365; run;

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
