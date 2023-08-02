/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Tuesday, November 29, 2022     TIME: 6:40:14 PM
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

/*   START OF NODE: 04_Merge mbsf file   */
%LET _CLIENTTASKLABEL='04_Merge mbsf file';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp';
%LET _CLIENTPROJECTPATHHOST='VDI-PS-L90350';
%LET _CLIENTPROJECTNAME='Project pimavanserin.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
options source;

/**************************************************************************
	Geet MBSF file
**************************************************************************/
data mbsf16_18 (keep= bene_id BENE_ENROLLMT_REF_YR BENE_BIRTH_DT BENE_DEATH_DT  SEX_IDENT_CD RTI_RACE_CD ENTLMT_RSN_ORIG);
set &lib.MBSF_ABCD16_R9984 &lib.MBSF_ABCD17_R9984 &lib.MBSF_ABCD18_R9984;
run;

proc sql;	**601,033 unique pts;
create table mbsf16_18_pima as 
select b.*
from cohort_v02 as a , mbsf16_18 as b
where a.bene_id = b.bene_id
order by bene_id, bene_death_dt;
quit;
proc sql;
select count (bene_id) as all_clams, count (distinct bene_id) as unique_pt
from mbsf16_18_pima;
quit;
Data mbsf16_18_pima_u;
set mbsf16_18_pima;
by bene_id;
if last.bene_id;
run;

/**************************************************************************
	Update cohort with at least one record in MBSF file	and get all variables
**************************************************************************/
proc sql;	**601,033 unique pts;
create table cohort_v03 as 
select a.*, b.*
from cohort_v02 as a, mbsf16_18_pima_u as b
where a.bene_id = b.bene_id;
quit;

/**************************************************************************
	Identify index date	
**************************************************************************/

Data cohort_v04;
set cohort_v03;

**reassign diagnosis date;
if pimavanserin = 0 then do;
	park_date_v2 = park_date;
end;

if pimavanserin = 1 then do;
	if park_date <= pima_dt then park_date_v2 = park_date;
	if park_date > pima_dt  then park_date_v2 = pima_dt;
end;

index_dt = pima_dt;

park_pima_rx_date = pima_dt - park_date_v2;								 **Diag to rx date;
format park_date_v2 index_dt mmddyy10.;

run;

proc means data= cohort_v04 maxdec= 0;
var park_pima_rx_date;
where pimavanserin = 1;
run;

proc univariate data= cohort_v04 ;
var park_pima_rx_date;
histogram;
where pimavanserin = 1;
run;



















/**************************************************************************
	Analysis
**************************************************************************/
/*How to assign index date to non-users?*/
/*https://www.mwsug.org/proceedings/2012/PH/MWSUG-2012-PH02.pdf*/
/*https://communities.sas.com/t5/SAS-Programming/assigning-a-random-index-date/td-p/427238*/
data cohort_v05;
set cohort_v04;

if missing(index_dt) then duration = rand('random', 503, 275);

if index_dt = . then index_dt = floor(park_date_v2 + duration);

format index_dt date9.;

run;

Data cohort_v06;
set cohort_v05;

if bene_death_dt < index_dt then wrong_die = 1;

**time from diagnosis to death;
time_dx_death = bene_death_dt - park_date_v2;

**death yes no;
if bene_death_dt = . then death = 0; 
else death = 1;

time_pima_death = bene_death_dt - pima_dt;
death30 = 0;  if death = 1 and 0<= time_pima_death <=30 then death30 = 1;
death90 = 0;  if death = 1 and 0<= time_pima_death <=90 then death90 = 1;
death180 = 0; if death = 1 and 0<= time_pima_death <=180 then death180 = 1;


age_yr = ( "01Jan2016"D - bene_birth_dt )/ 365;

if sex_ident_cd = 1 then male = 1; 
if sex_ident_cd = 2 then male = 0; 

run;

data cohort_v07;		**600,839 --- 601033;
set cohort_v06;
if death = 1 and time_dx_death <0 then delete;
run;

proc means data=cohort_v07 maxdec = 0 n mean std median min max;
var age_yr ;
class pimavanserin;
run;

proc freq data= cohort_v07;
tables pimavanserin * (death death30 death90 death180) /  missing;
run;

proc freq data = cohort_v07;
tables death death30 death90 death180;
where pimavanserin = 1;
run; 
/**/
/*proc lifetest data = cohort_v07 notable plots=survival (cb=hw test atrisk);*/
/*time time_dx_death * death (0);*/
/*strata pimavanserin;*/
/*run;*/

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
